import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_invitation_usecase.dart';
import '../../domain/usecases/get_company_drivers_usecase.dart';
import '../../domain/usecases/get_company_invitations_usecase.dart';
import '../../domain/usecases/register_driver_by_company_usecase.dart';
import '../../domain/usecases/send_invitation_usecase.dart';
import '../../domain/usecases/unlink_driver_usecase.dart';
import '../../domain/usecases/update_company_profile_usecase.dart';
import '../../domain/usecases/get_pending_trips_usecase.dart';
import '../../domain/usecases/approve_trip_closure_usecase.dart';
import '../../domain/usecases/reject_trip_closure_usecase.dart';
import 'company_event.dart';
import 'company_state.dart';

/// BLoC del feature de empresa en Safe Drive AI.
///
/// Solo conoce UseCases del dominio. No importa repositorios ni Firebase.
class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc({
    required GetCompanyDriversUseCase getCompanyDriversUseCase,
    required UnlinkDriverUseCase unlinkDriverUseCase,
    required SendInvitationUseCase sendInvitationUseCase,
    required GetCompanyInvitationsUseCase getCompanyInvitationsUseCase,
    required CancelInvitationUseCase cancelInvitationUseCase,
    required UpdateCompanyProfileUseCase updateCompanyProfileUseCase,
    required RegisterDriverByCompanyUseCase registerDriverByCompanyUseCase,
    required GetPendingTripsUseCase getPendingTripsUseCase,
    required ApproveTripClosureUseCase approveTripClosureUseCase,
    required RejectTripClosureUseCase rejectTripClosureUseCase,
  })  : _getCompanyDriversUseCase = getCompanyDriversUseCase,
        _unlinkDriverUseCase = unlinkDriverUseCase,
        _sendInvitationUseCase = sendInvitationUseCase,
        _getCompanyInvitationsUseCase = getCompanyInvitationsUseCase,
        _cancelInvitationUseCase = cancelInvitationUseCase,
        _updateCompanyProfileUseCase = updateCompanyProfileUseCase,
        _registerDriverByCompanyUseCase = registerDriverByCompanyUseCase,
        _getPendingTripsUseCase = getPendingTripsUseCase,
        _approveTripClosureUseCase = approveTripClosureUseCase,
        _rejectTripClosureUseCase = rejectTripClosureUseCase,
        super(const CompanyInitial()) {
    on<CompanyDriversRequested>(_onDriversRequested);
    on<CompanyDriverUnlinkRequested>(_onDriverUnlinkRequested);
    on<CompanyInvitationSendRequested>(_onInvitationSendRequested);
    on<CompanyInvitationsRequested>(_onInvitationsRequested);
    on<CompanyInvitationCancelRequested>(_onInvitationCancelRequested);
    on<CompanyProfileRequested>(_onProfileRequested);
    on<CompanyProfileUpdateRequested>(_onProfileUpdateRequested);
    on<CompanyDriverRegisterRequested>(_onDriverRegisterRequested);
    on<CompanyPendingTripsRequested>(_onPendingTripsRequested);
    on<CompanyTripClosureApproved>(_onTripClosureApproved);
    on<CompanyTripClosureRejected>(_onTripClosureRejected);
  }

  final GetCompanyDriversUseCase _getCompanyDriversUseCase;
  final UnlinkDriverUseCase _unlinkDriverUseCase;
  final SendInvitationUseCase _sendInvitationUseCase;
  final GetCompanyInvitationsUseCase _getCompanyInvitationsUseCase;
  final CancelInvitationUseCase _cancelInvitationUseCase;
  final UpdateCompanyProfileUseCase _updateCompanyProfileUseCase;
  final RegisterDriverByCompanyUseCase _registerDriverByCompanyUseCase;
  final GetPendingTripsUseCase _getPendingTripsUseCase;
  final ApproveTripClosureUseCase _approveTripClosureUseCase;
  final RejectTripClosureUseCase _rejectTripClosureUseCase;

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _onDriversRequested(
    CompanyDriversRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _getCompanyDriversUseCase(
      GetCompanyDriversParams(companyId: event.companyId),
    );

    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
    );
  }

  Future<void> _onDriverUnlinkRequested(
    CompanyDriverUnlinkRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _unlinkDriverUseCase(
      UnlinkDriverParams(linkId: event.linkId),
    );

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message: 'Conductor desvinculado correctamente.',
          ),
        );
        // Recarga la lista de conductores tras desvincular
        final driversResult = await _getCompanyDriversUseCase(
          GetCompanyDriversParams(companyId: event.companyId),
        );
        driversResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
        );
      },
    );
  }

  Future<void> _onInvitationSendRequested(
    CompanyInvitationSendRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _sendInvitationUseCase(
      SendInvitationParams(
        companyId: event.companyId,
        companyName: event.companyName,
        driverCedula: event.driverCedula,
        cargo: event.cargo,
        phone: event.phone,
      ),
    );

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message: 'Invitación enviada correctamente.',
          ),
        );
        // Recarga la lista de invitaciones tras enviar
        final invitationsResult = await _getCompanyInvitationsUseCase(
          GetCompanyInvitationsParams(companyId: event.companyId),
        );
        invitationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (invitations) =>
              emit(CompanyInvitationsLoaded(invitations: invitations)),
        );
      },
    );
  }

  Future<void> _onInvitationsRequested(
    CompanyInvitationsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _getCompanyInvitationsUseCase(
      GetCompanyInvitationsParams(companyId: event.companyId),
    );

    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (invitations) => emit(CompanyInvitationsLoaded(invitations: invitations)),
    );
  }

  Future<void> _onInvitationCancelRequested(
    CompanyInvitationCancelRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _cancelInvitationUseCase(
      CancelInvitationParams(invitationId: event.invitationId),
    );

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message: 'Invitación cancelada correctamente.',
          ),
        );
        // Recarga la lista de invitaciones tras cancelar
        final invitationsResult = await _getCompanyInvitationsUseCase(
          GetCompanyInvitationsParams(companyId: event.companyId),
        );
        invitationsResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (invitations) =>
              emit(CompanyInvitationsLoaded(invitations: invitations)),
        );
      },
    );
  }

  Future<void> _onProfileRequested(
    CompanyProfileRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    // El perfil se provee desde el AuthBloc al navegar; aquí se usa para
    // confirmar que el estado local es el más reciente.
    // Como no hay un usecase de "get profile" puro (ya existe en auth),
    // emitimos error si no tenemos datos — la página provee la entidad inicial.
    emit(const CompanyError(
        message: 'Use el perfil provisto en la navegación.'));
  }

  Future<void> _onProfileUpdateRequested(
    CompanyProfileUpdateRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _updateCompanyProfileUseCase(
      UpdateCompanyProfileParams(
        companyId: event.companyId,
        name: event.name,
        representativeName: event.representativeName,
      ),
    );

    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (company) => emit(CompanyProfileLoaded(company: company)),
    );
  }

  Future<void> _onDriverRegisterRequested(
    CompanyDriverRegisterRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _registerDriverByCompanyUseCase(
      RegisterDriverByCompanyParams(
        companyId: event.companyId,
        name: event.name,
        cedula: event.cedula,
        email: event.email,
        phone: event.phone,
        cargo: event.cargo,
      ),
    );

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message:
                'Conductor registrado exitosamente. Se enviaron las credenciales a su correo.',
          ),
        );
        // Recarga la lista de conductores para que aparezca el nuevo registro
        final driversResult = await _getCompanyDriversUseCase(
          GetCompanyDriversParams(companyId: event.companyId),
        );
        driversResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (drivers) => emit(CompanyDriversLoaded(drivers: drivers)),
        );
      },
    );
  }

  Future<void> _onPendingTripsRequested(
    CompanyPendingTripsRequested event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _getPendingTripsUseCase(event.companyId);

    result.fold(
      (failure) => emit(CompanyError(message: failure.message)),
      (pendingTrips) => emit(CompanyPendingTripsLoaded(pendingTrips: pendingTrips)),
    );
  }

  Future<void> _onTripClosureApproved(
    CompanyTripClosureApproved event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _approveTripClosureUseCase(event.tripId);

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message: 'Cierre de viaje aprobado correctamente.',
          ),
        );
        // Recargar la lista de viajes pendientes
        final pendingResult = await _getPendingTripsUseCase(event.companyId);
        pendingResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (pendingTrips) => emit(CompanyPendingTripsLoaded(pendingTrips: pendingTrips)),
        );
      },
    );
  }

  Future<void> _onTripClosureRejected(
    CompanyTripClosureRejected event,
    Emitter<CompanyState> emit,
  ) async {
    emit(const CompanyLoading());

    final result = await _rejectTripClosureUseCase(event.tripId);

    await result.fold(
      (failure) async => emit(CompanyError(message: failure.message)),
      (_) async {
        emit(
          const CompanyActionSuccess(
            message: 'Cierre de viaje rechazado.',
          ),
        );
        final pendingResult = await _getPendingTripsUseCase(event.companyId);
        pendingResult.fold(
          (failure) => emit(CompanyError(message: failure.message)),
          (pendingTrips) => emit(CompanyPendingTripsLoaded(pendingTrips: pendingTrips)),
        );
      },
    );
  }
}

