import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_session_usecase.dart';
import 'features/auth/domain/usecases/get_active_company_usecase.dart';
import 'features/auth/domain/usecases/get_current_company_usecase.dart';
import 'features/auth/domain/usecases/get_current_driver_usecase.dart';
import 'features/auth/domain/usecases/get_driver_companies_usecase.dart';
import 'features/auth/domain/usecases/login_company_usecase.dart';
import 'features/auth/domain/usecases/login_driver_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_company_usecase.dart';
import 'features/auth/domain/usecases/register_driver_usecase.dart';
import 'features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'features/auth/domain/usecases/set_active_company_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/company/data/datasources/company_datasource.dart';
import 'features/company/data/datasources/company_datasource_impl.dart';
import 'features/company/data/repositories/company_repository_impl.dart';
import 'features/company/domain/repositories/company_repository.dart';
import 'features/company/domain/usecases/cancel_invitation_usecase.dart';
import 'features/company/domain/usecases/get_company_drivers_usecase.dart';
import 'features/company/domain/usecases/get_company_invitations_usecase.dart';
import 'features/company/domain/usecases/get_driver_profile_usecase.dart';
import 'features/company/domain/usecases/register_driver_by_company_usecase.dart';
import 'features/company/domain/usecases/send_invitation_usecase.dart';
import 'features/company/domain/usecases/unlink_driver_usecase.dart';
import 'features/company/domain/usecases/update_company_profile_usecase.dart';
import 'features/company/domain/usecases/get_pending_trips_usecase.dart';
import 'features/company/domain/usecases/approve_trip_closure_usecase.dart';
import 'features/company/domain/usecases/reject_trip_closure_usecase.dart';
import 'features/company/domain/usecases/create_trip_with_destination_usecase.dart';
import 'features/company/presentation/bloc/company_bloc.dart';
import 'features/driver/data/datasources/driver_datasource.dart';
import 'features/driver/data/datasources/driver_datasource_impl.dart';
import 'features/driver/data/repositories/driver_repository_impl.dart';
import 'features/driver/domain/repositories/driver_repository.dart';
import 'features/driver/domain/usecases/accept_invitation_usecase.dart';
import 'features/driver/domain/usecases/get_driver_invitations_usecase.dart';
import 'features/driver/domain/usecases/get_driver_linked_companies_usecase.dart';
import 'features/driver/domain/usecases/reject_invitation_usecase.dart';
import 'features/driver/domain/usecases/update_driver_profile_usecase.dart';
import 'features/trips/data/datasources/trip_datasource.dart';
import 'features/trips/data/datasources/trip_datasource_impl.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/trips/domain/repositories/trip_repository.dart';
import 'features/trips/domain/usecases/end_trip_usecase.dart';
import 'features/trips/domain/usecases/get_active_trip_usecase.dart';
import 'features/trips/domain/usecases/get_trip_route_usecase.dart';
import 'features/trips/domain/usecases/save_route_point_usecase.dart';
import 'features/trips/domain/usecases/start_trip_usecase.dart';
import 'features/trips/domain/usecases/request_remote_closure_usecase.dart';
import 'features/trips/domain/usecases/listen_to_approval_stream_usecase.dart';
import 'features/trips/domain/usecases/end_trip_with_zone_check_usecase.dart';
import 'features/trips/domain/usecases/get_driver_trips_usecase.dart';

/// Contenedor global de inyección de dependencias de Safe Drive AI.
///
/// Uso: llamar `await di.init()` en `main.dart` antes de `runApp`.
/// El [AuthBloc] está registrado como `factory` para garantizar una instancia
/// fresca en cada provisión, mientras que los UseCases son `LazySingleton`
/// para reutilizar la misma instancia a lo largo del ciclo de vida del app.
final GetIt sl = GetIt.instance;

Future<void> init() async {
  // ── Firebase ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // ── SharedPreferences ─────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Features ──────────────────────────────────────────────────────────────
  _initAuth();
  _initCompany();
  _initDriver();
  _initTrips();
}

