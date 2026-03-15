import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/company_entity.dart';
import '../repositories/auth_repository.dart';

/// Obtiene la empresa autenticada actualmente desde Firebase Auth + Firestore.
///
/// Retorna [Left] con [NotAuthenticatedFailure] cuando no hay sesión activa
/// (Firebase Auth no tiene `currentUser`) o cuando el documento no existe en
/// la colección `companies`.
/// Retorna [Right] con la [CompanyEntity] completa si la sesión es válida.
class GetCurrentCompanyUseCase extends UseCase<CompanyEntity, NoParams> {
  const GetCurrentCompanyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, CompanyEntity>> call(NoParams params) async {
    final result = await _repository.getCurrentCompany();
    return result.fold(
      Left.new,
      (company) => company != null
          ? Right(company)
          : const Left(NotAuthenticatedFailure()),
    );
  }
}
