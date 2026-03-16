import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

class StopMonitoringAndFinalizeUseCase implements UseCase<void, String> {
  final TripRepository repository;

  StopMonitoringAndFinalizeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.stopMonitoringAndFinalize(tripId);
  }
}
