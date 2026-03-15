import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/invitation_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';

/// Tarjeta que muestra el estado de una invitación enviada por la empresa.
///
/// Color del chip de estado:
///   - pending   → warning
///   - accepted  → success
///   - rejected  → error
///   - cancelled → error
///
/// Muestra botón "Cancelar" únicamente cuando el estado es [InvitationStatus.pending].
class InvitationCardWidget extends StatelessWidget {
  const InvitationCardWidget({
    super.key,
    required this.invitation,
    required this.companyId,
  });

  final InvitationEntity invitation;
  final String companyId;

  Color _statusColor() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return AppColors.warning;
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.rejected:
      case InvitationStatus.cancelled:
        return AppColors.error;
    }
  }

  Color _statusSurface() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return AppColors.warningSurface;
      case InvitationStatus.accepted:
        return AppColors.successSurface;
      case InvitationStatus.rejected:
      case InvitationStatus.cancelled:
        return AppColors.errorSurface;
    }
  }

  String _statusLabel() {
    switch (invitation.status) {
      case InvitationStatus.pending:
        return 'Pendiente';
      case InvitationStatus.accepted:
        return 'Aceptada';
      case InvitationStatus.rejected:
        return 'Rechazada';
      case InvitationStatus.cancelled:
        return 'Cancelada';
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar invitación'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta invitación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CompanyBloc>().add(
            CompanyInvitationCancelRequested(
              invitationId: invitation.id,
              companyId: companyId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.cargo,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invitation.phone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusSurface(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enviada: ${dateFormatter.format(invitation.sentAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (invitation.resolvedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Resuelta: ${dateFormatter.format(invitation.resolvedAt!)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            if (invitation.status == InvitationStatus.pending) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _confirmCancel(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancelar invitación',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
