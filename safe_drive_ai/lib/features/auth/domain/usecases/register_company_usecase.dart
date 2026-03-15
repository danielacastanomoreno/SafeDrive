import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/company_entity.dart';
import '../repositories/auth_repository.dart';

/// Registra una nueva empresa en Firebase Auth y en Firestore.
class RegisterCompanyUseCase
    extends UseCase<CompanyEntity, RegisterCompanyParams> {
  const RegisterCompanyUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, CompanyEntity>> call(RegisterCompanyParams params) {
    return _repository.registerCompany(
      params.name,
      params.nit,
      params.email,
      params.password,
      params.representativeName,
    );
  }
}

class RegisterCompanyParams extends Equatable {
  const RegisterCompanyParams({
    required this.name,
    required this.nit,
    required this.email,
    required this.password,
    required this.representativeName,
  });

  final String name;
  final String nit;
  final String email;
  final String password;
  final String representativeName;

  @override
  List<Object?> get props => [name, nit, email, password, representativeName];
}
