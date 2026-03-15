import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/trip_entity.dart';

/// Pantalla de resumen del viaje, mostrada automáticamente al finalizar.
class TripSummaryPage extends StatelessWidget {
  const TripSummaryPage({super.key, required this.trip});

  final TripEntity trip;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resumen del viaje'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle, color: AppColors.success, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Viaje finalizado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _SummaryRow(
                icon: Icons.play_circle_outline,
                label: 'Inicio',
                value: _formatDateTime(trip.startTime),
              ),
              const Divider(height: 28),
              _SummaryRow(
                icon: Icons.stop_circle_outlined,
                label: 'Fin',
                value: _formatDateTime(trip.endTime!),
              ),
              const Divider(height: 28),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'Duración',
                value: _formatDuration(trip.elapsed),
              ),
              const Divider(height: 28),
              _SummaryRow(
                icon: trip.hasCameraPermission
                    ? Icons.videocam_outlined
                    : Icons.videocam_off_outlined,
                label: 'Monitoreo de cámara',
                value: trip.hasCameraPermission ? 'Activo' : 'Sin cámara',
                valueColor: trip.hasCameraPermission
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
