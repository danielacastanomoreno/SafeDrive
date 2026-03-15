import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/company_link_entity.dart';
import '../repositories/auth_repository.dart';

/// Obtiene la lista de empresas vinculadas a un conductor.
///
/// Consulta `company_drivers` filtrando por [driverId].
class GetDriverCompaniesUseCase
    extends UseCase<List<CompanyLinkEntity>, GetDriverCompaniesParams> {
  const GetDriverCompaniesUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> call(
    GetDriverCompaniesParams params,
  ) {
    return _repository.getDriverCompanies(params.driverId);
  }
}

class GetDriverCompaniesParams extends Equatable {
  const GetDriverCompaniesParams({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
