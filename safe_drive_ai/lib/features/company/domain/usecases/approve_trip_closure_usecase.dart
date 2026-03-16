import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

class ApproveTripClosureUseCase implements UseCase<void, String> {
  const ApproveTripClosureUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(String tripId) async {
    return await _repository.approveTripClosure(tripId);
  }
}
