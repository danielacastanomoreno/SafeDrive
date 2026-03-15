// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Contrato base para todos los casos de uso.
///
/// [Type]   — tipo del resultado exitoso.
/// [Params] — parámetros de entrada del caso de uso.
///
/// Uso:
///   class LoginUseCase extends UseCase<UserEntity, LoginParams> { ... }
///   final result = await loginUseCase(LoginParams(email: ..., password: ...));
abstract class UseCase<Type, Params> {
  const UseCase();

  Future<Either<Failure, Type>> call(Params params);
}

/// Usar cuando el caso de uso no necesita parámetros.
///
/// Uso:
///   class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> { ... }
///   final result = await getCurrentUserUseCase(const NoParams());
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Usar para casos de uso que trabajan con streams (observación en tiempo real).
///
/// [Type]   — tipo del elemento emitido por el stream.
/// [Params] — parámetros de entrada.
abstract class StreamUseCase<Type, Params> {
  const StreamUseCase();

  Stream<Either<Failure, Type>> call(Params params);
}
