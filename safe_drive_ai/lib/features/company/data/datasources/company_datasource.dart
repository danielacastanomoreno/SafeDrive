import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../trips/data/models/trip_model.dart';
import '../models/invitation_model.dart';

/// Contrato de la fuente de datos remota para el feature de empresa.
///
/// La implementación concreta accede a Firestore.
/// El repositorio traduce las excepciones lanzadas aquí en Failures.
abstract class CompanyDatasource {
  /// Obtiene conductores activos vinculados a la empresa.
  Future<List<CompanyLinkModel>> getCompanyDrivers(String companyId);

  /// Obtiene el perfil de un conductor por su UID.
  Future<UserModel> getDriverProfile(String driverId);

  /// Marca el vínculo como inactivo en `company_drivers`.
  Future<void> unlinkDriver(String linkId);

  /// Busca un conductor por cédula y crea la invitación en Firestore.
  Future<void> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverCedula,
    required String cargo,
    required String phone,
  });

  /// Obtiene invitaciones de la empresa ordenadas por sentAt desc.
  Future<List<InvitationModel>> getCompanyInvitations(String companyId);

  /// Cancela una invitación pendiente.
  Future<void> cancelInvitation(String invitationId);

  /// Actualiza nombre y representante de la empresa y devuelve el perfil actualizado.
  Future<CompanyEntity> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  });

  /// Crea una cuenta Firebase Auth para un conductor nuevo (sin cerrar sesión de
  /// la empresa), crea el documento en `users`, el vínculo en `company_drivers`
  /// y envía el correo de restablecimiento de contraseña.
  Future<void> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  });

  /// Obtiene los viajes pendientes de aprobación de los conductores de esta empresa
  Future<List<TripModel>> getPendingTrips(String companyId);

  /// Aprueba el cierre remoto de un viaje
  Future<void> approveTripClosure(String tripId);

  /// Rechaza el cierre de un viaje
  Future<void> rejectTripClosure(String tripId);

  /// Crea un viaje pendiente para un conductor con destino pactado
  Future<TripModel> createTripWithDestination({
    required String companyId,
    required String driverId,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    DateTime? scheduledStartTime,
  });
}

