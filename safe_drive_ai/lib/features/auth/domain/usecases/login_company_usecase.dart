import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/company_entity.dart';
import '../repositories/auth_repository.dart';

/// Inicia sesión como empresa verificando rol "company" en Firestore.
class LoginCompanyUseCase extends UseCase<CompanyEntity, LoginCompanyParams> {
  const LoginCompanyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, CompanyEntity>> call(LoginCompanyParams params) {
    return _repository.loginCompany(params.email, params.password);
  }
}

class LoginCompanyParams extends Equatable {
  const LoginCompanyParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
