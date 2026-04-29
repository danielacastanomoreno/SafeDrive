import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../../../../../core/constants/app_colors.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_state.dart';
import '../cubit/drowsiness_cubit.dart';
import '../cubit/seatbelt_cubit.dart';
import '../services/drowsiness_event_logger.dart';
import '../services/voice_alert_service.dart';
import '../services/voice_response_service.dart';
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
  static const Duration _clipDuration = Duration(seconds: 20);
  static const Duration _voiceResponseWindow = Duration(seconds: 5);
  static const Duration _periodicInterval = Duration(minutes: 3);
  static const Duration _periodicTick = Duration(seconds: 15);
  static const Duration _periodicStepDuration = Duration(seconds: 3);
  static const double _level1Volume = 0.7;
  static const double _maxVolume = 1.0;
    static const bool _enableClipRecording = false;
  static const String _periodicPromptMessage =
      '¿Estás bien? Di cualquier cosa para confirmar.';
    static const String _drowsinessVoiceMessage =
      'Somnolencia detectada. Por favor reacciona.';
  static const String _noFaceMessage =
      'No se detecta tu rostro.\n'
      'Asegurate de que la camara frontal\n'
      'tenga visibilidad de tu cara.';
  static const String _cameraUnavailableMessage =
      'Deteccion facial no disponible';

  Timer? _audioAlarmTimer;
  Timer? _periodicTimer;
  bool _seatbeltAlertActive = false;
  bool _drowsinessAlertInProgress = false;
  bool _periodicInProgress = false;
  bool _isRecordingClip = false;
  bool _alertVibrationActive = false;
  int _lastAlertSequenceHandled = 0;
  DateTime? _lastPeriodicResponseAt;
  Completer<void>? _autoStopCompleter;
  bool _autoStopTriggered = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _alertAudioPlayer = AudioPlayer();
  final VoiceAlertService _voiceAlertService = VoiceAlertService();
  final VoiceResponseService _voiceResponseService = VoiceResponseService();
  final DrowsinessEventLogger _eventLogger = DrowsinessEventLogger();
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
    _alertAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
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
    _periodicTimer?.cancel();
    _audioPlayer.dispose();
    _alertAudioPlayer.dispose();
    unawaited(_voiceAlertService.dispose());
    unawaited(_voiceResponseService.dispose());
    if (_alertVibrationActive) {
      Vibration.cancel();
      _alertVibrationActive = false;
    }
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

  void _handleDrowsinessState(DrowsinessState state) {
    if (!state.isDrowsy && _drowsinessAlertInProgress) {
      _signalAutoStop();
    }
    final alert = state.lastAlert;
    if (alert == null) return;
    if (state.alertSequence == _lastAlertSequenceHandled) return;
    _lastAlertSequenceHandled = state.alertSequence;

    final tripState = context.read<TripBloc>().state;
    if (tripState is! TripActive) return;
    if (!tripState.trip.hasCameraPermission) return;

    unawaited(_processDrowsinessAlert(alert, tripState));
  }

  Future<void> _processDrowsinessAlert(
    DrowsinessAlert alert,
    TripActive tripState,
  ) async {
    if (_drowsinessAlertInProgress) return;
    _drowsinessAlertInProgress = true;
    _autoStopTriggered = false;
    _autoStopCompleter = Completer<void>();

    if (_periodicInProgress) {
      _periodicInProgress = false;
      await _stopAlertSound();
      await _voiceResponseService.stop();
      await _voiceAlertService.stop();
    }

    final clipFuture = _recordDrowsinessClip(
      tripId: tripState.trip.id,
      level: alert.level,
      triggeredAt: alert.triggeredAt,
    );

    unawaited(_voiceAlertService.speak(_drowsinessVoiceMessage));

    final initialVolume =
        alert.level == DrowsinessLevel.level1 ? _level1Volume : _maxVolume;
    final initialVibration = alert.level == DrowsinessLevel.level2;

    await _startAlertSound(
      volume: initialVolume,
      vibrate: initialVibration,
    );

    final respondedInWindow = await _waitForVoiceOrAutoStop(
      duration: _voiceResponseWindow,
    );

    if (respondedInWindow) {
      await _stopAlertSound();
    } else {
      await _startAlertSound(volume: _maxVolume, vibrate: true);
      await _listenUntilResponse();
    }

    final clipPath = await clipFuture;
    await _eventLogger.logEvent(
      tripId: tripState.trip.id,
      type: alert.level == DrowsinessLevel.level1
          ? 'somnolencia nivel 1'
          : 'somnolencia nivel 2',
      status: respondedInWindow ? 'respondida' : 'no respondida',
      timestamp: alert.triggeredAt,
      clipPath: clipPath,
    );

    _drowsinessAlertInProgress = false;
  }

  Future<void> _startAlertSound({
    required double volume,
    required bool vibrate,
  }) async {
    try {
      await _alertAudioPlayer.stop();
      await _alertAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _alertAudioPlayer.setVolume(volume);
      await _alertAudioPlayer.play(
        AssetSource('audio/alert_beep.wav'),
        volume: volume,
      );
    } catch (e) {
      debugPrint('[ALERT_AUDIO] failed to play alert_beep.wav: $e');
    }

    if (vibrate) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        _alertVibrationActive = true;
        Vibration.vibrate(pattern: [0, 400, 200, 400], repeat: 0);
      } else {
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _stopAlertSound() async {
    try {
      await _alertAudioPlayer.stop();
      await _alertAudioPlayer.release();
    } catch (_) {}

    if (_alertVibrationActive) {
      Vibration.cancel();
      _alertVibrationActive = false;
    } else {
      Vibration.cancel();
    }
  }

  Future<void> _playAlertStep({
    required double volume,
    required Duration duration,
  }) async {
    await _startAlertSound(volume: volume, vibrate: false);
    await Future.delayed(duration);
    await _stopAlertSound();
  }

  Future<void> _listenUntilResponse() async {
    while (mounted) {
      if (_autoStopTriggered) {
        await _stopAlertSound();
        return;
      }
      final tripState = context.read<TripBloc>().state;
      if (tripState is! TripActive) return;
      final responded = await _voiceResponseService.listenForResponse(
        duration: _voiceResponseWindow,
      );
      if (responded) {
        await _stopAlertSound();
        return;
      }
    }
  }

  void _startPeriodicChecks(DateTime startTime) {
    _lastPeriodicResponseAt ??= startTime;
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_periodicTick, (_) {
      if (_periodicInProgress || _drowsinessAlertInProgress) return;
      final last = _lastPeriodicResponseAt ?? startTime;
      if (DateTime.now().difference(last) >= _periodicInterval) {
        unawaited(_runPeriodicVerification());
      }
    });
  }

  void _stopPeriodicChecks() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _resetDrowsinessSession() {
    _drowsinessAlertInProgress = false;
    _periodicInProgress = false;
    _lastAlertSequenceHandled = 0;
    _lastPeriodicResponseAt = null;
    _isRecordingClip = false;
    _autoStopTriggered = false;
    _autoStopCompleter = null;
    _stopPeriodicChecks();
    unawaited(_voiceResponseService.stop());
    unawaited(_voiceAlertService.stop());
    unawaited(_stopAlertSound());
  }

  void _signalAutoStop() {
    if (_autoStopTriggered) return;
    _autoStopTriggered = true;
    if (_autoStopCompleter != null && !_autoStopCompleter!.isCompleted) {
      _autoStopCompleter!.complete();
    }
    unawaited(_voiceResponseService.stop());
    unawaited(_stopAlertSound());
  }

  Future<bool> _waitForVoiceOrAutoStop({
    required Duration duration,
  }) async {
    _autoStopCompleter ??= Completer<void>();
    final voiceFuture = _voiceResponseService.listenForResponse(
      duration: duration,
    );
    final result = await Future.any([
      voiceFuture,
      _autoStopCompleter!.future.then((_) => true),
    ]);
    return result == true;
  }

  Future<void> _runPeriodicVerification() async {
    if (_periodicInProgress || _drowsinessAlertInProgress) return;
    _periodicInProgress = true;

    final startedAt = DateTime.now();
    await _voiceAlertService.speak(_periodicPromptMessage);

    final respondedInWindow =
        await _voiceResponseService.listenForResponse(
      duration: _voiceResponseWindow,
    );

    if (respondedInWindow) {
      await _eventLogger.logEvent(
        tripId: _currentTripId(),
        type: 'alerta periodica',
        status: 'respondida',
        timestamp: startedAt,
      );
      _lastPeriodicResponseAt = DateTime.now();
      _periodicInProgress = false;
      return;
    }

    await _eventLogger.logEvent(
      tripId: _currentTripId(),
      type: 'alerta periodica',
      status: 'no respondida - posible microsueno',
      timestamp: startedAt,
    );

    await _playAlertStep(volume: 0.5, duration: _periodicStepDuration);
    if (_drowsinessAlertInProgress) {
      _periodicInProgress = false;
      return;
    }

    await _playAlertStep(volume: 0.8, duration: _periodicStepDuration);
    if (_drowsinessAlertInProgress) {
      _periodicInProgress = false;
      return;
    }

    await _startAlertSound(volume: _maxVolume, vibrate: true);
    await _listenUntilResponse();
    await _stopAlertSound();

    _lastPeriodicResponseAt = DateTime.now();
    _periodicInProgress = false;
  }

  String _currentTripId() {
    final tripState = context.read<TripBloc>().state;
    if (tripState is TripActive) {
      return tripState.trip.id;
    }
    return 'unknown';
  }

  Future<String?> _recordDrowsinessClip({
    required String tripId,
    required DrowsinessLevel level,
    required DateTime triggeredAt,
  }) async {
    // Tipo B: grabar 20s posteriores al evento (sin prebuffer).
    if (!_enableClipRecording) return null;
    final controller = _frontController;
    if (controller == null || !controller.value.isInitialized) return null;
    if (_isRecordingClip) return null;

    context.read<DrowsinessCubit>().reset();
    _isRecordingClip = true;
    final wasStreaming = controller.value.isStreamingImages;

    try {
      if (wasStreaming) {
        await controller.stopImageStream();
      }

      await controller.startVideoRecording();
      await Future.delayed(_clipDuration);
      final file = await controller.stopVideoRecording();

      final directory = await getApplicationDocumentsDirectory();
      final clipsDir = Directory('${directory.path}/drowsiness_clips');
      await clipsDir.create(recursive: true);

      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final safeTripId = tripId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final levelLabel =
          level == DrowsinessLevel.level1 ? 'nivel1' : 'nivel2';
      final fileName =
          'trip_${safeTripId}_${levelLabel}_${formatter.format(triggeredAt)}.mp4';
      final targetPath = '${clipsDir.path}/$fileName';

      await File(file.path).copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('[DROWSINESS_CLIP] recording failed: $e');
      return null;
    } finally {
      if (wasStreaming && mounted && controller.value.isInitialized) {
        await controller.startImageStream(_onCameraImage);
      }
      _isRecordingClip = false;
    }
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
          _resetDrowsinessSession();
          context.read<SeatbeltCubit>().reset();
          context.read<DrowsinessCubit>().reset();
          return;
        }

        if (state.isNewlyStarted) {
          // Permission was just granted — re-try camera init
          _initCamera();
        }
        if (_periodicTimer == null) {
          _startPeriodicChecks(state.trip.startTime);
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
                  '[DROWSINESS] face=${drowsinessState.faceDetected} eyes=${drowsinessState.eyesClosed} headDown=${drowsinessState.headDown} drowsy=${drowsinessState.isDrowsy} missing=${drowsinessState.faceMissing}',
                );
                _handleDrowsinessState(drowsinessState);
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

                if (!state.trip.hasCameraPermission)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AlertBanner(
                      message: _cameraUnavailableMessage,
                      color: Colors.black54,
                      topPadding: MediaQuery.of(context).padding.top + 4,
                    ),
                  ),

                BlocBuilder<DrowsinessCubit, DrowsinessState>(
                  builder: (context, drowsinessState) {
                    if (!drowsinessState.faceMissing) {
                      return const SizedBox.shrink();
                    }

                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.warning, width: 1),
                        ),
                        child: const Text(
                          _noFaceMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

    if (state.faceMissing) {
      bgColor = AppColors.warning;
      symbol = '!';
    } else if (state.isDrowsy) {
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
      message: state.faceMissing
        ? 'Rostro no detectado'
        : state.isDrowsy
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
    final eyesSeconds =
      (state.eyesClosedDuration.inMilliseconds / 1000).toStringAsFixed(1);

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
            label: 'Duracion ojos',
            value: '${eyesSeconds}s',
          ),
          _PanelMetric(
            label: 'Cabeceo',
            value: state.headDown ? 'SI' : 'NO',
          ),
          _PanelMetric(
            label: 'Bostezo',
            value: state.yawning ? 'SI' : 'NO',
          ),
          _PanelMetric(
            label: 'Pitch',
            value: state.headPitch != null
                ? state.headPitch!.toStringAsFixed(1)
                : '-',
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
