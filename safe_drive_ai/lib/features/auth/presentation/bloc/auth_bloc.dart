import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_session_usecase.dart';
import '../../domain/usecases/get_active_company_usecase.dart';
import '../../domain/usecases/get_current_company_usecase.dart';
import '../../domain/usecases/get_current_driver_usecase.dart';
import '../../domain/usecases/get_driver_companies_usecase.dart';
import '../../domain/usecases/login_company_usecase.dart';
import '../../domain/usecases/login_driver_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_company_usecase.dart';
import '../../domain/usecases/register_driver_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/set_active_company_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC de autenticación de Safe Drive AI.
///
/// Solo conoce UseCases del dominio. No importa ningún repositorio,
/// ningún datasource ni ningún paquete de Firebase directamente.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required CheckSessionUseCase checkSessionUseCase,
    required GetCurrentDriverUseCase getCurrentDriverUseCase,
    required GetCurrentCompanyUseCase getCurrentCompanyUseCase,
    required LoginDriverUseCase loginDriverUseCase,
    required LoginCompanyUseCase loginCompanyUseCase,
    required RegisterCompanyUseCase registerCompanyUseCase,
    required RegisterDriverUseCase registerDriverUseCase,
    required LogoutUseCase logoutUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
    required GetDriverCompaniesUseCase getDriverCompaniesUseCase,
    required SetActiveCompanyUseCase setActiveCompanyUseCase,
    required GetActiveCompanyUseCase getActiveCompanyUseCase,
  })  : _checkSessionUseCase = checkSessionUseCase,
        _getCurrentDriverUseCase = getCurrentDriverUseCase,
        _getCurrentCompanyUseCase = getCurrentCompanyUseCase,
        _loginDriverUseCase = loginDriverUseCase,
        _loginCompanyUseCase = loginCompanyUseCase,
        _registerCompanyUseCase = registerCompanyUseCase,
        _registerDriverUseCase = registerDriverUseCase,
        _logoutUseCase = logoutUseCase,
        _sendPasswordResetUseCase = sendPasswordResetUseCase,
        _getDriverCompaniesUseCase = getDriverCompaniesUseCase,
        _setActiveCompanyUseCase = setActiveCompanyUseCase,
        _getActiveCompanyUseCase = getActiveCompanyUseCase,
        super(const AuthInitial()) {
    on<AuthCheckSessionRequested>(_onCheckSession);
    on<AuthDriverLoginRequested>(_onDriverLogin);
    on<AuthCompanyLoginRequested>(_onCompanyLogin);
    on<AuthCompanyRegisterRequested>(_onCompanyRegister);
    on<AuthDriverRegisterRequested>(_onDriverRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthCompanySelected>(_onCompanySelected);
    on<AuthActiveCompanyChangeRequested>(_onActiveCompanyChange);
  }

  final CheckSessionUseCase _checkSessionUseCase;
  final GetCurrentDriverUseCase _getCurrentDriverUseCase;
  final GetCurrentCompanyUseCase _getCurrentCompanyUseCase;
  final LoginDriverUseCase _loginDriverUseCase;
  final LoginCompanyUseCase _loginCompanyUseCase;
  final RegisterCompanyUseCase _registerCompanyUseCase;
  final RegisterDriverUseCase _registerDriverUseCase;
  final LogoutUseCase _logoutUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;
  final GetDriverCompaniesUseCase _getDriverCompaniesUseCase;
  final SetActiveCompanyUseCase _setActiveCompanyUseCase;
  final GetActiveCompanyUseCase _getActiveCompanyUseCase;

  // ── Handlers ────────────────────────────────────────────────────────────────

  /// Verifica la sesión persistida al abrir la app.
  ///
  /// Flujo:
  /// 1. Lee el rol guardado en SharedPreferences con [CheckSessionUseCase].
  /// 2. Si el rol es `'driver'`, rehidrata el conductor con
  ///    [GetCurrentDriverUseCase] y sus empresas con [GetDriverCompaniesUseCase].
  ///    Si Firebase Auth ya no tiene sesión activa, el UseCase devuelve
  ///    [Left] y se forza re-login emitiendo [AuthRoleNotSelected].
  /// 3. Si el rol es `'company'`, rehidrata la empresa con
  ///    [GetCurrentCompanyUseCase]. Mismo comportamiento ante sesión expirada.
  /// 4. Si no hay rol guardado o cualquier paso falla → [AuthRoleNotSelected].
  Future<void> _onCheckSession(
    AuthCheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final sessionResult = await _checkSessionUseCase(const NoParams());

    await sessionResult.fold(
      (_) async => emit(const AuthRoleNotSelected()),
      (role) async {
        if (role == 'driver') {
          await _rehidrateDriver(emit);
        } else if (role == 'company') {
          await _rehidrateCompany(emit);
        } else {
          emit(const AuthRoleNotSelected());
        }
      },
    );
  }

  /// Rehidrata la sesión de un conductor usando Firebase Auth + Firestore.
  ///
  /// Si el uid de Firebase Auth es válido y el documento existe, emite
  /// [AuthDriverAuthenticated]. En cualquier otro caso emite [AuthRoleNotSelected].
  Future<void> _rehidrateDriver(Emitter<AuthState> emit) async {
    final driverResult = await _getCurrentDriverUseCase(const NoParams());

    await driverResult.fold(
      (_) async => emit(const AuthRoleNotSelected()),
      (user) async {
        final companiesResult = await _getDriverCompaniesUseCase(
          GetDriverCompaniesParams(driverId: user.id),
        );

        await companiesResult.fold(
          (_) async => emit(const AuthRoleNotSelected()),
          (companies) async {
            final activeIdResult =
                await _getActiveCompanyUseCase(const NoParams());

            final activeCompanyId =
                activeIdResult.fold((_) => null, (id) => id);

            emit(
              AuthDriverAuthenticated(
                user: user,
                companies: companies,
                activeCompanyId: activeCompanyId ??
                    (companies.length == 1 ? companies.first.companyId : null),
              ),
            );
          },
        );
      },
    );
  }

  /// Rehidrata la sesión de una empresa usando Firebase Auth + Firestore.
  ///
  /// Si el uid de Firebase Auth es válido y el documento existe, emite
  /// [AuthCompanyAuthenticated]. En cualquier otro caso emite [AuthRoleNotSelected].
  Future<void> _rehidrateCompany(Emitter<AuthState> emit) async {
    final companyResult = await _getCurrentCompanyUseCase(const NoParams());

    companyResult.fold(
      (_) => emit(const AuthRoleNotSelected()),
      (company) => emit(AuthCompanyAuthenticated(company: company)),
    );
  }

  /// Inicia sesión como conductor.
  Future<void> _onDriverLogin(
    AuthDriverLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final loginResult = await _loginDriverUseCase(
      LoginDriverParams(email: event.email, password: event.password),
    );

    await loginResult.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (user) async {
        final companiesResult = await _getDriverCompaniesUseCase(
          GetDriverCompaniesParams(driverId: user.id),
        );

        await companiesResult.fold(
          (failure) async => emit(AuthError(message: failure.message)),
          (companies) async {
            if (companies.length <= 1) {
              if (companies.length == 1) {
                await _setActiveCompanyUseCase(
                  SetActiveCompanyParams(
                    companyId: companies.first.companyId,
                  ),
                );
              }
              emit(
                AuthDriverAuthenticated(
                  user: user,
                  companies: companies,
                  activeCompanyId:
                      companies.isEmpty ? null : companies.first.companyId,
                ),
              );
            } else {
              emit(
                AuthCompanySelectionRequired(
                  user: user,
                  companies: companies,
                ),
              );
            }
          },
        );
      },
    );
  }

  /// Inicia sesión como empresa.
  Future<void> _onCompanyLogin(
    AuthCompanyLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _loginCompanyUseCase(
      LoginCompanyParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (company) => emit(AuthCompanyAuthenticated(company: company)),
    );
  }

  /// Registra una nueva empresa.
  Future<void> _onCompanyRegister(
    AuthCompanyRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _registerCompanyUseCase(
      RegisterCompanyParams(
        name: event.name,
        nit: event.nit,
        email: event.email,
        password: event.password,
        representativeName: event.representativeName,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (company) => emit(AuthCompanyAuthenticated(company: company)),
    );
  }

  /// Registra un nuevo conductor independiente.
  Future<void> _onDriverRegister(
    AuthDriverRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _registerDriverUseCase(
      RegisterDriverParams(
        name: event.name,
        cedula: event.cedula,
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(
        AuthDriverAuthenticated(
          user: user,
          companies: const [], // A new driver starts with 0 companies linked
          activeCompanyId: null,
        ),
      ),
    );
  }

  /// Cierra la sesión activa.
  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase(const NoParams());
    emit(const AuthLoggedOut());
  }

  /// Envía el correo de recuperación de contraseña.
  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _sendPasswordResetUseCase(
      SendPasswordResetParams(email: event.email),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  /// Confirma la empresa seleccionada por el conductor y persiste la elección.
  Future<void> _onCompanySelected(
    AuthCompanySelected event,
    Emitter<AuthState> emit,
  ) async {
    await _setActiveCompanyUseCase(
      SetActiveCompanyParams(companyId: event.companyId),
    );

    final currentState = state;
    if (currentState is AuthCompanySelectionRequired) {
      emit(
        AuthDriverAuthenticated(
          user: currentState.user,
          companies: currentState.companies,
          activeCompanyId: event.companyId,
        ),
      );
    } else if (currentState is AuthDriverAuthenticated) {
      emit(
        AuthDriverAuthenticated(
          user: currentState.user,
          companies: currentState.companies,
          activeCompanyId: event.companyId,
        ),
      );
    }
    // Si el estado actual no es ninguno de los anteriores, la persistencia
    // ya fue ejecutada y no se necesita emitir un nuevo estado.
  }

  /// Cambia la empresa activa del conductor.
  Future<void> _onActiveCompanyChange(
    AuthActiveCompanyChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _setActiveCompanyUseCase(
      SetActiveCompanyParams(companyId: event.companyId),
    );

    final currentState = state;
    if (currentState is AuthDriverAuthenticated) {
      emit(
        AuthDriverAuthenticated(
          user: currentState.user,
          companies: currentState.companies,
          activeCompanyId: event.companyId,
        ),
      );
    } else if (currentState is AuthCompanySelectionRequired) {
      emit(
        AuthDriverAuthenticated(
          user: currentState.user,
          companies: currentState.companies,
          activeCompanyId: event.companyId,
        ),
      );
    }
  }
}
