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

/// Internal — dispatched every second by the Timer.
class TripTick extends TripEvent {
  const TripTick();
}

/// Internal — dispatched when GPS emits a new position.
class TripLocationUpdated extends TripEvent {
  const TripLocationUpdated({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}

// --- Cierre de viaje ---

class RequestRemoteClosureEvent extends TripEvent {
  final String tripId;
  const RequestRemoteClosureEvent({required this.tripId});
  @override
  List<Object?> get props => [tripId];
}

class ApprovalStreamUpdatedEvent extends TripEvent {
  final bool isApproved;
  final String? tripId;
  const ApprovalStreamUpdatedEvent({required this.isApproved, this.tripId});
  @override
  List<Object?> get props => [isApproved, tripId];
}
