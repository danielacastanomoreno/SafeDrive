import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Envía una invitación a un conductor buscado por su cédula.
class SendInvitationUseCase extends UseCase<void, SendInvitationParams> {
  const SendInvitationUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(SendInvitationParams params) {
    return _repository.sendInvitation(
      companyId: params.companyId,
      companyName: params.companyName,
      driverCedula: params.driverCedula,
      cargo: params.cargo,
      phone: params.phone,
    );
  }
}

class SendInvitationParams extends Equatable {
  const SendInvitationParams({
    required this.companyId,
    required this.companyName,
    required this.driverCedula,
    required this.cargo,
    required this.phone,
  });

  final String companyId;
  final String companyName;
  final String driverCedula;
  final String cargo;
  final String phone;

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        driverCedula,
        cargo,
        phone,
      ];
}
