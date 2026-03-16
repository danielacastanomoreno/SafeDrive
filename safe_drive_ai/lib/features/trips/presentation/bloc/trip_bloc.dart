import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/trip_entity.dart';
import '../../domain/usecases/end_trip_usecase.dart';
import '../../domain/usecases/get_active_trip_usecase.dart';
import '../../domain/usecases/save_route_point_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import '../../domain/usecases/request_remote_closure_usecase.dart';
import '../../domain/usecases/listen_to_approval_stream_usecase.dart';
import '../../domain/usecases/verify_manual_pin_usecase.dart';
import '../../domain/usecases/stop_monitoring_and_finalize_usecase.dart';
import '../../domain/usecases/generate_and_store_pin_usecase.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc({
    required StartTripUseCase startTripUseCase,
    required EndTripUseCase endTripUseCase,
    required GetActiveTripUseCase getActiveTripUseCase,
    required SaveRoutePointUseCase saveRoutePointUseCase,
    required RequestRemoteClosureUseCase requestRemoteClosureUseCase,
    required ListenToApprovalStreamUseCase listenToApprovalStreamUseCase,
    required VerifyManualPinUseCase verifyManualPinUseCase,
    required StopMonitoringAndFinalizeUseCase stopMonitoringAndFinalizeUseCase,
    required GenerateAndStorePinUseCase generateAndStorePinUseCase,
  })  : _startTripUseCase = startTripUseCase,
        _endTripUseCase = endTripUseCase,
        _getActiveTripUseCase = getActiveTripUseCase,
        _saveRoutePointUseCase = saveRoutePointUseCase,
        _requestRemoteClosureUseCase = requestRemoteClosureUseCase,
        _listenToApprovalStreamUseCase = listenToApprovalStreamUseCase,
        _verifyManualPinUseCase = verifyManualPinUseCase,
        _stopMonitoringAndFinalizeUseCase = stopMonitoringAndFinalizeUseCase,
        _generateAndStorePinUseCase = generateAndStorePinUseCase,
        super(const TripInitial()) {
    on<TripCheckActiveRequested>(_onCheckActive);
    on<TripStartRequested>(_onStartTrip);
    on<TripEndRequested>(_onEndTrip);
    on<TripTick>(_onTick);
    on<TripLocationUpdated>(_onLocationUpdated);
    on<RequestRemoteClosureEvent>(_onRequestRemoteClosure);
    on<ApprovalStreamUpdatedEvent>(_onApprovalStreamUpdated);
    on<VerifyManualPinEvent>(_onVerifyManualPin);
  }

  final StartTripUseCase _startTripUseCase;
  final EndTripUseCase _endTripUseCase;
  final GetActiveTripUseCase _getActiveTripUseCase;
  final SaveRoutePointUseCase _saveRoutePointUseCase;

  final RequestRemoteClosureUseCase _requestRemoteClosureUseCase;
  final ListenToApprovalStreamUseCase _listenToApprovalStreamUseCase;
  final VerifyManualPinUseCase _verifyManualPinUseCase;
  final StopMonitoringAndFinalizeUseCase _stopMonitoringAndFinalizeUseCase;
  final GenerateAndStorePinUseCase _generateAndStorePinUseCase;

  Timer? _timer;
  Timer? _inactivityTimer;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription? _approvalSubscription;

  // Auto-end trip after 20 min with no GPS movement
  static const _inactivityTimeout = Duration(minutes: 20);

  // ── Timer ────────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TripTick());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Inactivity timer ──────────────────────────────────────────────────────────

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (state is TripActive) {
        add(TripEndRequested(tripId: (state as TripActive).trip.id));
      }
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────

  Future<void> _startLocationTracking() async {
    await _positionSub?.cancel();

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // trip continues without GPS tracking
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // meters — update every 20m moved
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      add(TripLocationUpdated(lat: position.latitude, lng: position.longitude));
    });
  }

  void _stopLocationTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    _stopLocationTracking();
    _stopInactivityTimer();
    _approvalSubscription?.cancel();
    return super.close();
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onCheckActive(
    TripCheckActiveRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());
    final result = await _getActiveTripUseCase(
      GetActiveTripParams(driverId: event.driverId),
    );
    result.fold(
      (_) => emit(const TripIdle()),
      (trip) {
        if (trip == null) {
          emit(const TripIdle());
        } else {
          emit(TripActive(trip: trip, elapsed: trip.elapsed));
          _startTimer();
          _startLocationTracking();
          _resetInactivityTimer();
        }
      },
    );
  }

  Future<void> _onStartTrip(
    TripStartRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());
    final result = await _startTripUseCase(
      StartTripParams(
        driverId: event.driverId,
        hasCameraPermission: event.hasCameraPermission,
      ),
    );
    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) async {
        // Generate and store PIN for contingency closure
        final pinResult = await _generateAndStorePinUseCase(trip.id);
        
        pinResult.fold(
          (failure) => emit(TripError(message: 'Error al generar PIN: ${failure.message}')),
          (_) {
            emit(TripActive(
                trip: trip, elapsed: Duration.zero, isNewlyStarted: true));
            _startTimer();
            _startLocationTracking();
            _resetInactivityTimer();
          },
        );
      },
    );
  }

  Future<void> _onEndTrip(
    TripEndRequested event,
    Emitter<TripState> emit,
  ) async {
    emit(TripClosureLoading());
    await _finalizeAndEmit(event.tripId, emit);
  }

  void _onTick(TripTick event, Emitter<TripState> emit) {
    if (state is TripActive) {
      final current = state as TripActive;
      emit(current.copyWith(elapsed: current.trip.elapsed));
    }
  }

  Future<void> _onLocationUpdated(
    TripLocationUpdated event,
    Emitter<TripState> emit,
  ) async {
    if (state is! TripActive) return;
    final current = state as TripActive;

    // Save to Firestore (fire-and-forget — errors are silently ignored)
    _saveRoutePointUseCase(
      SaveRoutePointParams(
        tripId: current.trip.id,
        lat: event.lat,
        lng: event.lng,
      ),
    );

    // Reset inactivity timer — driver is still moving
    _resetInactivityTimer();

    // Update local route for map display
    final updatedRoute = List<LatLng>.from(current.route)
      ..add(LatLng(event.lat, event.lng));

    emit(current.copyWith(route: updatedRoute));
  }

  // --- Cierre de viaje ---

  Future<void> _onRequestRemoteClosure(
    RequestRemoteClosureEvent event,
    Emitter<TripState> emit,
  ) async {
    if (state is! TripActive) return;
    
    emit(TripClosureLoading());

    final result = await _requestRemoteClosureUseCase(event.tripId);

    if (state is! TripActive) return;
    final currentState = state as TripActive;

    result.fold(
      (failure) => emit(TripClosureError(message: failure.message)),
      (_) {
        // En vez de emitir TripClosureRequested y bloquear, 
        // actualizamos la entidad del viaje en el estado activo.
        final updatedTrip = TripEntity(
          id: currentState.trip.id,
          driverId: currentState.trip.driverId,
          startTime: currentState.trip.startTime,
          hasCameraPermission: currentState.trip.hasCameraPermission,
          status: currentState.trip.status,
          endTime: currentState.trip.endTime,
          endTripPin: currentState.trip.endTripPin,
          closureRequestedAt: DateTime.now(), // Marcamos la hora de solicitud
          isClosureApproved: false,
        );

        emit(currentState.copyWith(trip: updatedTrip));
        
        _approvalSubscription?.cancel();
        _approvalSubscription =
            _listenToApprovalStreamUseCase(event.tripId).listen(
          (result) {
            result.fold(
                (failure) =>
                    add(const ApprovalStreamUpdatedEvent(isApproved: false)),
                (tripFromStream) {
              if (tripFromStream.isClosureApproved) {
                add(ApprovalStreamUpdatedEvent(
                    isApproved: true, tripId: tripFromStream.id));
              }
            });
          },
        );
      },
    );
  }

  Future<void> _onApprovalStreamUpdated(
    ApprovalStreamUpdatedEvent event,
    Emitter<TripState> emit,
  ) async {
    if (event.isApproved && event.tripId != null) {
      if (state is TripActive) {
        emit(TripClosureLoading());
        await _finalizeAndEmit(event.tripId!, emit);
      }
    }
  }

  Future<void> _onVerifyManualPin(
    VerifyManualPinEvent event,
    Emitter<TripState> emit,
  ) async {
    final prevState = state;
    emit(TripClosureLoading());

    final result = await _verifyManualPinUseCase(event.pin);

    await result.fold(
      (failure) async {
        if (prevState is TripActive) emit(prevState);
        emit(TripClosureError(message: failure.message));
      },
      (isValid) async {
        if (isValid) {
          await _finalizeAndEmit(event.tripId, emit);
        } else {
          if (prevState is TripActive) emit(prevState);
          emit(const TripClosureError(message: 'PIN incorrecto'));
        }
      },
    );
  }

  Future<void> _finalizeAndEmit(String tripId, Emitter<TripState> emit) async {
    _approvalSubscription?.cancel();
    _stopTimer();
    _stopLocationTracking();
    _stopInactivityTimer();

    final result = await _stopMonitoringAndFinalizeUseCase(tripId);

    result.fold(
      (failure) => emit(TripClosureError(message: failure.message)),
      (_) {
        // Emit TripEnded so navigation works correctly
        // Create a minimal trip entity for navigation
        final trip = TripEntity(
          id: tripId,
          driverId: '',
          startTime: DateTime.now(),
          hasCameraPermission: false,
          status: TripStatus.completed,
          endTime: DateTime.now(),
        );
        emit(TripEnded(trip: trip));
      },
    );
  }
}
