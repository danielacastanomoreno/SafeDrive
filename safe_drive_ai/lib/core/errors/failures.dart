import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos del dominio.
/// Solo el dominio y la presentación conocen estas clases.
abstract class Failure extends Equatable {
  const Failure({this.message = ''});

  final String message;

  @override
  List<Object> get props => [message];
}

// ── Autenticación ─────────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Error de autenticación.'});
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
      : super(message: 'Correo o contraseña incorrectos.');
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure()
      : super(message: 'No existe una cuenta con ese correo.');
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure()
      : super(message: 'Ese correo ya está registrado.');
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure()
      : super(message: 'La contraseña es demasiado débil.');
}

class NotAuthenticatedFailure extends Failure {
  const NotAuthenticatedFailure()
      : super(message: 'El usuario no está autenticado.');
}

// ── Servidor / Red ────────────────────────────────────────────────────────────

class ServerFailure extends Failure {
  const ServerFailure(
      {super.message = 'Error en el servidor. Intenta más tarde.'});
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super(message: 'Sin conexión a internet.');
}

// ── Firestore ────────────────────────────────────────────────────────────────

class FirestoreFailure extends Failure {
  const FirestoreFailure(
      {super.message = 'Error al acceder a la base de datos.'});
}

class DocumentNotFoundFailure extends Failure {
  const DocumentNotFoundFailure()
      : super(message: 'No se encontró la información solicitada.');
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure()
      : super(message: 'No tienes permisos para realizar esta acción.');
}

// ── Datos ─────────────────────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Error al leer datos locales.'});
}

// ── Viaje ─────────────────────────────────────────────────────────────────────

class TripAlreadyActiveFailure extends Failure {
  const TripAlreadyActiveFailure()
      : super(message: 'Ya tienes un viaje en curso.');
}

class TripNotFoundFailure extends Failure {
  const TripNotFoundFailure()
      : super(message: 'No se encontró el viaje solicitado.');
}

// ── Invitaciones ──────────────────────────────────────────────────────────────

class InvitationNotFoundFailure extends Failure {
  const InvitationNotFoundFailure()
      : super(message: 'No se encontró la invitación.');
}

class InvitationAlreadyExistsFailure extends Failure {
  const InvitationAlreadyExistsFailure()
      : super(
            message: 'Ya existe una invitación pendiente para este conductor.');
}

class DriverAlreadyLinkedFailure extends Failure {
  const DriverAlreadyLinkedFailure()
      : super(message: 'Este conductor ya está vinculado a tu empresa.');
}

class CedulaAlreadyRegisteredFailure extends Failure {
  const CedulaAlreadyRegisteredFailure()
      : super(
          message:
              'Esta cédula ya está registrada. Usa "Invitar conductor" para vincularlo a tu empresa.',
        );
}

class EmailAlreadyRegisteredFailure extends Failure {
  const EmailAlreadyRegisteredFailure()
      : super(
          message:
              'Este correo ya está registrado. Usa "Invitar conductor" para vincularlo a tu empresa.',
        );
}
