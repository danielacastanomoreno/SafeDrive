import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Desvincula a un conductor de la empresa marcando el link como inactivo.
class UnlinkDriverUseCase extends UseCase<void, UnlinkDriverParams> {
  const UnlinkDriverUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(UnlinkDriverParams params) {
    return _repository.unlinkDriver(params.linkId);
  }
}

class UnlinkDriverParams extends Equatable {
  const UnlinkDriverParams({required this.linkId});

  final String linkId;

  @override
  List<Object?> get props => [linkId];
}
