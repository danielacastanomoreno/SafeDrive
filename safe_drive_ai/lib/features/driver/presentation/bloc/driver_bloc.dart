import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/accept_invitation_usecase.dart';
import '../../domain/usecases/get_driver_invitations_usecase.dart';
import '../../domain/usecases/get_driver_linked_companies_usecase.dart';
import '../../domain/usecases/reject_invitation_usecase.dart';
import '../../domain/usecases/update_driver_profile_usecase.dart';
import 'driver_event.dart';
import 'driver_state.dart';

/// BLoC del feature driver.
///
/// Solo conoce UseCases del dominio. No importa repositorios,
/// datasources ni paquetes de Firebase directamente.
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  DriverBloc({
    required GetDriverInvitationsUseCase getDriverInvitationsUseCase,
    required AcceptInvitationUseCase acceptInvitationUseCase,
    required RejectInvitationUseCase rejectInvitationUseCase,
    required GetDriverLinkedCompaniesUseCase getDriverLinkedCompaniesUseCase,
    required UpdateDriverProfileUseCase updateDriverProfileUseCase,
  })  : _getDriverInvitationsUseCase = getDriverInvitationsUseCase,
        _acceptInvitationUseCase = acceptInvitationUseCase,
        _rejectInvitationUseCase = rejectInvitationUseCase,
        _getDriverLinkedCompaniesUseCase = getDriverLinkedCompaniesUseCase,
        _updateDriverProfileUseCase = updateDriverProfileUseCase,
        super(const DriverInitial()) {
    on<DriverInvitationsRequested>(_onInvitationsRequested);
    on<DriverInvitationAccepted>(_onInvitationAccepted);
    on<DriverInvitationRejected>(_onInvitationRejected);
    on<DriverCompaniesRequested>(_onCompaniesRequested);
    on<DriverProfileRequested>(_onProfileRequested);
    on<DriverProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  final GetDriverInvitationsUseCase _getDriverInvitationsUseCase;
  final AcceptInvitationUseCase _acceptInvitationUseCase;
  final RejectInvitationUseCase _rejectInvitationUseCase;
  final GetDriverLinkedCompaniesUseCase _getDriverLinkedCompaniesUseCase;
  final UpdateDriverProfileUseCase _updateDriverProfileUseCase;

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onInvitationsRequested(
    DriverInvitationsRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    final result = await _getDriverInvitationsUseCase(
      GetDriverInvitationsParams(driverId: event.driverId),
    );

    result.fold(
      (failure) => emit(DriverError(message: failure.message)),
      (invitations) => emit(DriverInvitationsLoaded(invitations: invitations)),
    );
  }

  Future<void> _onInvitationAccepted(
    DriverInvitationAccepted event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    final result = await _acceptInvitationUseCase(
      AcceptInvitationParams(
        invitationId: event.invitationId,
        companyId: event.companyId,
        companyName: event.companyName,
        driverId: event.driverId,
        cargo: event.cargo,
        phone: event.phone,
      ),
    );

    await result.fold(
      (failure) async => emit(DriverError(message: failure.message)),
      (_) async {
        emit(const DriverActionSuccess(message: 'Invitación aceptada'));
        add(DriverInvitationsRequested(driverId: event.driverId));
      },
    );
  }

  Future<void> _onInvitationRejected(
    DriverInvitationRejected event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    final result = await _rejectInvitationUseCase(
      RejectInvitationParams(invitationId: event.invitationId),
    );

    await result.fold(
      (failure) async => emit(DriverError(message: failure.message)),
      (_) async {
        emit(const DriverActionSuccess(message: 'Invitación rechazada'));
        add(DriverInvitationsRequested(driverId: event.driverId));
      },
    );
  }

  Future<void> _onCompaniesRequested(
    DriverCompaniesRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    final result = await _getDriverLinkedCompaniesUseCase(
      GetDriverLinkedCompaniesParams(driverId: event.driverId),
    );

    result.fold(
      (failure) => emit(DriverError(message: failure.message)),
      (companies) => emit(DriverCompaniesLoaded(companies: companies)),
    );
  }

  /// Carga el perfil del conductor desde Firestore ejecutando una actualización
  /// sin cambios (name y phone vacíos se ignoran si el campo ya existe).
  ///
  /// En la práctica, [DriverProfilePage] inicializa el formulario con los
  /// datos del [AuthBloc]. Este handler solo es invocado cuando se necesita
  /// recargar el perfil desde Firestore después de una edición exitosa.
  Future<void> _onProfileRequested(
    DriverProfileRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());
    // No tenemos un usecase de solo lectura de perfil en este feature;
    // la UI carga el perfil inicial desde AuthBloc.
    // Este evento emite DriverInitial para que la page use los datos del AuthBloc.
    emit(const DriverInitial());
  }

  Future<void> _onProfileUpdateRequested(
    DriverProfileUpdateRequested event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    final result = await _updateDriverProfileUseCase(
      UpdateDriverProfileParams(
        driverId: event.driverId,
        name: event.name,
        phone: event.phone,
      ),
    );

    result.fold(
      (failure) => emit(DriverError(message: failure.message)),
      (driver) {
        emit(
          const DriverActionSuccess(
              message: 'Perfil actualizado correctamente'),
        );
        emit(DriverProfileLoaded(driver: driver));
      },
    );
  }
}
