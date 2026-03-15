import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../repositories/company_repository.dart';

/// Actualiza el nombre y representante legal del perfil de empresa.
class UpdateCompanyProfileUseCase
    extends UseCase<CompanyEntity, UpdateCompanyProfileParams> {
  const UpdateCompanyProfileUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, CompanyEntity>> call(
    UpdateCompanyProfileParams params,
  ) {
    return _repository.updateCompanyProfile(
      companyId: params.companyId,
      name: params.name,
      representativeName: params.representativeName,
    );
  }
}

class UpdateCompanyProfileParams extends Equatable {
  const UpdateCompanyProfileParams({
    required this.companyId,
    required this.name,
    required this.representativeName,
  });

  final String companyId;
  final String name;
  final String representativeName;

  @override
  List<Object?> get props => [companyId, name, representativeName];
}
