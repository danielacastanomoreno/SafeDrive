import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Obtiene el conductor autenticado actualmente desde Firebase Auth + Firestore.
///
/// Retorna [Left] con [NotAuthenticatedFailure] cuando no hay sesión activa
/// (Firebase Auth no tiene `currentUser`) o cuando el documento no existe en
/// la colección `users`.
/// Retorna [Right] con el [UserEntity] completo si la sesión es válida.
class GetCurrentDriverUseCase extends UseCase<UserEntity, NoParams> {
  const GetCurrentDriverUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    final result = await _repository.getCurrentDriver();
    return result.fold(
      Left.new,
      (user) =>
          user != null ? Right(user) : const Left(NotAuthenticatedFailure()),
    );
  }
}
