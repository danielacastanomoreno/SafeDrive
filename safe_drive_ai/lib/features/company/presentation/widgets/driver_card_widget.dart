import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';

/// Tarjeta que muestra los datos de un conductor vinculado a la empresa.
///
/// Incluye botón "Desvincular" con confirmación mediante AlertDialog.
class DriverCardWidget extends StatelessWidget {
  const DriverCardWidget({
    super.key,
    required this.link,
    required this.companyId,
    required this.driverName,
    required this.driverCedula,
  });

  final CompanyLinkEntity link;
  final String companyId;
  final String driverName;
  final String driverCedula;

  Future<void> _confirmUnlink(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desvincular conductor'),
        content: Text(
          '¿Estás seguro de que deseas desvincular a $driverName de tu empresa? '
          'Esta acción no se puede deshacer desde la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Desvincular',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CompanyBloc>().add(
            CompanyDriverUnlinkRequested(
              linkId: link.id,
              companyId: companyId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'C.C. $driverCedula',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: link.status == LinkStatus.active
                        ? AppColors.successSurface
                        : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    link.status == LinkStatus.active ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: link.status == LinkStatus.active
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  link.cargo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.phone_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  link.phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _confirmUnlink(context),
                icon: const Icon(
                  Icons.link_off,
                  size: 16,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Desvincular',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
