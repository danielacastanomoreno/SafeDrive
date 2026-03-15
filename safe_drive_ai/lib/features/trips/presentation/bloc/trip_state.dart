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

class TripActive extends TripState {
  const TripActive({
    required this.trip,
    required this.elapsed,
    this.route = const [],
  });

  final TripEntity trip;
  final Duration elapsed;

  /// GPS points accumulated since the trip started (or since app resumed).
  final List<LatLng> route;

  TripActive copyWith({
    TripEntity? trip,
    Duration? elapsed,
    List<LatLng>? route,
  }) {
    return TripActive(
      trip: trip ?? this.trip,
      elapsed: elapsed ?? this.elapsed,
      route: route ?? this.route,
    );
  }

  @override
  List<Object?> get props => [trip, elapsed, route];
}

class TripEnded extends TripState {
  const TripEnded({required this.trip});
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
