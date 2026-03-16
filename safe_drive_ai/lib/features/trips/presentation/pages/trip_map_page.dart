import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_colors.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_state.dart';
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

class _TripMapPageState extends State<TripMapPage> {
  // ── Map ───────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  bool _followDriver = true;

  // ── Front camera (selfie — conductor) ────────────────────────────────────
  CameraController? _frontController;
  bool _frontReady = false;
  bool _frontVisible = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ── Camera initialization ─────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (_frontReady) return;

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

    final ctrl = CameraController(
      frontCam,
      ResolutionPreset.low,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _frontController = ctrl;
        _frontReady = true;
      });
    } catch (_) {
      await ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _frontController?.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
        if (state is TripActive && state.isNewlyStarted) {
          // Permission was just granted — re-try camera init
          _initCamera();
        }
        if (state is TripActive && state.route.isNotEmpty && _followDriver) {
          _mapController.move(state.route.last, _mapController.camera.zoom);
        }
      },
      builder: (context, state) {
        if (state is! TripActive) return _buildNoTripView();

        final route = state.route;
        final currentPosition = route.isNotEmpty ? route.last : null;
        final topPadding = MediaQuery.of(context).padding.top;
        final overlayTop = topPadding + 80.0;

        return Scaffold(
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
                              border: Border.all(color: Colors.white, width: 2),
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
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.navigation,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── 2. Top bar ────────────────────────────────────────────────
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
                      ? _CameraOverlay(
                          controller: _frontController!,
                          onClose: () => setState(() => _frontVisible = false),
                        )
                      : _MapButton(
                          icon: Icons.camera_front_outlined,
                          onTap: () => setState(() => _frontVisible = true),
                          tooltip: 'Mostrar cámara',
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
                        onPressed: () => _onEndPressed(context, state.trip.id),
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
    required this.onClose,
  });

  final CameraController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
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
