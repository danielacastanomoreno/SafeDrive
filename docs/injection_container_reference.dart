// lib/injection_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // ─── Firebase Instances ───────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // ─── Features ─────────────────────────────────────────────────────────────
  // Se registran aquí a medida que se implementan las HUs.
  // Orden recomendado por feature:
  //   1. DataSources
  //   2. Repositories
  //   3. UseCases
  //   4. BLoCs / Cubits
  //
  // Ejemplo (auth feature — se descomenta al implementar HU1):
  // _initAuth();
}

// void _initAuth() {
//   sl.registerLazySingleton<AuthRemoteDataSource>(
//     () => AuthRemoteDataSourceImpl(auth: sl(), firestore: sl()),
//   );
//   sl.registerLazySingleton<AuthRepository>(
//     () => AuthRepositoryImpl(remoteDataSource: sl()),
//   );
//   sl.registerLazySingleton(() => LoginUseCase(sl()));
//   sl.registerLazySingleton(() => LogoutUseCase(sl()));
//   sl.registerFactory(() => AuthBloc(loginUseCase: sl(), logoutUseCase: sl()));
// }
