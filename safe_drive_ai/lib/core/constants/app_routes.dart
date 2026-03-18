import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/company_entity.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/company_login_page.dart';
import '../../features/auth/presentation/pages/company_register_page.dart';
import '../../features/auth/presentation/pages/driver_login_page.dart';
import '../../features/auth/presentation/pages/driver_register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/select_company_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/domain/entities/company_link_entity.dart';
import '../../features/company/presentation/pages/company_driver_detail_page.dart';
import '../../features/company/presentation/pages/company_home_page.dart';
import '../../features/company/presentation/pages/register_driver_page.dart';
import '../../features/company/presentation/pages/create_trip_page.dart';
import '../../features/company/presentation/pages/trip_approval_detail_page.dart';
import '../../features/driver/presentation/pages/driver_home_page.dart';
import '../../features/trips/domain/entities/trip_entity.dart';
import '../../features/trips/presentation/pages/trip_summary_page.dart';

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
        path: '/driver/register',
        builder: (context, state) => const DriverRegisterPage(),
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
      GoRoute(
        path: '/company/register-driver',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          if (extra == null) return const SizedBox.shrink();
          return RegisterDriverPage(
            companyId: extra['companyId']!,
            companyName: extra['companyName']!,
          );
        },
      ),
      GoRoute(
        path: '/company/driver-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const SizedBox.shrink();
          return CompanyDriverDetailPage(
            link: extra['link'] as CompanyLinkEntity,
            profile: extra['profile'] as UserEntity,
          );
        },
      ),
      GoRoute(
        path: '/company/create-trip',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const SizedBox.shrink();
          return CreateTripPage(
            companyId: extra['companyId'] as String,
            driverId: extra['driverId'] as String,
            driverName: extra['driverName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/company/trip-approval',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const RoleSelectionPage();
          return TripApprovalDetailPage(
            trip: extra['trip'] as TripEntity,
            companyId: extra['companyId'] as String,
          );
        },
      ),
      GoRoute(
        path: '/trip/summary',
        builder: (context, state) {
          final trip = state.extra as TripEntity?;
          if (trip == null) return const RoleSelectionPage();
          return TripSummaryPage(trip: trip);
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
