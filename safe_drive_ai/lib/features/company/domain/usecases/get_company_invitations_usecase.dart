import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/invitation_entity.dart';
import '../repositories/company_repository.dart';

/// Obtiene todas las invitaciones enviadas por la empresa, ordenadas por fecha.
class GetCompanyInvitationsUseCase
    extends UseCase<List<InvitationEntity>, GetCompanyInvitationsParams> {
  const GetCompanyInvitationsUseCase(this._repository);

  final CompanyRepository _repository;

  @override
  Future<Either<Failure, List<InvitationEntity>>> call(
    GetCompanyInvitationsParams params,
  ) {
    return _repository.getCompanyInvitations(params.companyId);
  }
}

class GetCompanyInvitationsParams extends Equatable {
  const GetCompanyInvitationsParams({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}
