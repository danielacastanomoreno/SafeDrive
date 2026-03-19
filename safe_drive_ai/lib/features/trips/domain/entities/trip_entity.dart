import 'package:equatable/equatable.dart';

enum TripStatus { active, pending, pendingApproval, onBreak, completed }

class TripEntity extends Equatable {
  const TripEntity({
    required this.id,
    required this.driverId,
    required this.startTime,
    required this.hasCameraPermission,
    required this.status,
    this.endTime,
    this.closureRequestedAt,
    this.isClosureApproved = false,
    this.destinationLat,
    this.destinationLng,
    this.destinationAddress,
    this.isOutOfZone = false,
    this.scheduledStartTime,
  });

  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool hasCameraPermission;
  final TripStatus status;
  final DateTime? closureRequestedAt;
  final bool isClosureApproved;
  final double? destinationLat;
  final double? destinationLng;
  final String? destinationAddress;
  final bool isOutOfZone;
  final DateTime? scheduledStartTime;

  bool get hasDestination => destinationLat != null && destinationLng != null;

  bool get isScheduled => scheduledStartTime != null;

  bool get canStartNow {
    if (scheduledStartTime == null) return true;
    return DateTime.now().isAfter(scheduledStartTime!) || 
           DateTime.now().isAtSameMomentAs(scheduledStartTime!);
  }

  bool get isPending => status == TripStatus.pending;
  bool get isActive => status == TripStatus.active;

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  TripEntity copyWith({
    String? id,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    bool? hasCameraPermission,
    TripStatus? status,
    DateTime? closureRequestedAt,
    bool? isClosureApproved,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
    bool? isOutOfZone,
    DateTime? scheduledStartTime,
  }) {
    return TripEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      status: status ?? this.status,
      closureRequestedAt: closureRequestedAt ?? this.closureRequestedAt,
      isClosureApproved: isClosureApproved ?? this.isClosureApproved,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      isOutOfZone: isOutOfZone ?? this.isOutOfZone,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        startTime,
        endTime,
        hasCameraPermission,
        status,
        closureRequestedAt,
        isClosureApproved,
        destinationLat,
        destinationLng,
        destinationAddress,
        isOutOfZone,
        scheduledStartTime,
      ];
}
