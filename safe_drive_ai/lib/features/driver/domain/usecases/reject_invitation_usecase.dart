import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/driver_repository.dart';

class RejectInvitationUseCase extends UseCase<void, RejectInvitationParams> {
  const RejectInvitationUseCase(this._repository);

  final DriverRepository _repository;

  @override
  Future<Either<Failure, void>> call(RejectInvitationParams params) {
    return _repository.rejectInvitation(params.invitationId);
  }
}

class RejectInvitationParams extends Equatable {
  const RejectInvitationParams({required this.invitationId});

  final String invitationId;

  @override
  List<Object> get props => [invitationId];
}
