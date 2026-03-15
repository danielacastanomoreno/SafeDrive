import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Verifica si existe una sesión activa guardada en SharedPreferences.
///
/// Retorna [String?]:
///   - `'driver'`  → hay sesión activa de conductor.
///   - `'company'` → hay sesión activa de empresa.
///   - `null`      → no hay sesión guardada; el usuario debe autenticarse.
class CheckSessionUseCase extends UseCase<String?, NoParams> {
  const CheckSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) {
    return _repository.getSavedRole();
  }
}
