import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/company_link_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/primary_button_widget.dart';

/// Pantalla de selección de empresa activa para el conductor.
///
/// Solo se muestra cuando el conductor tiene más de una empresa vinculada
/// y no hay empresa activa guardada localmente. Bloquea la navegación hacia
/// atrás con [PopScope] para forzar la selección.
class SelectCompanyPage extends StatefulWidget {
  const SelectCompanyPage({super.key});

  @override
  State<SelectCompanyPage> createState() => _SelectCompanyPageState();
}

class _SelectCompanyPageState extends State<SelectCompanyPage> {
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Selecciona tu empresa'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthDriverAuthenticated) {
              context.go('/driver/home');
            }
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    final List<CompanyLinkEntity> companies;

    if (state is AuthCompanySelectionRequired) {
      companies = state.companies;
    } else {
      // Estado inesperado: redirige a selección de rol.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/role-selection');
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final link = companies[index];
                final isSelected = _selectedCompanyId == link.companyId;
                return RadioGroup<String>(
                  groupValue: _selectedCompanyId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCompanyId = value;
                      _selectedCompanyName = link.companyName;
                    });
                  },
                  child: ListTile(
                    leading: Radio<String>(
                      value: link.companyId,
                      activeColor: AppColors.primary,
                    ),
                    title: Text(
                      link.companyName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      link.cargo,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCompanyId = link.companyId;
                        _selectedCompanyName = link.companyName;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButtonWidget(
              label: 'Continuar',
              onPressed: _selectedCompanyId == null
                  ? null
                  : () {
                      context.read<AuthBloc>().add(
                            AuthCompanySelected(
                              companyId: _selectedCompanyId!,
                              companyName: _selectedCompanyName ?? '',
                            ),
                          );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
