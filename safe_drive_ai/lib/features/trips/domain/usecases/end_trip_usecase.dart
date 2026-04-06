import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class EndTripUseCase implements UseCase<TripEntity, EndTripParams> {
  const EndTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripEntity>> call(EndTripParams params) =>
      _repository.endTrip(
        tripId: params.tripId,
        endedAt: params.endedAt,
      );
}

class EndTripParams extends Equatable {
  const EndTripParams({
    required this.tripId,
    required this.endedAt,
  });

  final String tripId;
  final DateTime endedAt;

  @override
  List<Object?> get props => [tripId, endedAt];
}
