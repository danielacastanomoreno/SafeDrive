import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

class RejectTripClosureUseCase implements UseCase<void, String> {
  final CompanyRepository repository;

  RejectTripClosureUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String tripId) {
    return repository.rejectTripClosure(tripId);
  }
}
