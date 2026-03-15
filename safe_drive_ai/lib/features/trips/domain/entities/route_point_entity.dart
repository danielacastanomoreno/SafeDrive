import 'package:equatable/equatable.dart';

class RoutePointEntity extends Equatable {
  const RoutePointEntity({
    required this.lat,
    required this.lng,
    required this.recordedAt,
  });

  final double lat;
  final double lng;
  final DateTime recordedAt;

  @override
  List<Object?> get props => [lat, lng, recordedAt];
}
