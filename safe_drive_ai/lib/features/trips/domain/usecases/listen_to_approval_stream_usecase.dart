import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/trip_entity.dart';
import '../repositories/trip_repository.dart';

class ListenToApprovalStreamUseCase {
  final TripRepository repository;

  ListenToApprovalStreamUseCase(this.repository);

  Stream<Either<Failure, TripEntity>> call(String tripId) {
    return repository.listenToApprovalStream(tripId);
  }
}
