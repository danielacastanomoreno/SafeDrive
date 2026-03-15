import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pantalla inicial de Safe Drive AI.
///
/// Dispara [AuthCheckSessionRequested] en [initState] y escucha el estado del
/// [AuthBloc] para redirigir al destino correcto sin lógica de negocio propia.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCheckSessionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRoleNotSelected) {
          context.go('/role-selection');
        } else if (state is AuthDriverAuthenticated) {
          if (state.activeCompanyId != null) {
            context.go('/driver/home', extra: state);
          } else {
            context.go('/driver/select-company');
          }
        } else if (state is AuthCompanyAuthenticated) {
          context.go('/company/home', extra: state.company);
        } else if (state is AuthCompanySelectionRequired) {
          context.go('/driver/select-company');
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Safe Drive AI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
