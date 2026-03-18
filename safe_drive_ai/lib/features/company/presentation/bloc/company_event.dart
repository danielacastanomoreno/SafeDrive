import 'package:equatable/equatable.dart';

/// Contrato base para todos los eventos del BLoC de empresa.
abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita la lista de conductores activos vinculados a la empresa.
class CompanyDriversRequested extends CompanyEvent {
  const CompanyDriversRequested({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita desvincular a un conductor de la empresa.
class CompanyDriverUnlinkRequested extends CompanyEvent {
  const CompanyDriverUnlinkRequested({
    required this.linkId,
    required this.companyId,
  });

  final String linkId;

  /// Se usa para recargar la lista tras la desvinculación.
  final String companyId;

  @override
  List<Object?> get props => [linkId, companyId];
}

/// Solicita enviar una invitación a un conductor por su cédula.
class CompanyInvitationSendRequested extends CompanyEvent {
  const CompanyInvitationSendRequested({
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

/// Solicita la lista de invitaciones enviadas por la empresa.
class CompanyInvitationsRequested extends CompanyEvent {
  const CompanyInvitationsRequested({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita cancelar una invitación pendiente.
class CompanyInvitationCancelRequested extends CompanyEvent {
  const CompanyInvitationCancelRequested({
    required this.invitationId,
    required this.companyId,
  });

  final String invitationId;

  /// Se usa para recargar la lista tras la cancelación.
  final String companyId;

  @override
  List<Object?> get props => [invitationId, companyId];
}

/// Solicita cargar el perfil actual de la empresa.
class CompanyProfileRequested extends CompanyEvent {
  const CompanyProfileRequested({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita actualizar el nombre y representante legal de la empresa.
class CompanyProfileUpdateRequested extends CompanyEvent {
  const CompanyProfileUpdateRequested({
    required this.companyId,
    required this.name,
    required this.representativeName,
  });

  final String companyId;
  final String name;
  final String representativeName;

  @override
  List<Object?> get props => [companyId, name, representativeName];
}

/// Solicita registrar un conductor nuevo en la plataforma desde la empresa.
class CompanyDriverRegisterRequested extends CompanyEvent {
  const CompanyDriverRegisterRequested({
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.cedula,
    required this.email,
    required this.phone,
    required this.cargo,
  });

  final String companyId;
  final String companyName;
  final String name;
  final String cedula;
  final String email;
  final String phone;
  final String cargo;

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        name,
        cedula,
        email,
        phone,
        cargo,
      ];
}

/// Solicita obtener la lista de viajes pendientes de aprobación de cierre.
class CompanyPendingTripsRequested extends CompanyEvent {
  const CompanyPendingTripsRequested({required this.companyId});

  final String companyId;

  @override
  List<Object?> get props => [companyId];
}

/// Solicita aprobar el cierre de un viaje.
class CompanyTripClosureApproved extends CompanyEvent {
  const CompanyTripClosureApproved({
    required this.tripId,
    required this.companyId,
  });

  final String tripId;
  final String companyId; // Para poder recargar la lista luego de aprobar

  @override
  List<Object?> get props => [tripId, companyId];
}

/// Solicita rechazar el cierre de un viaje.
class CompanyTripClosureRejected extends CompanyEvent {
  const CompanyTripClosureRejected({
    required this.tripId,
    required this.companyId,
  });

  final String tripId;
  final String companyId;

  @override
  List<Object?> get props => [tripId, companyId];
}

