import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class EndTripWithZoneCheckUseCase implements UseCase<TripEntity, String> {
  final TripRepository repository;

  EndTripWithZoneCheckUseCase(this.repository);

  @override
  Future<Either<Failure, TripEntity>> call(String tripId) {
    return repository.endTripWithZoneCheck(tripId);
  }
}
