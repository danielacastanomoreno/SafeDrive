import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/primary_button_widget.dart';

/// Pantalla temporal de home para el conductor.
///
/// Muestra el nombre del conductor autenticado y un botón para cerrar sesión.
/// Será reemplazada por la pantalla real de home en el feature de trips.
class DriverHomePlaceholderPage extends StatelessWidget {
  const DriverHomePlaceholderPage({super.key});

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
          title: const Text('Safe Drive AI'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final String driverName;
                final String activeCompanyId;

                if (state is AuthDriverAuthenticated) {
                  driverName = state.user.name;
                  activeCompanyId = state.activeCompanyId ?? 'Sin empresa';
                } else {
                  driverName = '';
                  activeCompanyId = '';
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.drive_eta,
                      size: 72,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hola, $driverName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Conductor autenticado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    if (activeCompanyId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Empresa activa: $activeCompanyId',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
