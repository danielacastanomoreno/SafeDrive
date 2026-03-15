import '../models/trip_model.dart';

abstract class TripDatasource {
  Future<TripModel> startTrip({
    required String driverId,
    required bool hasCameraPermission,
  });
  Future<TripModel> endTrip(String tripId);
  Future<TripModel?> getActiveTrip(String driverId);
}
