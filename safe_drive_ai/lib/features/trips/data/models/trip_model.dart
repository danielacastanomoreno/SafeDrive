import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/trip_entity.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.driverId,
    required super.startTime,
    required super.hasCameraPermission,
    required super.status,
    super.endTime,
    super.endTripPin,
    super.closureRequestedAt,
    super.isClosureApproved,
  });

  factory TripModel.fromMap(String id, Map<String, dynamic> map) {
    return TripModel(
      id: id,
      driverId: map['driverId'] as String,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      hasCameraPermission: map['hasCameraPermission'] as bool? ?? false,
      status: switch (map['status'] as String? ?? 'active') {
        'completed' => TripStatus.completed,
        'onBreak' => TripStatus.onBreak,
        _ => TripStatus.active,
      },
      endTripPin: map['endTripPin'] as String?,
      closureRequestedAt: map['closureRequestedAt'] != null
          ? (map['closureRequestedAt'] as Timestamp).toDate()
          : null,
      isClosureApproved: map['isClosureApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'hasCameraPermission': hasCameraPermission,
        'status': switch (status) {
          TripStatus.completed => 'completed',
          TripStatus.onBreak => 'onBreak',
          TripStatus.active => 'active',
        },
        if (endTripPin != null) 'endTripPin': endTripPin,
        if (closureRequestedAt != null)
          'closureRequestedAt': Timestamp.fromDate(closureRequestedAt!),
        'isClosureApproved': isClosureApproved,
      };
}
