import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../repositories/driver_repository.dart';

class GetDriverLinkedCompaniesUseCase
    extends UseCase<List<CompanyLinkEntity>, GetDriverLinkedCompaniesParams> {
  const GetDriverLinkedCompaniesUseCase(this._repository);

  final DriverRepository _repository;

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> call(
    GetDriverLinkedCompaniesParams params,
  ) {
    return _repository.getDriverLinkedCompanies(params.driverId);
  }
}

class GetDriverLinkedCompaniesParams extends Equatable {
  const GetDriverLinkedCompaniesParams({required this.driverId});

  final String driverId;

  @override
  List<Object> get props => [driverId];
}
