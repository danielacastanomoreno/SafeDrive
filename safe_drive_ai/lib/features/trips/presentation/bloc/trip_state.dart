import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/trip_entity.dart';

abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripLoading extends TripState {
  const TripLoading();
}

class TripIdle extends TripState {
  const TripIdle();
}

class TripPending extends TripState {
  const TripPending({required this.trip});

  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

class TripActive extends TripState {
  const TripActive({
    required this.trip,
    required this.elapsed,
    this.route = const [],
    this.isNewlyStarted = false,
  });

  final TripEntity trip;
  final Duration elapsed;

  /// GPS points accumulated since the trip started (or since app resumed).
  final List<LatLng> route;

  /// `true` only on the very first emission after [TripStartRequested] succeeds.
  /// Used by [DriverHomePage] to auto-open the map exactly once.
  final bool isNewlyStarted;

  TripActive copyWith({
    TripEntity? trip,
    Duration? elapsed,
    List<LatLng>? route,
  }) {
    return TripActive(
      trip: trip ?? this.trip,
      elapsed: elapsed ?? this.elapsed,
      route: route ?? this.route,
      isNewlyStarted: false, // never true after the initial emission
    );
  }

  @override
  List<Object?> get props => [trip, elapsed, route, isNewlyStarted];
}

class TripEnded extends TripState {
  const TripEnded({required this.trip});
  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

class TripPendingApproval extends TripState {
  const TripPendingApproval({required this.trip});
  final TripEntity trip;

  @override
  List<Object?> get props => [trip];
}

class TripError extends TripState {
  const TripError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Cierre de viaje ---

class TripClosureLoading extends TripState {}

class TripClosureRequested extends TripState {}

class TripFinalizedSuccess extends TripState {
  const TripFinalizedSuccess();
}

class TripClosureError extends TripState {
  final String message;
  const TripClosureError({required this.message});
  @override
  List<Object?> get props => [message];
}
