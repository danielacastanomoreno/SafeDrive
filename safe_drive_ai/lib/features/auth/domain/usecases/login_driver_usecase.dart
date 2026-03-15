import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Inicia sesión como conductor verificando rol "driver" en Firestore.
class LoginDriverUseCase extends UseCase<UserEntity, LoginDriverParams> {
  const LoginDriverUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginDriverParams params) {
    return _repository.loginDriver(params.email, params.password);
  }
}

class LoginDriverParams extends Equatable {
  const LoginDriverParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
