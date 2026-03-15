import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../company/data/models/invitation_model.dart';

/// Contrato de la fuente de datos remota para el feature driver.
///
/// La implementación concreta accede a Firestore.
/// El repositorio traduce las excepciones lanzadas aquí en Failures.
abstract class DriverDatasource {
  /// Obtiene todas las invitaciones del conductor (pending, accepted, rejected).
  Future<List<InvitationModel>> getDriverInvitations(String driverId);

  /// Acepta una invitación y crea el vínculo activo en company_drivers.
  Future<void> acceptInvitation({
    required String invitationId,
    required String companyId,
    required String companyName,
    required String driverId,
    required String cargo,
    required String phone,
  });

  /// Rechaza una invitación pendiente.
  Future<void> rejectInvitation(String invitationId);

  /// Obtiene las empresas activas vinculadas al conductor con nombre desnormalizado.
  Future<List<CompanyLinkModel>> getDriverLinkedCompanies(String driverId);

  /// Actualiza name y phone en el doc del conductor y devuelve el perfil actualizado.
  Future<UserModel> updateDriverProfile({
    required String driverId,
    required String name,
    required String phone,
  });
}
