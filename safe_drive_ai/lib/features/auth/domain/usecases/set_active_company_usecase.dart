import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Persiste localmente el ID de la empresa activa seleccionada por el conductor.
class SetActiveCompanyUseCase extends UseCase<void, SetActiveCompanyParams> {
  const SetActiveCompanyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetActiveCompanyParams params) {
    return _repository.setActiveCompany(params.companyId);
  }
}

class SetActiveCompanyParams extends Equatable {
  const SetActiveCompanyParams({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}
