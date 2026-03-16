import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../bloc/company_bloc.dart';
import '../bloc/company_event.dart';

import '../../../../injection_container.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/get_driver_profile_usecase.dart';

/// Tarjeta que muestra los datos de un conductor vinculado a la empresa.
///
/// Incluye botón "Desvincular" con confirmación mediante AlertDialog.
class DriverCardWidget extends StatefulWidget {
  const DriverCardWidget({
    super.key,
    required this.link,
    required this.companyId,
    required this.onTap,
  });

  final CompanyLinkEntity link;
  final String companyId;
  final void Function(UserEntity profile) onTap;

  @override
  State<DriverCardWidget> createState() => _DriverCardWidgetState();
}

class _DriverCardWidgetState extends State<DriverCardWidget> {
  late Future<UserEntity?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<UserEntity?> _loadProfile() async {
    final useCase = di.sl<GetDriverProfileUseCase>();
    final result = await useCase(GetDriverProfileParams(driverId: widget.link.driverId));
    return result.fold(
      (failure) => null,
      (profile) => profile,
    );
  }

  Future<void> _confirmUnlink(BuildContext context, String driverName) async {
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
              linkId: widget.link.id,
              companyId: widget.companyId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserEntity?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final profile = snapshot.data;
        final driverName = profile?.name ?? 'Nombre no disponible';
        final driverEmail = profile?.email ?? 'Email no disponible';

        return InkWell(
          onTap: profile != null ? () => widget.onTap(profile) : null,
          borderRadius: BorderRadius.circular(12),
          child: Card(
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
                              driverEmail,
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
                          color: widget.link.status == LinkStatus.active
                              ? AppColors.successSurface
                              : AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.link.status == LinkStatus.active ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: widget.link.status == LinkStatus.active
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
                        widget.link.cargo,
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
                        widget.link.phone,
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
                      onPressed: () => _confirmUnlink(context, driverName),
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
          ),
        );
      },
    );
  }
}
