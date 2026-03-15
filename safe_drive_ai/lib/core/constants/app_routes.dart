import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/company_entity.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/company_login_page.dart';
import '../../features/auth/presentation/pages/company_register_page.dart';
import '../../features/auth/presentation/pages/driver_login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/select_company_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/company/presentation/pages/company_home_page.dart';
import '../../features/driver/presentation/pages/driver_home_page.dart';

/// Configuración del router de Safe Drive AI.
///
/// La lógica de redirección basada en autenticación la maneja [SplashPage]
/// vía [BlocListener]. El router no usa `redirect` con Firebase directamente,
/// lo que mantiene la separación de responsabilidades entre navegación y BLoC.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: '/driver/login',
        builder: (context, state) => const DriverLoginPage(),
      ),
      GoRoute(
        path: '/company/login',
        builder: (context, state) => const CompanyLoginPage(),
      ),
      GoRoute(
        path: '/company/register',
        builder: (context, state) => const CompanyRegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/driver/select-company',
        builder: (context, state) => const SelectCompanyPage(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) {
          final authState = state.extra as AuthDriverAuthenticated?;
          if (authState == null) {
            return const RoleSelectionPage();
          }
          return DriverHomePage(
            driver: authState.user,
            companies: authState.companies,
          );
        },
      ),
      GoRoute(
        path: '/company/home',
        builder: (context, state) {
          final company = state.extra as CompanyEntity?;
          if (company == null) {
            return const RoleSelectionPage();
          }
          return CompanyHomePage(company: company);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
}
