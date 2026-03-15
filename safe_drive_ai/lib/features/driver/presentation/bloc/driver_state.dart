import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../company/domain/entities/invitation_entity.dart';

abstract class DriverState extends Equatable {
  const DriverState();

  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoading extends DriverState {
  const DriverLoading();
}

class DriverInvitationsLoaded extends DriverState {
  const DriverInvitationsLoaded({required this.invitations});

  final List<InvitationEntity> invitations;

  @override
  List<Object?> get props => [invitations];
}

class DriverCompaniesLoaded extends DriverState {
  const DriverCompaniesLoaded({required this.companies});

  final List<CompanyLinkEntity> companies;

  @override
  List<Object?> get props => [companies];
}

class DriverProfileLoaded extends DriverState {
  const DriverProfileLoaded({required this.driver});

  final UserEntity driver;

  @override
  List<Object?> get props => [driver];
}

class DriverActionSuccess extends DriverState {
  const DriverActionSuccess({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class DriverError extends DriverState {
  const DriverError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
