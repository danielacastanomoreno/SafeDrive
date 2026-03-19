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
    super.closureRequestedAt,
    super.isClosureApproved,
    super.destinationLat,
    super.destinationLng,
    super.destinationAddress,
    super.isOutOfZone,
    super.scheduledStartTime,
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
        'pending' => TripStatus.pending,
        'pendingApproval' => TripStatus.pendingApproval,
        _ => TripStatus.active,
      },
      closureRequestedAt: map['closureRequestedAt'] != null
          ? (map['closureRequestedAt'] as Timestamp).toDate()
          : null,
      isClosureApproved: map['isClosureApproved'] as bool? ?? false,
      destinationLat: map['destinationLat'] as double?,
      destinationLng: map['destinationLng'] as double?,
      destinationAddress: map['destinationAddress'] as String?,
      isOutOfZone: map['isOutOfZone'] as bool? ?? false,
      scheduledStartTime: map['scheduledStartTime'] != null
          ? (map['scheduledStartTime'] as Timestamp).toDate()
          : null,
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
          TripStatus.pending => 'pending',
          TripStatus.pendingApproval => 'pendingApproval',
          TripStatus.active => 'active',
        },
        if (closureRequestedAt != null)
          'closureRequestedAt': Timestamp.fromDate(closureRequestedAt!),
        'isClosureApproved': isClosureApproved,
        if (destinationLat != null) 'destinationLat': destinationLat,
        if (destinationLng != null) 'destinationLng': destinationLng,
        if (destinationAddress != null) 'destinationAddress': destinationAddress,
        'isOutOfZone': isOutOfZone,
        if (scheduledStartTime != null)
          'scheduledStartTime': Timestamp.fromDate(scheduledStartTime!),
      };
}
