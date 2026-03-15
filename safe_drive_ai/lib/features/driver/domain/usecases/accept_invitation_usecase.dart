import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/driver_repository.dart';

class AcceptInvitationUseCase extends UseCase<void, AcceptInvitationParams> {
  const AcceptInvitationUseCase(this._repository);

  final DriverRepository _repository;

  @override
  Future<Either<Failure, void>> call(AcceptInvitationParams params) {
    return _repository.acceptInvitation(
      invitationId: params.invitationId,
      companyId: params.companyId,
      companyName: params.companyName,
      driverId: params.driverId,
      cargo: params.cargo,
      phone: params.phone,
    );
  }
}

class AcceptInvitationParams extends Equatable {
  const AcceptInvitationParams({
    required this.invitationId,
    required this.companyId,
    required this.companyName,
    required this.driverId,
    required this.cargo,
    required this.phone,
  });

  final String invitationId;
  final String companyId;
  final String companyName;
  final String driverId;
  final String cargo;
  final String phone;

  @override
  List<Object> get props => [
        invitationId,
        companyId,
        companyName,
        driverId,
        cargo,
        phone,
      ];
}
