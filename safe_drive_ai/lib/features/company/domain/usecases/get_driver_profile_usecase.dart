import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/company_repository.dart';

/// Obtiene el perfil completo de un conductor por su UID.
class GetDriverProfileUseCase
    extends UseCase<UserEntity, GetDriverProfileParams> {
  const GetDriverProfileUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(GetDriverProfileParams params) {
    return _repository.getDriverProfile(params.driverId);
  }
}

class GetDriverProfileParams extends Equatable {
  const GetDriverProfileParams({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}
