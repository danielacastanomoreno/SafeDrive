import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/route_point_entity.dart';
import '../entities/trip_entity.dart';

abstract class TripRepository {
  Future<Either<Failure, TripEntity>> startTrip({
    required String driverId,
    required bool hasCameraPermission,
    required DateTime startedAt,
  });
  Future<Either<Failure, TripEntity>> endTrip({
    required String tripId,
    required DateTime endedAt,
  });
  Future<Either<Failure, TripEntity?>> getActiveTrip(String driverId);

  Future<Either<Failure, void>> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, List<RoutePointEntity>>> getTripRoute(String tripId);
  Future<Either<Failure, List<TripEntity>>> getDriverTrips(String driverId);

  // Cierre de viaje
  Future<Either<Failure, void>> requestRemoteClosure(String tripId);
  Stream<Either<Failure, TripEntity>> listenToApprovalStream(String tripId);
  Future<Either<Failure, TripEntity>> endTripWithZoneCheck(String tripId);
}
