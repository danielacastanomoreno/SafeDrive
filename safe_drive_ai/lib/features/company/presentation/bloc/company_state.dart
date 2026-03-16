import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/entities/invitation_entity.dart';

/// Contrato base para todos los estados del BLoC de empresa.
abstract class CompanyState extends Equatable {
  const CompanyState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cualquier operación.
class CompanyInitial extends CompanyState {
  const CompanyInitial();
}

/// Operación asíncrona en progreso.
class CompanyLoading extends CompanyState {
  const CompanyLoading();
}

/// Lista de conductores activos cargada correctamente.
class CompanyDriversLoaded extends CompanyState {
  const CompanyDriversLoaded({required this.drivers});

  final List<CompanyLinkEntity> drivers;

  @override
  List<Object?> get props => [drivers];
}

/// Lista de invitaciones cargada correctamente.
class CompanyInvitationsLoaded extends CompanyState {
  const CompanyInvitationsLoaded({required this.invitations});

  final List<InvitationEntity> invitations;

  @override
  List<Object?> get props => [invitations];
}

/// Perfil de la empresa cargado o actualizado correctamente.
class CompanyProfileLoaded extends CompanyState {
  const CompanyProfileLoaded({required this.company});

  final CompanyEntity company;

  @override
  List<Object?> get props => [company];
}

/// Una acción (desvincular, invitar, cancelar, actualizar perfil) completó con éxito.
class CompanyActionSuccess extends CompanyState {
  const CompanyActionSuccess({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Ocurrió un error durante una operación del feature de empresa.
class CompanyError extends CompanyState {
  const CompanyError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Lista de viajes pendientes de cierre cargada correctamente.
class CompanyPendingTripsLoaded extends CompanyState {
  const CompanyPendingTripsLoaded({required this.pendingTrips});

  final List<TripEntity> pendingTrips;

  @override
  List<Object?> get props => [pendingTrips];
}

