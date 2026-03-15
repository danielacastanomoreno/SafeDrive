// Excepciones lanzadas por la capa data.
// La capa domain nunca las ve — el repository impl las convierte a Failures.

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

class UserNotFoundException implements Exception {
  const UserNotFoundException();

  @override
  String toString() => 'UserNotFoundException';
}

class EmailAlreadyInUseException implements Exception {
  const EmailAlreadyInUseException();

  @override
  String toString() => 'EmailAlreadyInUseException';
}

class WeakPasswordException implements Exception {
  const WeakPasswordException();

  @override
  String toString() => 'WeakPasswordException';
}

class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();

  @override
  String toString() => 'NotAuthenticatedException';
}

class ServerException implements Exception {
  const ServerException(this.message);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException';
}

class FirestoreException implements Exception {
  const FirestoreException(this.message);

  final String message;

  @override
  String toString() => 'FirestoreException: $message';
}

class DocumentNotFoundException implements Exception {
  const DocumentNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'DocumentNotFoundException: $message';
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException();

  @override
  String toString() => 'PermissionDeniedException';
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class DriverNotFoundException implements Exception {
  const DriverNotFoundException();

  @override
  String toString() => 'DriverNotFoundException';
}

class InvitationAlreadyExistsException implements Exception {
  const InvitationAlreadyExistsException();

  @override
  String toString() => 'InvitationAlreadyExistsException';
}

class DriverAlreadyLinkedException implements Exception {
  const DriverAlreadyLinkedException();

  @override
  String toString() => 'DriverAlreadyLinkedException';
}

class TripAlreadyActiveException implements Exception {
  const TripAlreadyActiveException();

  @override
  String toString() => 'TripAlreadyActiveException';
}

/// La cédula proporcionada ya pertenece a un conductor registrado.
/// La empresa debe usar "Invitar conductor" en su lugar.
class CedulaAlreadyRegisteredException implements Exception {
  const CedulaAlreadyRegisteredException();

  @override
  String toString() => 'CedulaAlreadyRegisteredException';
}

/// El correo proporcionado ya pertenece a una cuenta en Firebase Auth.
/// La empresa debe usar "Invitar conductor" en su lugar.
class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException();

  @override
  String toString() => 'EmailAlreadyRegisteredException';
}
