import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/company_link_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/primary_button_widget.dart';

//Pantalla de selección de empresa activa para el conductor.
class SelectCompanyPage extends StatefulWidget {
  const SelectCompanyPage({super.key});

  @override
  State<SelectCompanyPage> createState() => _SelectCompanyPageState();
}

class _SelectCompanyPageState extends State<SelectCompanyPage> {
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  //Helpers

  //Extrae la lista de empresas del estado actual del BLoC.
  //Devuelve una lista vacía si el estado no es el esperado.
  List<CompanyLinkEntity> _companiesFromState(AuthState authState) {
    if (authState is AuthCompanySelectionRequired) return authState.companies;
    if (authState is AuthDriverAuthenticated) return authState.companies;
    return const [];
  }

  //Navega a la pantalla principal del conductor.
  void _goToDriverHome(BuildContext context, AuthDriverAuthenticated state) {
    context.go('/driver/home', extra: state);
  }

  //Build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      //Bloquea el botón "Atrás" del sistema para forzar la selección.
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
            //El BLoC emitió AuthDriverAuthenticated (empresa ya seleccionada y persistida) → navegar a Home.
            if (state is AuthDriverAuthenticated) {
              _goToDriverHome(context, state);
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthState authState) {
    if (authState is! AuthCompanySelectionRequired &&
        authState is! AuthDriverAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/role-selection');
      });
      return const SizedBox.shrink();
    }

    final companies = _companiesFromState(authState);

    //Caso 2: una sola empresa
    if (companies.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthBloc>().add(
              AuthCompanySelected(
                companyId: companies.first.companyId,
                companyName: companies.first.companyName,
              ),
            );
      });
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    //Caso 1: múltiples empresas
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primarySurface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: const Text(
              'Estás vinculado a más de una empresa. '
              'Selecciona la empresa con la que vas a trabajar hoy.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          //Lista de empresas
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final link = companies[index];
                final isSelected = _selectedCompanyId == link.companyId;

                return _CompanyTile(
                  link: link,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCompanyId = link.companyId;
                      _selectedCompanyName = link.companyName;
                    });
                  },
                );
              },
            ),
          ),

          //Botón Continuar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: PrimaryButtonWidget(
              label: 'Continuar',
              onPressed: _selectedCompanyId == null
                  ? null // Deshabilitado hasta que haya selección.
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

//Fila de empresa en la lista de selección.
class _CompanyTile extends StatelessWidget {
  const _CompanyTile({
    required this.link,
    required this.isSelected,
    required this.onTap,
  });

  final CompanyLinkEntity link;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isSelected ? AppColors.primarySurface : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // Radio button manual — no depende de RadioGroup.
            Radio<String>(
              value: link.companyId,
              groupValue: isSelected ? link.companyId : null,
              activeColor: AppColors.primary,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.companyName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link.cargo,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
