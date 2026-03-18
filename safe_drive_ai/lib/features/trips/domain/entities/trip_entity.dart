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

  bool get hasDestination => destinationLat != null && destinationLng != null;

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
      ];
}
