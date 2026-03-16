import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetDriverTripsUseCase
    implements UseCase<List<TripEntity>, GetDriverTripsParams> {
  const GetDriverTripsUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, List<TripEntity>>> call(
      GetDriverTripsParams params) async {
    return await _repository.getDriverTrips(params.driverId);
  }
}

class GetDriverTripsParams extends Equatable {
  const GetDriverTripsParams({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
