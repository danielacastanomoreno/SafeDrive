import 'package:equatable/equatable.dart';

/// Estado de una invitación enviada por una empresa a un conductor.
enum InvitationStatus {
  /// Invitación enviada, pendiente de respuesta del conductor.
  pending,

  /// El conductor aceptó la invitación.
  accepted,

  /// El conductor rechazó la invitación.
  rejected,

  /// La empresa canceló la invitación antes de que el conductor respondiera.
  cancelled,
}

/// Entidad que representa una invitación de empresa a conductor.
///
/// Corresponde a un documento en la colección `invitations` de Firestore.
/// Pertenece exclusivamente al dominio. No importa nada de Firebase ni Flutter.
class InvitationEntity extends Equatable {
  const InvitationEntity({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.driverId,
    required this.cargo,
    required this.phone,
    required this.status,
    required this.sentAt,
    this.resolvedAt,
  });

  /// Identificador único de la invitación (document ID en Firestore).
  final String id;

  /// UID de Firebase Auth de la empresa que envía la invitación.
  final String companyId;

  /// Nombre de la empresa (desnormalizado para evitar joins en la UI).
  final String companyName;

  /// UID de Firebase Auth del conductor invitado.
  final String driverId;

  /// Cargo o rol propuesto para el conductor dentro de la empresa.
  final String cargo;

  /// Teléfono de contacto del conductor (10 dígitos, inicia con 3).
  final String phone;

  /// Estado actual de la invitación.
  final InvitationStatus status;

  /// Fecha y hora en que se envió la invitación.
  final DateTime sentAt;

  /// Fecha y hora en que se resolvió la invitación. `null` si sigue pendiente.
  final DateTime? resolvedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        driverId,
        cargo,
        phone,
        status,
        sentAt,
        resolvedAt,
      ];
}
