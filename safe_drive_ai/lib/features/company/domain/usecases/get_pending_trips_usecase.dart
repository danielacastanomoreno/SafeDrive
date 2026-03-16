import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/company_repository.dart';

class GetPendingTripsUseCase implements UseCase<List<TripEntity>, String> {
  const GetPendingTripsUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, List<TripEntity>>> call(String companyId) async {
    return await _repository.getPendingTrips(companyId);
  }
}
