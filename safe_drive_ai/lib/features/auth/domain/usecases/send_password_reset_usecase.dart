import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Envía un correo de recuperación de contraseña al email indicado.
class SendPasswordResetUseCase extends UseCase<void, SendPasswordResetParams> {
  const SendPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) {
    return _repository.sendPasswordReset(params.email);
  }
}

class SendPasswordResetParams extends Equatable {
  const SendPasswordResetParams({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}
