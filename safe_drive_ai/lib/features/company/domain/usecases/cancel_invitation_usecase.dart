import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/company_repository.dart';

/// Cancela una invitación pendiente enviada por la empresa.
class CancelInvitationUseCase extends UseCase<void, CancelInvitationParams> {
  const CancelInvitationUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, void>> call(CancelInvitationParams params) {
    return _repository.cancelInvitation(params.invitationId);
  }
}

class CancelInvitationParams extends Equatable {
  const CancelInvitationParams({required this.invitationId});

  final String invitationId;

  @override
  List<Object?> get props => [invitationId];
}
