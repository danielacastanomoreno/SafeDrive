import 'package:equatable/equatable.dart';

import '../../domain/entities/company_entity.dart';
import '../../domain/entities/company_link_entity.dart';
import '../../domain/entities/user_entity.dart';

/// Contrato base para todos los estados del BLoC de autenticación.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de que se haya verificado cualquier sesión.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Operación asíncrona en progreso.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No hay sesión activa o el role guardado no coincide con ningún usuario
/// disponible. La UI debe mostrar la pantalla de selección de rol.
class AuthRoleNotSelected extends AuthState {
  const AuthRoleNotSelected();
}

/// Un conductor está autenticado y tiene al menos una empresa resuelta.
///
/// [activeCompanyId] es `null` cuando el conductor no pertenece a ninguna
/// empresa. Cuando tiene exactamente una, ya viene preseleccionada.
class AuthDriverAuthenticated extends AuthState {
  const AuthDriverAuthenticated({
    required this.user,
    required this.companies,
    required this.activeCompanyId,
  });

  final UserEntity user;
  final List<CompanyLinkEntity> companies;
  final String? activeCompanyId;

  @override
  List<Object?> get props => [user, companies, activeCompanyId];
}

/// Una empresa está autenticada.
class AuthCompanyAuthenticated extends AuthState {
  const AuthCompanyAuthenticated({required this.company});

  final CompanyEntity company;

  @override
  List<Object?> get props => [company];
}

/// El conductor tiene más de una empresa vinculada y no hay empresa activa
/// guardada localmente. La UI debe mostrar la pantalla de selección de empresa.
class AuthCompanySelectionRequired extends AuthState {
  const AuthCompanySelectionRequired({
    required this.user,
    required this.companies,
  });

  final UserEntity user;
  final List<CompanyLinkEntity> companies;

  @override
  List<Object?> get props => [user, companies];
}

/// El correo de recuperación de contraseña fue enviado con éxito.
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

/// Ocurrió un error durante una operación de autenticación.
class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// La sesión fue cerrada correctamente.
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}
