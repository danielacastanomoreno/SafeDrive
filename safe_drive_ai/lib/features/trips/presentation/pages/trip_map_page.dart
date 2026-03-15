import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

/// Mapa en vivo que muestra la posición actual del conductor
/// y una traza azul del recorrido desde que inició el viaje.
///
/// Se muestra como 4to tab (oculto) en el [IndexedStack] del [DriverHomePage]
/// para compartir el mismo [TripBloc] sin complicaciones de navegación.
class TripMapPage extends StatefulWidget {
  const TripMapPage({super.key, required this.onClose});

  /// Called when the user taps the back/close button.
  final VoidCallback onClose;

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  final MapController _mapController = MapController();
  bool _followDriver = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onEndPressed(BuildContext context, String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Finalizar viaje'),
        content: const Text('¿Confirmas que quieres finalizar el viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<TripBloc>().add(TripEndRequested(tripId: tripId));
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripBloc, TripState>(
      listener: (context, state) {
        if (state is TripActive && state.route.isNotEmpty && _followDriver) {
          final last = state.route.last;
          _mapController.move(last, _mapController.camera.zoom);
        }
      },
      builder: (context, state) {
        if (state is! TripActive) {
          return _buildNoTripView();
        }

        final route = state.route;
        final currentPosition = route.isNotEmpty ? route.last : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── Map ──────────────────────────────────────────────────────────
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
                  // OpenStreetMap tiles (free, no API key)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bombastik.safedrive',
                  ),
                  // Route polyline (blue)
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
                  // Start marker (green dot)
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
                  // Current position marker (blue navigation icon)
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
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── Top bar ──────────────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Back button
                      _MapButton(
                        icon: Icons.arrow_back,
                        onTap: widget.onClose,
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 8),
                      // Trip timer pill
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
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
                              const Text(
                                'Viaje en curso  ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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

              // ── Bottom controls ──────────────────────────────────────────────
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Re-center button (visible only when user has panned away)
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
                    // End trip button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _onEndPressed(context, state.trip.id),
                        icon: const Icon(Icons.stop),
                        label: const Text(
                          'Finalizar Viaje',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                child: Text(
                  'No hay un viaje activo.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
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
