import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Contrato base para todos los casos de uso.
///
/// [Result] — tipo del resultado exitoso.
/// [Params] — parámetros de entrada del caso de uso.
abstract class UseCase<Result, Params> {
  const UseCase();

  Future<Either<Failure, Result>> call(Params params);
}

/// Usar cuando el caso de uso no necesita parámetros.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Usar para casos de uso que trabajan con streams (observación en tiempo real).
///
/// [Result] — tipo del elemento emitido por el stream.
/// [Params] — parámetros de entrada.
abstract class StreamUseCase<Result, Params> {
  const StreamUseCase();

  Stream<Either<Failure, Result>> call(Params params);
}
