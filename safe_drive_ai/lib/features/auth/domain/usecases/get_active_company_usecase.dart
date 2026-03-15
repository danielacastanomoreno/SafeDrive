import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Lee el ID de la empresa activa guardada localmente en SharedPreferences.
///
/// Retorna [String?]:
///   - `String` → el companyId guardado.
///   - `null`   → el conductor no tiene empresa activa seleccionada.
class GetActiveCompanyUseCase extends UseCase<String?, NoParams> {
  const GetActiveCompanyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) {
    return _repository.getActiveCompanyId();
  }
}
