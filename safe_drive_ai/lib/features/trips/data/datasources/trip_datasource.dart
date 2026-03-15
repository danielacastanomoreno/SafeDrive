import '../models/route_point_model.dart';
import '../models/trip_model.dart';

abstract class TripDatasource {
  Future<TripModel> startTrip({
    required String driverId,
    required bool hasCameraPermission,
  });
  Future<TripModel> endTrip(String tripId);
  Future<TripModel?> getActiveTrip(String driverId);

  Future<void> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  });

  Future<List<RoutePointModel>> getTripRoute(String tripId);
}
