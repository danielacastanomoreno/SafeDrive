import 'package:equatable/equatable.dart';

enum TripStatus { active, completed }

class TripEntity extends Equatable {
  const TripEntity({
    required this.id,
    required this.driverId,
    required this.startTime,
    required this.hasCameraPermission,
    required this.status,
    this.endTime,
  });

  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool hasCameraPermission;
  final TripStatus status;

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  @override
  List<Object?> get props =>
      [id, driverId, startTime, endTime, hasCameraPermission, status];
}
