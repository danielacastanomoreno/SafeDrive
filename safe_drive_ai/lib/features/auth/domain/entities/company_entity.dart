import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Entidad que representa a una empresa registrada en Safe Drive AI.
///
/// Pertenece exclusivamente al dominio. No importa nada de Firebase ni Flutter.
class CompanyEntity extends Equatable {
  const CompanyEntity({
    required this.id,
    required this.name,
    required this.nit,
    required this.email,
    required this.representativeName,
    required this.role,
    required this.createdAt,
  });

  /// UID de Firebase Auth — clave primaria en Firestore (colección `companies`).
  final String id;

  /// Razón social de la empresa.
  final String name;

  /// NIT de la empresa en formato XXXXXXXXX-Y, validado con algoritmo DIAN.
  final String nit;

  /// Correo electrónico de la empresa.
  final String email;

  /// Nombre del representante legal.
  final String representativeName;

  /// Siempre [UserRole.company] para esta entidad.
  final UserRole role;

  /// Fecha y hora de creación del registro.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        nit,
        email,
        representativeName,
        role,
        createdAt,
      ];
}