void _initAuth() {
  // Datasource
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      sharedPreferences: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CheckSessionUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentDriverUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentCompanyUseCase(sl()));
  sl.registerLazySingleton(() => LoginDriverUseCase(sl()));
  sl.registerLazySingleton(() => LoginCompanyUseCase(sl()));
  sl.registerLazySingleton(() => RegisterCompanyUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));
  sl.registerLazySingleton(() => GetDriverCompaniesUseCase(sl()));
  sl.registerLazySingleton(() => SetActiveCompanyUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveCompanyUseCase(sl()));

  // BLoC — factory para instancia fresca en cada BlocProvider
  sl.registerFactory(
    () => AuthBloc(
      checkSessionUseCase: sl(),
      getCurrentDriverUseCase: sl(),
      getCurrentCompanyUseCase: sl(),
      loginDriverUseCase: sl(),
      loginCompanyUseCase: sl(),
      registerCompanyUseCase: sl(),
      registerDriverUseCase: sl(),
      logoutUseCase: sl(),
      sendPasswordResetUseCase: sl(),
      getDriverCompaniesUseCase: sl(),
      setActiveCompanyUseCase: sl(),
      getActiveCompanyUseCase: sl(),
    ),
  );
}

void _initCompany() {
  // Datasource
  sl.registerLazySingleton<CompanyDatasource>(
    () => CompanyDatasourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<CompanyRepository>(
    () => CompanyRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCompanyDriversUseCase(sl()));
  sl.registerLazySingleton(() => GetDriverProfileUseCase(sl()));
  sl.registerLazySingleton(() => UnlinkDriverUseCase(sl()));
  sl.registerLazySingleton(() => SendInvitationUseCase(sl()));
  sl.registerLazySingleton(() => GetCompanyInvitationsUseCase(sl()));
  sl.registerLazySingleton(() => CancelInvitationUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCompanyProfileUseCase(sl()));
  sl.registerLazySingleton(() => RegisterDriverByCompanyUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingTripsUseCase(sl()));
  sl.registerLazySingleton(() => ApproveTripClosureUseCase(sl()));
  sl.registerLazySingleton(() => RejectTripClosureUseCase(sl()));
  sl.registerLazySingleton(() => CreateTripWithDestinationUseCase(sl()));

  // BLoC — factory para instancia fresca en cada CompanyHomePage
  sl.registerFactory(
    () => CompanyBloc(
      getCompanyDriversUseCase: sl(),
      unlinkDriverUseCase: sl(),
      sendInvitationUseCase: sl(),
      getCompanyInvitationsUseCase: sl(),
      cancelInvitationUseCase: sl(),
      updateCompanyProfileUseCase: sl(),
      registerDriverByCompanyUseCase: sl(),
      getPendingTripsUseCase: sl(),
      approveTripClosureUseCase: sl(),
      rejectTripClosureUseCase: sl(),
    ),
  );
}

void _initDriver() {
  // Datasource
  sl.registerLazySingleton<DriverDatasource>(
    () => DriverDatasourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDriverInvitationsUseCase(sl()));
  sl.registerLazySingleton(() => AcceptInvitationUseCase(sl()));
  sl.registerLazySingleton(() => RejectInvitationUseCase(sl()));
  sl.registerLazySingleton(() => GetDriverLinkedCompaniesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDriverProfileUseCase(sl()));
}

void _initTrips() {
  // Datasource
  sl.registerLazySingleton<TripDatasource>(
    () => TripDatasourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => StartTripUseCase(sl()));
  sl.registerLazySingleton(() => EndTripUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveTripUseCase(sl()));
  sl.registerLazySingleton(() => SaveRoutePointUseCase(sl()));
  sl.registerLazySingleton(() => GetTripRouteUseCase(sl()));
  sl.registerLazySingleton(() => GetDriverTripsUseCase(sl()));

  // Closure UseCases
  sl.registerLazySingleton(() => RequestRemoteClosureUseCase(sl()));
  sl.registerLazySingleton(() => ListenToApprovalStreamUseCase(sl()));
  sl.registerLazySingleton(() => EndTripWithZoneCheckUseCase(sl()));
}
