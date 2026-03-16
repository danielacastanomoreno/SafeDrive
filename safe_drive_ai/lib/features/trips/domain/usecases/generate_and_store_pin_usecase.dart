import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

class GenerateAndStorePinUseCase implements UseCase<void, String> {
  final TripRepository repository;

  GenerateAndStorePinUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.generateAndStorePin(tripId);
  }
}
