import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/route_point_entity.dart';
import '../repositories/trip_repository.dart';

class GetTripRouteUseCase
    implements UseCase<List<RoutePointEntity>, GetTripRouteParams> {
  const GetTripRouteUseCase(this._repository);
  final TripRepository _repository;

  @override
  Future<Either<Failure, List<RoutePointEntity>>> call(
          GetTripRouteParams params) =>
      _repository.getTripRoute(params.tripId);
}

class GetTripRouteParams extends Equatable {
  const GetTripRouteParams({required this.tripId});
  final String tripId;

  @override
  List<Object?> get props => [tripId];
}
