import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/driver_repository.dart';

class UpdateDriverProfileUseCase
    extends UseCase<UserEntity, UpdateDriverProfileParams> {
  const UpdateDriverProfileUseCase(this._repository);

  final DriverRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateDriverProfileParams params) {
    return _repository.updateDriverProfile(
      driverId: params.driverId,
      name: params.name,
      phone: params.phone,
    );
  }
}

class UpdateDriverProfileParams extends Equatable {
  const UpdateDriverProfileParams({
    required this.driverId,
    required this.name,
    required this.phone,
  });

  final String driverId;
  final String name;
  final String phone;

  @override
  List<Object> get props => [driverId, name, phone];
}
