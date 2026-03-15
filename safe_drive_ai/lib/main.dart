import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_routes.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart' as di;

/// Observer global de BLoC para trazabilidad en desarrollo.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    debugPrint('[BLoC] ${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('[BLoC] ${bloc.runtimeType} ERROR: $error');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();

  Bloc.observer = const AppBlocObserver();

  runApp(
    BlocProvider(
      create: (_) => di.sl<AuthBloc>(),
      child: const SafeDriveApp(),
    ),
  );
}

/// Widget raíz de Safe Drive AI.
///
/// Usa [MaterialApp.router] con el [AppRouter.router] de GoRouter.
/// El [AuthBloc] se provee en este nivel para que todas las rutas
/// compartan la misma instancia a través de [context.read<AuthBloc>()].
class SafeDriveApp extends StatelessWidget {
  const SafeDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Safe Drive AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: AppRouter.router,
    );
  }
}
