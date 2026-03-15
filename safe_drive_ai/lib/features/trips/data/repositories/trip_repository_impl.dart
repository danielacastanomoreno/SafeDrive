import 'package:dartz/dartz.dart';

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
}
