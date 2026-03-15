import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../company/domain/entities/invitation_entity.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tarjeta que representa una invitación de empresa al conductor.
///
/// - Pending: muestra botones "Aceptar" y "Rechazar".
/// - Accepted / Rejected / Cancelled: solo muestra badge de estado.
class DriverInvitationCardWidget extends StatelessWidget {
  const DriverInvitationCardWidget({
    super.key,
    required this.invitation,
    required this.driverId,
  });

  final InvitationEntity invitation;
  final String driverId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invitation.companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(status: invitation.status),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.work_outline,
              text: 'Cargo: ${invitation.cargo}',
            ),
            const SizedBox(height: 2),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: 'Teléfono: ${invitation.phone}',
            ),
            if (invitation.status == InvitationStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.read<DriverBloc>().add(
                            DriverInvitationRejected(
                              invitationId: invitation.id,
                              driverId: driverId,
                            ),
                          ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.read<DriverBloc>().add(
                            DriverInvitationAccepted(
                              invitationId: invitation.id,
                              companyId: invitation.companyId,
                              companyName: invitation.companyName,
                              driverId: driverId,
                              cargo: invitation.cargo,
                              phone: invitation.phone,
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return AppColors.warningSurface;
      case InvitationStatus.accepted:
        return AppColors.successSurface;
      case InvitationStatus.rejected:
        return AppColors.errorSurface;
      case InvitationStatus.cancelled:
        return const Color(0xFFF5F5F5);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final InvitationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == InvitationStatus.pending) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color get _badgeColor {
    switch (status) {
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.rejected:
        return AppColors.error;
      case InvitationStatus.cancelled:
        return AppColors.textSecondary;
      case InvitationStatus.pending:
        return AppColors.warning;
    }
  }

  String get _label {
    switch (status) {
      case InvitationStatus.accepted:
        return 'Aceptada';
      case InvitationStatus.rejected:
        return 'Rechazada';
      case InvitationStatus.cancelled:
        return 'Cancelada';
      case InvitationStatus.pending:
        return 'Pendiente';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
