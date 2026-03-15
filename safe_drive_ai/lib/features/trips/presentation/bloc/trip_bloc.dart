import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/end_trip_usecase.dart';
import '../../domain/usecases/get_active_trip_usecase.dart';
import '../../domain/usecases/start_trip_usecase.dart';
import 'trip_event.dart';
import 'trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc({
    required StartTripUseCase startTripUseCase,
    required EndTripUseCase endTripUseCase,
    required GetActiveTripUseCase getActiveTripUseCase,
  })  : _startTripUseCase = startTripUseCase,
        _endTripUseCase = endTripUseCase,
        _getActiveTripUseCase = getActiveTripUseCase,
        super(const TripInitial()) {
    on<TripCheckActiveRequested>(_onCheckActive);
    on<TripStartRequested>(_onStartTrip);
    on<TripEndRequested>(_onEndTrip);
    on<TripTick>(_onTick);
  }

  final StartTripUseCase _startTripUseCase;
  final EndTripUseCase _endTripUseCase;
  final GetActiveTripUseCase _getActiveTripUseCase;

  Timer? _timer;

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

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }

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
        emit(TripActive(trip: trip, elapsed: Duration.zero));
        _startTimer();
      },
    );
  }

  Future<void> _onEndTrip(
    TripEndRequested event,
    Emitter<TripState> emit,
  ) async {
    _stopTimer();
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
      emit(TripActive(trip: current.trip, elapsed: current.trip.elapsed));
    }
  }
}
