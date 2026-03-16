import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class GetActiveTripUseCase
    implements UseCase<TripEntity?, GetActiveTripParams> {
  const GetActiveTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity?>> call(GetActiveTripParams params) =>
      _repository.getActiveTrip(params.driverId);
}

class GetActiveTripParams extends Equatable {
  const GetActiveTripParams({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
