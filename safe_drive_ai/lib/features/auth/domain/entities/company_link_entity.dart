import 'package:equatable/equatable.dart';

/// Estado del vínculo entre un conductor y una empresa.
enum LinkStatus {
  /// El conductor está actualmente vinculado y operativo en la empresa.
  active,

  /// El conductor fue desvinculado de la empresa.
  inactive,
}

/// Entidad que representa el vínculo entre un conductor y una empresa.
///
/// Corresponde a un documento en la colección `company_drivers` de Firestore.
/// Pertenece exclusivamente al dominio. No importa nada de Firebase ni Flutter.
class CompanyLinkEntity extends Equatable {
  const CompanyLinkEntity({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.driverId,
    required this.cargo,
    required this.phone,
    required this.status,
    required this.linkedAt,
    this.unlinkedAt,
  });

  /// Identificador único del vínculo (document ID en Firestore).
  final String id;

  /// UID de Firebase Auth de la empresa.
  final String companyId;

  /// Nombre de la empresa (desnormalizado para evitar joins).
  final String companyName;

  /// UID de Firebase Auth del conductor.
  final String driverId;

  /// Cargo o rol del conductor dentro de la empresa.
  final String cargo;

  /// Teléfono de contacto del conductor (10 dígitos, inicia con 3).
  final String phone;

  /// Estado actual del vínculo.
  final LinkStatus status;

  /// Fecha y hora en que se estableció el vínculo.
  final DateTime linkedAt;

  /// Fecha y hora en que se desvinculó. `null` si sigue activo.
  final DateTime? unlinkedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        driverId,
        cargo,
        phone,
        status,
        linkedAt,
        unlinkedAt,
      ];
}
