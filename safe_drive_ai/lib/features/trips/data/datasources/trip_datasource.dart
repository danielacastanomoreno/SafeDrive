import '../models/route_point_model.dart';
import '../models/trip_model.dart';

abstract class TripDatasource {
  Future<TripModel> startTrip({
    required String driverId,
    required bool hasCameraPermission,
    required DateTime startedAt,
  });
  Future<TripModel> endTrip({
    required String tripId,
    required DateTime endedAt,
  });
  Future<TripModel?> getActiveTrip(String driverId);

  Future<void> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<List<RoutePointModel>> getTripRoute(String tripId);
  Future<List<TripModel>> getDriverTrips(String driverId);

  // Cierre de viaje
  Future<void> requestRemoteClosure(String tripId);
  Stream<TripModel> listenToApprovalStream(String tripId);
  Stream<List<TripModel>> listenToPendingTrips(String driverId);

  Future<TripModel> endTripWithZoneCheck({
    required String tripId,
    required double currentLat,
    required double currentLng,
  });
}
