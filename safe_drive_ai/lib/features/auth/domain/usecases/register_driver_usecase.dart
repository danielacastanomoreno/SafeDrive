import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Registra un conductor independiente en la aplicación.
class RegisterDriverUseCase
    implements UseCase<UserEntity, RegisterDriverParams> {
  const RegisterDriverUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterDriverParams params) {
    return _repository.registerDriver(
      params.name,
      params.cedula,
      params.email,
      params.password,
    );
  }
}

class RegisterDriverParams extends Equatable {
  const RegisterDriverParams({
    required this.name,
    required this.cedula,
    required this.email,
    required this.password,
  });

  final String name;
  final String cedula;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, cedula, email, password];
}
