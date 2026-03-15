import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Registra un conductor nuevo en la plataforma asociado a la empresa.
///
/// Responsabilidad única: orquestar la llamada al repositorio con los datos
/// del formulario. No contiene lógica de validación — esa vive en la UI.
class RegisterDriverByCompanyUseCase
    implements UseCase<void, RegisterDriverByCompanyParams> {
  const RegisterDriverByCompanyUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    RegisterDriverByCompanyParams params,
  ) {
    return _repository.registerDriverByCompany(
      companyId: params.companyId,
      name: params.name,
      cedula: params.cedula,
      email: params.email,
      phone: params.phone,
      cargo: params.cargo,
    );
  }
}

class RegisterDriverByCompanyParams {
  const RegisterDriverByCompanyParams({
    required this.companyId,
    required this.name,
    required this.cedula,
    required this.email,
    required this.phone,
    required this.cargo,
  });

  final String companyId;
  final String name;
  final String cedula;
  final String email;
  final String phone;
  final String cargo;
}
