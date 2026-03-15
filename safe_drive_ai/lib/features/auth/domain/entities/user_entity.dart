import 'package:equatable/equatable.dart';

/// Roles disponibles en Safe Drive AI.
enum UserRole {
  /// Conductor que usa la app para monitoreo de viajes.
  driver,

  /// Empresa que visualiza datos de sus conductores vinculados.
  company,
}

/// Entidad que representa a un conductor registrado en el sistema.
///
/// Pertenece exclusivamente al dominio. No importa nada de Firebase ni Flutter.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    required this.cedula,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// UID de Firebase Auth — clave primaria en Firestore (colección `users`).
  final String id;

  /// Nombre completo del conductor.
  final String name;

  /// Número de cédula colombiana (6–10 dígitos).
  final String cedula;

  /// Correo electrónico del conductor.
  final String email;

  /// Rol del usuario en el sistema.
  final UserRole role;

  /// Fecha y hora de creación del registro.
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, cedula, email, role, createdAt];
}
