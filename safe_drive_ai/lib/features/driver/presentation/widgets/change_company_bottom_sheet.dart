import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../trips/presentation/bloc/trip_bloc.dart';
import '../../../trips/presentation/bloc/trip_state.dart';

/// Muestra el bottom sheet de "Cambiar empresa activa".
///
/// Retorna `true` si el cambio fue realizado, `null` en caso contrario.
Future<bool?> showChangeCompanyBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<AuthBloc>()),
        BlocProvider.value(value: context.read<TripBloc>()),
      ],
      child: const _ChangeCompanySheet(),
    ),
  );
}

class _ChangeCompanySheet extends StatefulWidget {
  const _ChangeCompanySheet();

  @override
  State<_ChangeCompanySheet> createState() => _ChangeCompanySheetState();
}

class _ChangeCompanySheetState extends State<_ChangeCompanySheet> {
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasTripInProgress(TripState tripState) {
    return tripState is TripActive ||
        tripState is TripPendingApproval ||
        tripState is TripClosureLoading ||
        tripState is TripClosureRequested;
  }

  List<CompanyLinkEntity> _activeCompanies(
    List<CompanyLinkEntity> companies,
  ) =>
      companies
          .where((c) => c.status == LinkStatus.active)
          .toList();

  void _onConfirm(BuildContext context) {
    if (_selectedCompanyId == null) return;
    context.read<AuthBloc>().add(
          AuthActiveCompanyChangeRequested(
            companyId: _selectedCompanyId!,
            companyName: _selectedCompanyName ?? '',
          ),
        );
    Navigator.of(context).pop(true);
    _showSuccessSnackBar(context, _selectedCompanyName ?? '');
  }

  void _showSuccessSnackBar(BuildContext context, String companyName) {
    // El ScaffoldMessenger debe ser del contexto padre (fuera del sheet).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ahora estás trabajando para $companyName.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, tripState) {
        final tripInProgress = _hasTripInProgress(tripState);

        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final companies = authState is AuthDriverAuthenticated
                ? _activeCompanies(authState.companies)
                : <CompanyLinkEntity>[];

            final currentActiveId = authState is AuthDriverAuthenticated
                ? authState.activeCompanyId
                : null;

            // Inicializa la selección con la empresa actual al abrir.
            if (_selectedCompanyId == null && currentActiveId != null) {
              _selectedCompanyId = currentActiveId;
              try {
                _selectedCompanyName = companies
                    .firstWhere((c) => c.companyId == currentActiveId)
                    .companyName;
              } catch (_) {}
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle ──────────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Título ──────────────────────────────────────────────
                    const Text(
                      'Cambiar empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecciona la empresa con la que deseas continuar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Aviso de viaje en curso ──────────────────────────────
                    if (tripInProgress) ...[
                      _TripInProgressBanner(),
                      const SizedBox(height: 16),
                    ],

                    // ── Lista de empresas ────────────────────────────────────
                    if (companies.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No tienes empresas vinculadas.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...companies.map(
                        (link) => _CompanyOption(
                          link: link,
                          isSelected: _selectedCompanyId == link.companyId,
                          isActive: currentActiveId == link.companyId,
                          enabled: !tripInProgress,
                          onTap: tripInProgress
                              ? null
                              : () => setState(() {
                                    _selectedCompanyId = link.companyId;
                                    _selectedCompanyName = link.companyName;
                                  }),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Botón Cambiar ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: tripInProgress
                              ? AppColors.divider
                              : AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (tripInProgress ||
                                _selectedCompanyId == null ||
                                _selectedCompanyId == currentActiveId)
                            ? null
                            : () => _onConfirm(context),
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

/// Banner de advertencia cuando hay un viaje en curso.
class _TripInProgressBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block_outlined, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No puedes cambiar de empresa con un viaje en curso.\n'
              'Finaliza el viaje primero.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila seleccionable que representa una empresa en la lista.
class _CompanyOption extends StatelessWidget {
  const _CompanyOption({
    required this.link,
    required this.isSelected,
    required this.isActive,
    required this.enabled,
    required this.onTap,
  });

  final CompanyLinkEntity link;
  final bool isSelected;

  /// `true` si esta es la empresa actualmente activa (antes del cambio).
  final bool isActive;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Radio button manual
              Radio<String>(
                value: link.companyId,
                groupValue: isSelected ? link.companyId : null,
                activeColor: AppColors.primary,
                onChanged: enabled ? (_) => onTap?.call() : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            link.companyName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: enabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Activa',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.cargo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
