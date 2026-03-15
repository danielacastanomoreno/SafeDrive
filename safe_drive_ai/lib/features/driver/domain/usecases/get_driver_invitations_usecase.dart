import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../company/domain/entities/invitation_entity.dart';
import '../repositories/driver_repository.dart';

class GetDriverInvitationsUseCase
    extends UseCase<List<InvitationEntity>, GetDriverInvitationsParams> {
  const GetDriverInvitationsUseCase(this._repository);

  final DriverRepository _repository;

  @override
  Future<Either<Failure, List<InvitationEntity>>> call(
    GetDriverInvitationsParams params,
  ) {
    return _repository.getDriverInvitations(params.driverId);
  }
}

class GetDriverInvitationsParams extends Equatable {
  const GetDriverInvitationsParams({required this.driverId});

  final String driverId;

  @override
  List<Object> get props => [driverId];
}
