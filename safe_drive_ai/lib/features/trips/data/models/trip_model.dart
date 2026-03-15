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
      status: (map['status'] as String?) == 'completed'
          ? TripStatus.completed
          : TripStatus.active,
    );
  }

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'hasCameraPermission': hasCameraPermission,
        'status': status == TripStatus.completed ? 'completed' : 'active',
      };
}
