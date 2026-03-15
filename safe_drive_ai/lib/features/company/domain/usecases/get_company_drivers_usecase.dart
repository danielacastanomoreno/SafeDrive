import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../repositories/company_repository.dart';

/// Obtiene la lista de conductores activos vinculados a una empresa.
class GetCompanyDriversUseCase
    extends UseCase<List<CompanyLinkEntity>, GetCompanyDriversParams> {
  const GetCompanyDriversUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> call(
    GetCompanyDriversParams params,
  ) {
    return _repository.getCompanyDrivers(params.companyId);
  }
}

class GetCompanyDriversParams extends Equatable {
  const GetCompanyDriversParams({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}
