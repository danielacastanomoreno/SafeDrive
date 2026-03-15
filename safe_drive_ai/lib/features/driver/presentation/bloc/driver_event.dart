import 'package:equatable/equatable.dart';

abstract class DriverEvent extends Equatable {
  const DriverEvent();

  @override
  List<Object> get props => [];
}

class DriverInvitationsRequested extends DriverEvent {
  const DriverInvitationsRequested({required this.driverId});

  final String driverId;

  @override
  List<Object> get props => [driverId];
}

class DriverInvitationAccepted extends DriverEvent {
  const DriverInvitationAccepted({
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

class DriverInvitationRejected extends DriverEvent {
  const DriverInvitationRejected({
    required this.invitationId,
    required this.driverId,
  });

  final String invitationId;
  final String driverId;

  @override
  List<Object> get props => [invitationId, driverId];
}

class DriverCompaniesRequested extends DriverEvent {
  const DriverCompaniesRequested({required this.driverId});

  final String driverId;

  @override
  List<Object> get props => [driverId];
}

class DriverProfileRequested extends DriverEvent {
  const DriverProfileRequested({required this.driverId});

  final String driverId;

  @override
  List<Object> get props => [driverId];
}

class DriverProfileUpdateRequested extends DriverEvent {
  const DriverProfileUpdateRequested({
    required this.driverId,
    required this.name,
    required this.phone,
  });

  final String driverId;
  final String name;
  final String phone;

  @override
  List<Object> get props => [driverId, name, phone];
}
