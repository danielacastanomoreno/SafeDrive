import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/route_point_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_datasource.dart';

class TripRepositoryImpl implements TripRepository {
  const TripRepositoryImpl(this._datasource);

  final TripDatasource _datasource;

  @override
  Future<Either<Failure, TripEntity>> startTrip({
    required String driverId,
    required bool hasCameraPermission,
  }) async {
    try {
      final trip = await _datasource.startTrip(
        driverId: driverId,
        hasCameraPermission: hasCameraPermission,
      );
      return Right(trip);
    } on TripAlreadyActiveException {
      return const Left(TripAlreadyActiveFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> endTrip(String tripId) async {
    try {
      final trip = await _datasource.endTrip(tripId);
      return Right(trip);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity?>> getActiveTrip(String driverId) async {
    try {
      final trip = await _datasource.getActiveTrip(driverId);
      return Right(trip);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      await _datasource.saveRoutePoint(tripId: tripId, lat: lat, lng: lng);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoutePointEntity>>> getTripRoute(
      String tripId) async {
    try {
      final points = await _datasource.getTripRoute(tripId);
      return Right(points);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> getDriverTrips(
      String driverId) async {
    try {
      final trips = await _datasource.getDriverTrips(driverId);
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // --- Cierre de viaje ---

  @override
  Future<Either<Failure, void>> requestRemoteClosure(String tripId) async {
    try {
      await _datasource.requestRemoteClosure(tripId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, TripEntity>> listenToApprovalStream(
      String tripId) async* {
    try {
      yield* _datasource.listenToApprovalStream(tripId).map((tripModel) {
        return Right<Failure, TripEntity>(tripModel);
      });
    } on ServerException catch (e) {
      yield Left(ServerFailure(message: e.message));
    } catch (e) {
      yield Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> endTripWithZoneCheck(String tripId) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Left(PermissionDeniedFailure());
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final trip = await _datasource.endTripWithZoneCheck(
        tripId: tripId,
        currentLat: position.latitude,
        currentLng: position.longitude,
      );

      return Right(trip);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
