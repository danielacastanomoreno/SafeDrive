// lib/core/constants/app_router.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';

/// Nombres de ruta centralizados — usar siempre estas constantes,
/// nunca strings literales en el código de navegación.
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';

  // Driver routes
  static const driverHome = '/driver/home';
  static const driverTrip = '/driver/trip';

  // Company routes
  static const companyHome = '/company/home';
  static const companyDrivers = '/company/drivers';
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ── Driver shell ──────────────────────────────────────────────────────
      // Se expanden al implementar las HUs de conductor.
      GoRoute(
        path: AppRoutes.driverHome,
        name: 'driverHome',
        builder: (context, state) => const _RoleGuardedPlaceholder(role: 'driver'),
      ),

      // ── Company shell ─────────────────────────────────────────────────────
      // Se expanden al implementar las HUs de empresa.
      GoRoute(
        path: AppRoutes.companyHome,
        name: 'companyHome',
        builder: (context, state) => const _RoleGuardedPlaceholder(role: 'company'),
      ),
    ],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );

  /// Redirección global: usuario no autenticado va a /login,
  /// usuario autenticado no puede volver a /login o /.
  /// El rol se resuelve en SplashPage después de leer Firestore.
  static String? _globalRedirect(BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.splash;

    if (user == null && !isAuthRoute) {
      return AppRoutes.login;
    }

    return null;
  }
}

// ─── Placeholder interno para rutas aún no implementadas ─────────────────────

class _RoleGuardedPlaceholder extends StatelessWidget {
  const _RoleGuardedPlaceholder({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Safe Drive AI — $role')),
      body: Center(
        child: Text(
          'Pantalla de $role en construcción.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error de navegación')),
      body: Center(
        child: Text(
          error?.toString() ?? 'Ruta no encontrada.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
