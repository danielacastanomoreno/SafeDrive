import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/trip_repository.dart';

class RequestRemoteClosureUseCase implements UseCase<void, String> {
  final TripRepository repository;

  RequestRemoteClosureUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.requestRemoteClosure(tripId);
  }
}
