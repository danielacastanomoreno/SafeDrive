import 'package:equatable/equatable.dart';

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
  const TripActive({required this.trip, required this.elapsed});

  final TripEntity trip;
  final Duration elapsed;

  @override
  List<Object?> get props => [trip, elapsed];
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
