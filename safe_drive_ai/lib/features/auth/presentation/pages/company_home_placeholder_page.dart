import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/primary_button_widget.dart';

/// Pantalla temporal de home para la empresa.
///
/// Muestra el nombre de la empresa autenticada y un botón para cerrar sesión.
/// Será reemplazada por la pantalla real de dashboard en el feature de company.
class CompanyHomePlaceholderPage extends StatelessWidget {
  const CompanyHomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          context.go('/role-selection');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Safe Drive AI — Empresa'),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final String companyName;

                if (state is AuthCompanyAuthenticated) {
                  companyName = state.company.name;
                } else {
                  companyName = '';
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.business,
                      size: 72,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      companyName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Empresa autenticada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 48),
                    PrimaryButtonWidget(
                      label: 'Cerrar sesión',
                      onPressed: () {
                        context
                            .read<AuthBloc>()
                            .add(const AuthLogoutRequested());
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
