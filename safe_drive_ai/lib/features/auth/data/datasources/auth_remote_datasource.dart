import '../models/company_link_model.dart';
import '../models/company_model.dart';
import '../models/user_model.dart';

/// Contrato del datasource remoto para autenticación.
///
/// Retorna Models (nunca Entities) y lanza Exceptions (nunca Failures).
/// La traducción Exception → Failure ocurre exclusivamente en el repository impl.
abstract class AuthRemoteDatasource {
  /// Autentica un conductor. Lanza [AuthException] si la cuenta no es de tipo driver.
  Future<UserModel> loginDriver(String email, String password);

  /// Autentica una empresa. Lanza [AuthException] si la cuenta no es de tipo company.
  Future<CompanyModel> loginCompany(String email, String password);

  /// Registra una empresa nueva en Firebase Auth y Firestore.
  /// Lanza [AuthException] si el NIT ya existe en Firestore.
  Future<CompanyModel> registerCompany(
    String name,
    String nit,
    String email,
    String password,
    String representativeName,
  );

  /// Registra un conductor independiente en Firebase Auth y Firestore.
  /// Lanza [AuthException] si la cédula ya existe en Firestore.
  Future<UserModel> registerDriver(
    String name,
    String cedula,
    String email,
    String password,
  );

  /// Cierra la sesión activa en Firebase Auth.
  Future<void> logout();

  /// Envía correo de restablecimiento de contraseña.
  Future<void> sendPasswordReset(String email);

  /// Retorna el conductor autenticado actualmente, o null si no hay sesión.
  Future<UserModel?> getCurrentDriver();

  /// Retorna la empresa autenticada actualmente, o null si no hay sesión.
  Future<CompanyModel?> getCurrentCompany();

  /// Retorna los vínculos activos del conductor con empresas.
  Future<List<CompanyLinkModel>> getDriverCompanies(String driverId);

  /// Persiste el ID de la empresa activa en SharedPreferences.
  Future<void> setActiveCompany(String companyId);

  /// Lee el ID de la empresa activa desde SharedPreferences.
  Future<String?> getActiveCompanyId();

  /// Lee el rol guardado desde SharedPreferences.
  Future<String?> getSavedRole();

  /// Guarda userId, role y opcionalmente activeCompanyId en SharedPreferences.
  Future<void> saveSession(String userId, String role, String? activeCompanyId);

  /// Elimina userId, role y activeCompanyId de SharedPreferences.
  Future<void> clearSession();
}
