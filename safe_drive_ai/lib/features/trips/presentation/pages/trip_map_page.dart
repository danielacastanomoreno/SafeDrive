import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../../../../../core/constants/app_colors.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_state.dart';
import '../cubit/drowsiness_cubit.dart';
import '../cubit/seatbelt_cubit.dart';
import '../widgets/end_trip_dialog.dart';

/// Mapa en vivo con traza azul y overlay de cámara frontal (conductor).
///
/// Se muestra como 4to índice en el [IndexedStack] del [DriverHomePage].
class TripMapPage extends StatefulWidget {
  const TripMapPage({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage>
    with TickerProviderStateMixin {
  // ── Map ───────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  bool _followDriver = true;

  // ── Front camera (selfie — conductor) ────────────────────────────────────
  CameraController? _frontController;
  CameraDescription? _frontCamera;
  bool _frontReady = false;
  bool _frontVisible = true;
  InputImageRotation _imageRotation = InputImageRotation.rotation0deg;
  int _frameCounter = 0;

  static const int _seatbeltFrameSkip = 10;
  static const int _drowsinessFrameSkip = 15;
  static const Duration _drowsinessAlertCooldown = Duration(seconds: 3);

  Timer? _audioAlarmTimer;
  bool _seatbeltAlertActive = false;
  DateTime? _lastDrowsinessAlertAt;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AnimationController _blinkController;
  late final Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _blinkAnimation = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    _initCamera();
  }

  // ── Camera initialization ─────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (_frontReady) {
      final frontController = _frontController;
      if (frontController != null && !frontController.value.isStreamingImages) {
        await frontController.startImageStream(_onCameraImage);
      }
      return;
    }

    final status = await Permission.camera.status;
    if (!status.isGranted) return;

    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (_) {
      return;
    }
    if (cameras.isEmpty) return;

    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final imageFormatGroup =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888;

    final ctrl = CameraController(
      frontCam,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      _imageRotation = _rotationFromCamera(
        frontCam,
        ctrl.value.deviceOrientation,
      );
      await ctrl.startImageStream(_onCameraImage);
      setState(() {
        _frontController = ctrl;
        _frontCamera = frontCam;
        _frontReady = true;
      });
    } catch (_) {
      await ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    final frontController = _frontController;
    if (frontController != null && frontController.value.isStreamingImages) {
      unawaited(frontController.stopImageStream());
    }
    _frontController?.dispose();
    _audioAlarmTimer?.cancel();
    _audioPlayer.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onCameraImage(CameraImage image) {
    final frontController = _frontController;
    final frontCamera = _frontCamera;
    if (frontController != null && frontCamera != null) {
      _imageRotation = _rotationFromCamera(
        frontCamera,
        frontController.value.deviceOrientation,
      );
    }

    _frameCounter++;
    if (!mounted) return;

    if (_frameCounter % _seatbeltFrameSkip == 0) {
      context.read<SeatbeltCubit>().processFrame(image, _imageRotation);
    }

    if (_frameCounter % _drowsinessFrameSkip == 0) {
      context.read<DrowsinessCubit>().processFrame(image, _imageRotation);
    }
  }

  void _stopCameraStream() {
    final frontController = _frontController;
    if (frontController != null && frontController.value.isStreamingImages) {
      frontController.stopImageStream().catchError((_) {});
    }
  }

  void _startAlertAlarm() {
    if (_audioAlarmTimer != null) return;
    _triggerAlarmOnce();
    _audioAlarmTimer =
        Timer.periodic(const Duration(seconds: 8), (_) => _triggerAlarmOnce());
  }

  void _stopAlertAlarm() {
    _audioAlarmTimer?.cancel();
    _audioAlarmTimer = null;
    _audioPlayer.stop();
  }

  void _setSeatbeltAlert(bool active) {
    if (_seatbeltAlertActive == active) return;
    _seatbeltAlertActive = active;
    _syncAlertAlarm();
  }

  void _syncAlertAlarm() {
    if (_seatbeltAlertActive) {
      _startAlertAlarm();
    } else {
      _stopAlertAlarm();
    }
  }

  void _triggerDrowsinessAlertIfNeeded(DrowsinessState state) {
    final hasDrowsinessSignal = state.eyesClosed || state.yawning;
    if (!hasDrowsinessSignal) return;

    final now = DateTime.now();
    final last = _lastDrowsinessAlertAt;
    if (last != null && now.difference(last) < _drowsinessAlertCooldown) {
      return;
    }

    _lastDrowsinessAlertAt = now;
    debugPrint(
      '[DROWSINESS] signal eyesClosed=${state.eyesClosed} yawning=${state.yawning} score=${state.score}',
    );
    _triggerAlarmOnce();
  }

  Future<void> _triggerAlarmOnce() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 400, 200, 400]);
    } else {
      HapticFeedback.heavyImpact();
    }

    SystemSound.play(SystemSoundType.alert);

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(
        AssetSource('audio/alert_beep.wav'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('[ALERT_AUDIO] failed to play alert_beep.wav: $e');
    }
  }

  InputImageRotation _rotationFromCamera(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final deviceDegrees = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

    final sensorDegrees = camera.sensorOrientation;
    final rotationDegrees = camera.lensDirection == CameraLensDirection.front
        ? (sensorDegrees + deviceDegrees) % 360
        : (sensorDegrees - deviceDegrees + 360) % 360;

    return switch (rotationDegrees) {
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onEndPressed(BuildContext context, String tripId) async {
    final tripBloc = context.read<TripBloc>();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: tripBloc,
        child: EndTripDialog(tripId: tripId),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is! TripActive) {
          _stopCameraStream();
          _setSeatbeltAlert(false);
          _lastDrowsinessAlertAt = null;
          context.read<SeatbeltCubit>().reset();
          context.read<DrowsinessCubit>().reset();
          return;
        }

        if (state.isNewlyStarted) {
          // Permission was just granted — re-try camera init
          _initCamera();
        }
        if (state.route.isNotEmpty && _followDriver) {
          _mapController.move(state.route.last, _mapController.camera.zoom);
        }
      },
      builder: (context, state) {
        if (state is! TripActive) return _buildNoTripView();

        final route = state.route;
        final currentPosition = route.isNotEmpty ? route.last : null;
        final headingRadians = state.heading * math.pi / 180;
        final topPadding = MediaQuery.of(context).padding.top;
        final overlayTop = topPadding + 80.0;

        return MultiBlocListener(
          listeners: [
            BlocListener<SeatbeltCubit, SeatbeltState>(
              listener: (context, seatbeltState) {
                _setSeatbeltAlert(seatbeltState is SeatbeltNotDetected);
              },
            ),
            BlocListener<DrowsinessCubit, DrowsinessState>(
              listener: (context, drowsinessState) {
                debugPrint(
                  '[DROWSINESS] face=${drowsinessState.faceDetected} eyes=${drowsinessState.eyesClosed} yawn=${drowsinessState.yawning} score=${drowsinessState.score} drowsy=${drowsinessState.isDrowsy}',
                );
                _triggerDrowsinessAlertIfNeeded(drowsinessState);
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // ── 1. Map ────────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        currentPosition ?? const LatLng(4.6097, -74.0817),
                    initialZoom: 15,
                    onPositionChanged: (_, hasGesture) {
                      if (hasGesture && _followDriver) {
                        setState(() => _followDriver = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bombastik.safedrive',
                    ),
                    if (route.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route,
                            color: const Color(0xFF1565C0),
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      ),
                    if (route.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: route.first,
                            width: 16,
                            height: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPosition,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: headingRadians,
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── 2. Top bar ────────────────────────────────────────────────
                BlocBuilder<SeatbeltCubit, SeatbeltState>(
                  builder: (context, seatbeltState) {
                    return BlocBuilder<DrowsinessCubit, DrowsinessState>(
                      builder: (context, drowsinessState) {
                        final showSeatbeltWarning =
                            seatbeltState is SeatbeltNotDetected;
                        final showDrowsinessWarning = drowsinessState.isDrowsy;

                        if (!showSeatbeltWarning && !showDrowsinessWarning) {
                          return const SizedBox.shrink();
                        }

                        final topInset = MediaQuery.of(context).padding.top + 4;

                        return Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: FadeTransition(
                            opacity: _blinkAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showDrowsinessWarning)
                                  _AlertBanner(
                                    message: 'ALERTA DE SOMNOLENCIA',
                                    color: AppColors.warning,
                                    topPadding: topInset,
                                  ),
                                if (showSeatbeltWarning)
                                  _AlertBanner(
                                    message: 'PONTE EL CINTURON DE SEGURIDAD',
                                    color: AppColors.error,
                                    topPadding:
                                        showDrowsinessWarning ? 4 : topInset,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        _MapButton(
                          icon: Icons.arrow_back,
                          onTap: widget.onClose,
                          tooltip: 'Volver',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Viaje en curso  ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  _formatElapsed(state.elapsed),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 3. Front camera overlay — top-right (conductor/selfie) ────
                if (_frontReady && _frontController != null)
                  Positioned(
                    top: overlayTop,
                    right: 12,
                    child: _frontVisible
                        ? BlocBuilder<SeatbeltCubit, SeatbeltState>(
                            builder: (context, seatbeltState) {
                              return BlocBuilder<DrowsinessCubit,
                                  DrowsinessState>(
                                builder: (context, drowsinessState) {
                                  return _CameraOverlay(
                                    controller: _frontController!,
                                    seatbeltState: seatbeltState,
                                    drowsinessState: drowsinessState,
                                    onClose: () =>
                                        setState(() => _frontVisible = false),
                                  );
                                },
                              );
                            },
                          )
                        : _MapButton(
                            icon: Icons.camera_front_outlined,
                            onTap: () => setState(() => _frontVisible = true),
                            tooltip: 'Mostrar cámara',
                          ),
                  ),

                Positioned(
                  top: overlayTop,
                  left: 12,
                  child: BlocBuilder<DrowsinessCubit, DrowsinessState>(
                    builder: (context, drowsinessState) {
                      return _DriverConditionPanel(state: drowsinessState);
                    },
                  ),
                ),

                // ── 4. Bottom controls ────────────────────────────────────────
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!_followDriver)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MapButton(
                            icon: Icons.my_location,
                            onTap: () {
                              if (currentPosition != null) {
                                _mapController.move(currentPosition, 15);
                                setState(() => _followDriver = true);
                              }
                            },
                            tooltip: 'Centrar en mi posición',
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _onEndPressed(context, state.trip.id),
                          icon: const Icon(Icons.stop),
                          label: const Text('Finalizar Viaje',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoTripView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onClose,
              ),
              title: const Text('Mapa'),
            ),
            const Expanded(
              child: Center(
                child: Text('No hay un viaje activo.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Camera overlay ────────────────────────────────────────────────────────────

class _CameraOverlay extends StatelessWidget {
  const _CameraOverlay({
    required this.controller,
    required this.seatbeltState,
    required this.drowsinessState,
    required this.onClose,
  });

  final CameraController controller;
  final SeatbeltState seatbeltState;
  final DrowsinessState drowsinessState;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final borderColor = _cameraBorderColor(
        seatbeltState: seatbeltState, drowsinessState: drowsinessState);

    return Container(
      width: 110,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scaleX: -1.0, // mirror for selfie
            child: CameraPreview(controller),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 4,
            child: _SeatbeltIndicator(state: seatbeltState),
          ),
          Positioned(
            bottom: 22,
            right: 4,
            child: _DrowsinessIndicator(state: drowsinessState),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: const Text(
                'Conductor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared map button ─────────────────────────────────────────────────────────

Color _seatbeltBorderColor(SeatbeltState state) {
  if (state is SeatbeltDetected) return AppColors.success;
  if (state is SeatbeltNotDetected) return AppColors.error;
  return Colors.white;
}

Color _cameraBorderColor({
  required SeatbeltState seatbeltState,
  required DrowsinessState drowsinessState,
}) {
  if (drowsinessState.isDrowsy) {
    return AppColors.warning;
  }
  return _seatbeltBorderColor(seatbeltState);
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.message,
    required this.color,
    required this.topPadding,
  });

  final String message;
  final Color color;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatbeltIndicator extends StatelessWidget {
  const _SeatbeltIndicator({required this.state});

  final SeatbeltState state;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final String symbol;

    if (state is SeatbeltDetected) {
      bgColor = AppColors.success;
      symbol = 'C';
    } else if (state is SeatbeltNotDetected) {
      bgColor = AppColors.error;
      symbol = 'X';
    } else {
      bgColor = Colors.grey.shade600;
      symbol = '?';
    }

    return Tooltip(
      message: state is SeatbeltDetected
          ? 'Cinturon detectado'
          : state is SeatbeltNotDetected
              ? 'Sin cinturon'
              : 'Analizando...',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 3),
          ],
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrowsinessIndicator extends StatelessWidget {
  const _DrowsinessIndicator({required this.state});

  final DrowsinessState state;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final String symbol;

    if (state.isDrowsy) {
      bgColor = AppColors.warning;
      symbol = '!';
    } else if (state.faceDetected) {
      bgColor = AppColors.success;
      symbol = 'Z';
    } else {
      bgColor = Colors.grey.shade600;
      symbol = '?';
    }

    return Tooltip(
      message: state.isDrowsy
          ? (state.reason ?? 'Somnolencia detectada')
          : state.faceDetected
              ? 'Sin somnolencia detectada'
              : 'Analizando rostro...',
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 3),
          ],
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverConditionPanel extends StatelessWidget {
  const _DriverConditionPanel({required this.state});

  final DrowsinessState state;

  @override
  Widget build(BuildContext context) {
    final bool drowsyNow = state.isDrowsy;
    final Color statusColor = drowsyNow ? AppColors.warning : AppColors.success;
    final String statusText = drowsyNow ? 'SOMNOLIENTO' : 'BIEN';

    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                drowsyNow ? Icons.bedtime : Icons.check_circle,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              const Text(
                'Estado del conductor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _PanelMetric(
            label: 'Rostro',
            value: state.faceDetected ? 'Detectado' : 'No detectado',
          ),
          _PanelMetric(
            label: 'Ojos cerrados',
            value: state.eyesClosed ? 'SI' : 'NO',
          ),
          _PanelMetric(
            label: 'Bostezo',
            value: state.yawning ? 'SI' : 'NO',
          ),
          _PanelMetric(
            label: 'Score',
            value: '${state.score}',
          ),
        ],
      ),
    );
  }
}

class _PanelMetric extends StatelessWidget {
  const _PanelMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
      ),
    );
  }
}
