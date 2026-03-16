import 'package:equatable/equatable.dart';

/// Contrato base para todos los eventos del BLoC de autenticación.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Se dispara al abrir la app para verificar si existe una sesión activa.
class AuthCheckSessionRequested extends AuthEvent {
  const AuthCheckSessionRequested();
}

/// Solicita inicio de sesión para un conductor.
class AuthDriverLoginRequested extends AuthEvent {
  const AuthDriverLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Solicita inicio de sesión para una empresa.
class AuthCompanyLoginRequested extends AuthEvent {
  const AuthCompanyLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Solicita el registro de una nueva empresa.
class AuthCompanyRegisterRequested extends AuthEvent {
  const AuthCompanyRegisterRequested({
    required this.name,
    required this.nit,
    required this.email,
    required this.password,
    required this.representativeName,
  });

  final String name;
  final String nit;
  final String email;
  final String password;
  final String representativeName;

  @override
  List<Object?> get props => [name, nit, email, password, representativeName];
}

/// Solicita el registro de un nuevo conductor independiente.
class AuthDriverRegisterRequested extends AuthEvent {
  const AuthDriverRegisterRequested({
    required this.name,
    required this.cedula,
    required this.email,
    required this.password,
  });

  final String name;
  final String cedula;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, cedula, email, password];
}

/// Solicita cerrar la sesión activa.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Solicita el envío de un correo de recuperación de contraseña.
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// El conductor seleccionó una empresa activa por primera vez
/// (desde la pantalla de selección de empresa).
class AuthCompanySelected extends AuthEvent {
  const AuthCompanySelected({
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  List<Object?> get props => [companyId, companyName];
}

/// El conductor solicita cambiar la empresa activa desde el perfil o menú.
class AuthActiveCompanyChangeRequested extends AuthEvent {
  const AuthActiveCompanyChangeRequested({
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  List<Object?> get props => [companyId, companyName];
}
