import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/trip_bloc.dart';
import '../bloc/trip_event.dart';
import '../bloc/trip_state.dart';

/// Panel persistente de viaje mostrado en la parte superior del home del conductor.
class TripPanelWidget extends StatelessWidget {
  const TripPanelWidget({
    super.key,
    required this.driverId,
    required this.onOpenMap,
  });

  final String driverId;

  /// Called when the user taps "Ver mapa" while a trip is active.
  final VoidCallback onOpenMap;

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onStartPressed(BuildContext context) async {
    final status = await Permission.camera.status;
    bool hasCameraPermission = status.isGranted;

    if (!hasCameraPermission) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _NoCameraDialog(),
      );
      if (confirmed == null || !confirmed) return;
    }

    if (!context.mounted) return;
    context.read<TripBloc>().add(
          TripStartRequested(
            driverId: driverId,
            hasCameraPermission: hasCameraPermission,
          ),
        );
  }

  Future<void> _onEndPressed(BuildContext context, String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ConfirmEndDialog(),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    context.read<TripBloc>().add(TripEndRequested(tripId: tripId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is TripLoading || state is TripInitial) {
          return const _PanelShell(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            ),
          );
        }

        if (state is TripActive) {
          return _ActiveTripPanel(
            formatted: _formatElapsed(state.elapsed),
            onEnd: () => _onEndPressed(context, state.trip.id),
            onOpenMap: onOpenMap,
          );
        }

        return _IdleTripPanel(
          onStart: () => _onStartPressed(context),
          error: state is TripError ? state.message : null,
        );
      },
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: child,
    );
  }
}

class _IdleTripPanel extends StatelessWidget {
  const _IdleTripPanel({required this.onStart, this.error});
  final VoidCallback onStart;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.directions_car,
                  color: AppColors.textOnPrimary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sin viaje en curso',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Iniciar Viaje'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Container(
            width: double.infinity,
            color: AppColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({
    required this.formatted,
    required this.onEnd,
    required this.onOpenMap,
  });

  final String formatted;
  final VoidCallback onEnd;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1B5E20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status + timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Viaje en curso',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // Ver mapa button
          TextButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_outlined,
                color: Colors.white70, size: 18),
            label: const Text(
              'Ver mapa',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          // End button
          ElevatedButton.icon(
            onPressed: onEnd,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('Finalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCameraDialog extends StatelessWidget {
  const _NoCameraDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.videocam_off_outlined, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Sin permiso de cámara'),
        ],
      ),
      content: const Text(
        'Sin el permiso de cámara frontal, la detección de somnolencia y la '
        'verificación del cinturón no estarán disponibles.\n\n'
        '¿Deseas continuar sin estas funciones?',
        style: TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continuar sin cámara'),
        ),
      ],
    );
  }
}

class _ConfirmEndDialog extends StatelessWidget {
  const _ConfirmEndDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
