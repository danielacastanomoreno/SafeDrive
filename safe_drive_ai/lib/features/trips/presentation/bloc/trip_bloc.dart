import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/usecases/end_trip_usecase.dart';
import '../../domain/usecases/get_active_trip_usecase.dart';
import '../../domain/usecases/save_route_point_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc({
    required StartTripUseCase startTripUseCase,
    required EndTripUseCase endTripUseCase,
    required GetActiveTripUseCase getActiveTripUseCase,
    required SaveRoutePointUseCase saveRoutePointUseCase,
  })  : _startTripUseCase = startTripUseCase,
        _endTripUseCase = endTripUseCase,
        _getActiveTripUseCase = getActiveTripUseCase,
        _saveRoutePointUseCase = saveRoutePointUseCase,
        super(const TripInitial()) {
    on<TripCheckActiveRequested>(_onCheckActive);
    on<TripStartRequested>(_onStartTrip);
    on<TripEndRequested>(_onEndTrip);
    on<TripTick>(_onTick);
    on<TripLocationUpdated>(_onLocationUpdated);
  }

  final StartTripUseCase _startTripUseCase;
  final EndTripUseCase _endTripUseCase;
  final GetActiveTripUseCase _getActiveTripUseCase;
  final SaveRoutePointUseCase _saveRoutePointUseCase;

  Timer? _timer;
  Timer? _inactivityTimer;
  StreamSubscription<Position>? _positionSub;

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
    _stopTimer();
    _stopLocationTracking();
    _stopInactivityTimer();
    emit(const TripLoading());
    final result = await _endTripUseCase(EndTripParams(tripId: event.tripId));
    result.fold(
      (failure) => emit(TripError(message: failure.message)),
      (trip) => emit(TripEnded(trip: trip)),
    );
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
}
