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
import '../../domain/usecases/end_trip_with_zone_check_usecase.dart';
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
    required EndTripWithZoneCheckUseCase endTripWithZoneCheckUseCase,
  })  : _startTripUseCase = startTripUseCase,
        _endTripUseCase = endTripUseCase,
        _getActiveTripUseCase = getActiveTripUseCase,
        _saveRoutePointUseCase = saveRoutePointUseCase,
        _requestRemoteClosureUseCase = requestRemoteClosureUseCase,
        _listenToApprovalStreamUseCase = listenToApprovalStreamUseCase,
        _endTripWithZoneCheckUseCase = endTripWithZoneCheckUseCase,
        super(const TripInitial()) {
    on<TripCheckActiveRequested>(_onCheckActive);
    on<TripStartRequested>(_onStartTrip);
    on<TripEndRequested>(_onEndTrip);
    on<TripTick>(_onTick);
    on<TripLocationUpdated>(_onLocationUpdated);
    on<RequestRemoteClosureEvent>(_onRequestRemoteClosure);
    on<ApprovalStreamUpdatedEvent>(_onApprovalStreamUpdated);
  }

  final StartTripUseCase _startTripUseCase;
  final EndTripUseCase _endTripUseCase;
  final GetActiveTripUseCase _getActiveTripUseCase;
  final SaveRoutePointUseCase _saveRoutePointUseCase;

  final RequestRemoteClosureUseCase _requestRemoteClosureUseCase;
  final ListenToApprovalStreamUseCase _listenToApprovalStreamUseCase;
  final EndTripWithZoneCheckUseCase _endTripWithZoneCheckUseCase;

  Timer? _timer;
  Timer? _inactivityTimer;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription? _approvalSubscription;

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

  // ── Inactivity timer ───────────────────────────────────────────────────────
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      add(TripEndRequested(tripId: (state as TripActive).trip.id));
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  // ── Location ────────────────────────────────────────────────────────────────
  Future<void> _startLocationTracking() async {
    _positionSub?.cancel();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        add(TripLocationUpdated(lat: pos.latitude, lng: pos.longitude));
      });
    } catch (_) {}
  }

  void _stopLocationTracking() {
    _positionSub?.cancel();
    _positionSub = null;
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
        } else if (trip.status == TripStatus.pending) {
          emit(TripPending(trip: trip));
        } else if (trip.status == TripStatus.pendingApproval) {
          emit(TripPendingApproval(trip: trip));
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
      (trip) {
        emit(TripActive(trip: trip, elapsed: Duration.zero, isNewlyStarted: true));
        _startTimer();
        _startLocationTracking();
        _resetInactivityTimer();
      },
    );
  }

  Future<void> _onEndTrip(
    TripEndRequested event,
    Emitter<TripState> emit,
  ) async {
    if (state is TripActive) {
      await _finalizeAndEmit(event.tripId, emit);
    } else if (state is TripPendingApproval) {
      emit(const TripIdle());
    }
  }

  void _onTick(TripTick event, Emitter<TripState> emit) {
    if (state is TripActive) {
      final current = state as TripActive;
      if (current.trip.closureRequestedAt != null) {
        return;
      }
      emit(current.copyWith(elapsed: current.trip.elapsed));
    }
  }

  void _onLocationUpdated(
    TripLocationUpdated event,
    Emitter<TripState> emit,
  ) {
    if (state is TripActive) {
      final current = state as TripActive;
      final newRoute = [...?current.route, LatLng(event.lat, event.lng)];
      emit(current.copyWith(route: newRoute));
      _resetInactivityTimer();
    }
  }

  Future<void> _onRequestRemoteClosure(
    RequestRemoteClosureEvent event,
    Emitter<TripState> emit,
  ) async {
    if (state is! TripActive) return;

    final currentState = state as TripActive;

    final result = await _requestRemoteClosureUseCase(event.tripId);
    result.fold(
      (failure) => emit(TripClosureError(message: failure.message)),
      (_) {
        final updatedTrip = currentState.trip.copyWith(
          closureRequestedAt: DateTime.now(),
        );
        emit(currentState.copyWith(trip: updatedTrip));

        _approvalSubscription?.cancel();
        _approvalSubscription = _listenToApprovalStreamUseCase(event.tripId).listen(
          (result) {
            result.fold(
              (failure) {},
              (trip) {
                if (trip.isClosureApproved) {
                  add(ApprovalStreamUpdatedEvent(isApproved: true, tripId: event.tripId));
                }
              },
            );
          },
        );
      },
    );
  }

  void _onApprovalStreamUpdated(
    ApprovalStreamUpdatedEvent event,
    Emitter<TripState> emit,
  ) async {
    if (event.isApproved) {
      await _finalizeAndEmit(event.tripId!, emit);
    }
  }

  Future<void> _finalizeAndEmit(String tripId, Emitter<TripState> emit) async {
    _approvalSubscription?.cancel();
    _stopTimer();
    _stopLocationTracking();
    _stopInactivityTimer();

    final result = await _endTripWithZoneCheckUseCase(tripId);

    result.fold(
      (failure) {
        if (failure.message.contains('Permiso') || failure.message.contains('ubicación')) {
          emit(TripClosureError(message: 'Se requiere permiso de ubicación para finalizar el viaje.'));
        } else {
          emit(TripClosureError(message: failure.message));
        }
      },
      (trip) {
        if (trip.status == TripStatus.pendingApproval) {
          emit(TripPendingApproval(trip: trip));
        } else {
          emit(TripEnded(trip: trip));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _inactivityTimer?.cancel();
    _positionSub?.cancel();
    _approvalSubscription?.cancel();
    return super.close();
  }
}
