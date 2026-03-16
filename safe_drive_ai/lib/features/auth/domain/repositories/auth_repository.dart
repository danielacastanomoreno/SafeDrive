import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/company_entity.dart';
import '../entities/company_link_entity.dart';
import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación y sesión.
///
/// Define todas las operaciones posibles sobre auth, perfil de usuario
/// y sesión local. La implementación concreta vive en la capa de datos.
abstract class AuthRepository {
  // ── Autenticación ──────────────────────────────────────────────────────────

  /// Inicia sesión como conductor.
  /// Verifica que el documento en `users` tenga role = "driver".
  Future<Either<Failure, UserEntity>> loginDriver(
    String email,
    String password,
  );

  /// Inicia sesión como empresa.
  /// Verifica que el documento en `companies` tenga role = "company".
  Future<Either<Failure, CompanyEntity>> loginCompany(
    String email,
    String password,
  );

  /// Registra una nueva empresa en Firebase Auth y en Firestore (`companies`).
  Future<Either<Failure, CompanyEntity>> registerCompany(
    String name,
    String nit,
    String email,
    String password,
    String representativeName,
  );

  /// Registra un nuevo conductor en Firebase Auth y en Firestore (`users`).
  Future<Either<Failure, UserEntity>> registerDriver(
    String name,
    String cedula,
    String email,
    String password,
  );

  /// Cierra la sesión activa en Firebase Auth y limpia la sesión local.
  Future<Either<Failure, void>> logout();

  /// Envía un correo de recuperación de contraseña.
  Future<Either<Failure, void>> sendPasswordReset(String email);

  // ── Usuario actual ─────────────────────────────────────────────────────────

  /// Devuelve el conductor autenticado actualmente, o `null` si no hay sesión.
  Future<Either<Failure, UserEntity?>> getCurrentDriver();

  /// Devuelve la empresa autenticada actualmente, o `null` si no hay sesión.
  Future<Either<Failure, CompanyEntity?>> getCurrentCompany();

  // ── Vínculos conductor–empresa ─────────────────────────────────────────────

  /// Obtiene la lista de empresas a las que está vinculado el conductor.
  /// Consulta la colección `company_drivers` filtrando por [driverId].
  Future<Either<Failure, List<CompanyLinkEntity>>> getDriverCompanies(
    String driverId,
  );

  // ── Sesión local (SharedPreferences) ──────────────────────────────────────

  /// Persiste localmente qué empresa está activa para el conductor.
  Future<Either<Failure, void>> setActiveCompany(String companyId);

  /// Lee el ID de la empresa activa guardada localmente.
  /// Devuelve `null` si el conductor no tiene empresa activa seleccionada.
  Future<Either<Failure, String?>> getActiveCompanyId();

  /// Lee el rol guardado en SharedPreferences.
  /// Devuelve `'driver'`, `'company'`, o `null` si no hay sesión guardada.
  Future<Either<Failure, String?>> getSavedRole();

  /// Guarda los datos de sesión en SharedPreferences.
  Future<Either<Failure, void>> saveSession(
    String userId,
    String role,
    String? activeCompanyId,
  );

  /// Elimina todos los datos de sesión de SharedPreferences.
  Future<Either<Failure, void>> clearSession();
}
