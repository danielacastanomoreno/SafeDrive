import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

//Pantalla inicial de Safe Drive AI.
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
        } else if (state is AuthRoleRemembered) {
          if (state.role == 'driver') {
            context.go('/driver/login');
          } else if (state.role == 'company') {
            context.go('/company/login');
          } else {
            context.go('/role-selection');
          }
        } else if (state is AuthDriverAuthenticated) {
          //Caso 2: una empresa → activeCompanyId ya viene resuelto en el BLoC.
          final requiresSelection =
              state.companies.length > 1 && state.activeCompanyId == null;

          if (requiresSelection) {
            context.go('/driver/select-company');
          } else {
            context.go('/driver/home', extra: state);
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
