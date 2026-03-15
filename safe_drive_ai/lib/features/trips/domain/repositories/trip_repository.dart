import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/route_point_entity.dart';
import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<Either<Failure, TripEntity>> startTrip({
    required String driverId,
    required bool hasCameraPermission,
  });
  Future<Either<Failure, TripEntity>> endTrip(String tripId);
  Future<Either<Failure, TripEntity?>> getActiveTrip(String driverId);

  Future<Either<Failure, void>> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<RoutePointEntity>>> getTripRoute(String tripId);
}
