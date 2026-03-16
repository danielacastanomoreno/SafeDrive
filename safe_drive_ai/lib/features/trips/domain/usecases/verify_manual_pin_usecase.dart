import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

class VerifyManualPinUseCase implements UseCase<bool, String> {
  final TripRepository repository;

  VerifyManualPinUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String inputPin) {
    return repository.verifyManualPin(inputPin);
  }
}
