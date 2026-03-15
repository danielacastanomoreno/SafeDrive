import 'package:equatable/equatable.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

class TripCheckActiveRequested extends TripEvent {
  const TripCheckActiveRequested({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

class TripStartRequested extends TripEvent {
  const TripStartRequested({
    required this.driverId,
    required this.hasCameraPermission,
  });

  final String driverId;
  final bool hasCameraPermission;

  @override
  List<Object?> get props => [driverId, hasCameraPermission];
}

class TripEndRequested extends TripEvent {
  const TripEndRequested({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Dispatched internally every second while a trip is active. Do not use externally.
class TripTick extends TripEvent {
  const TripTick();
}
