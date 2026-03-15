// lib/core/errors/exceptions.dart

/// Excepciones de la capa de datos (datasources, repository impls).
/// Solo el data layer lanza estas excepciones.
/// Se convierten a Failure en el repository implementation.

// ── Autenticación ─────────────────────────────────────────────────────────────

class AuthException implements Exception {
  const AuthException({this.message = 'Error de autenticación.'});
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super(message: 'Correo o contraseña incorrectos.');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super(message: 'No existe una cuenta con ese correo.');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super(message: 'Ese correo ya está registrado.');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super(message: 'La contraseña es demasiado débil.');
}

class NotAuthenticatedException extends AuthException {
  const NotAuthenticatedException()
      : super(message: 'El usuario no está autenticado.');
}

// ── Servidor ─────────────────────────────────────────────────────────────────

class ServerException implements Exception {
  const ServerException({this.message = 'Error en el servidor.'});
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException: Sin conexión a internet.';
}

// ── Firestore ─────────────────────────────────────────────────────────────────

class FirestoreException implements Exception {
  const FirestoreException({this.message = 'Error al acceder a Firestore.'});
  final String message;

  @override
  String toString() => 'FirestoreException: $message';
}

class DocumentNotFoundException extends FirestoreException {
  const DocumentNotFoundException({String collection = '', String id = ''})
      : super(message: 'Documento no encontrado: $collection/$id');
}

class PermissionDeniedException extends FirestoreException {
  const PermissionDeniedException()
      : super(message: 'Permiso denegado en Firestore.');
}

// ── Caché ─────────────────────────────────────────────────────────────────────

class CacheException implements Exception {
  const CacheException({this.message = 'Error al acceder al caché local.'});
  final String message;

  @override
  String toString() => 'CacheException: $message';
}
