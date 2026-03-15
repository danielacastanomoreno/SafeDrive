import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/route_point_entity.dart';

class RoutePointModel extends RoutePointEntity {
  const RoutePointModel({
    required super.lat,
    required super.lng,
    required super.recordedAt,
  });

  factory RoutePointModel.fromMap(Map<String, dynamic> map) {
    return RoutePointModel(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'recordedAt': Timestamp.fromDate(recordedAt),
      };
}
