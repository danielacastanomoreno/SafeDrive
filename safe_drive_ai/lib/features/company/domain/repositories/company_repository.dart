import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../entities/invitation_entity.dart';

/// Contrato del repositorio de gestión de empresa.
///
/// Define todas las operaciones posibles para que una empresa administre sus
/// conductores vinculados, invitaciones y perfil propio.
/// La implementación concreta vive en la capa de datos.
abstract class CompanyRepository {
  /// Obtiene la lista de conductores activos vinculados a la empresa.
  ///
  /// Consulta `company_drivers` filtrando por [companyId] y status == 'active'.
  Future<Either<Failure, List<CompanyLinkEntity>>> getCompanyDrivers(
    String companyId,
  );

  /// Obtiene el perfil completo de un conductor por su UID.
  ///
  /// Consulta el documento en la colección `users`.
  Future<Either<Failure, UserEntity>> getDriverProfile(String driverId);

  /// Desvincula a un conductor marcando el link como inactivo.
  ///
  /// Actualiza el campo `status` a 'inactive' y `unlinkedAt` en `company_drivers`.
  Future<Either<Failure, void>> unlinkDriver(String linkId);

  /// Envía una invitación a un conductor identificado por su cédula.
  ///
  /// Busca en `users` el documento cuyo campo `cedula` coincide con
  /// [driverCedula]. Si no existe, falla con [DocumentNotFoundFailure].
  /// Crea un documento en `invitations` con status 'pending'.
  Future<Either<Failure, void>> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverCedula,
    required String cargo,
    required String phone,
  });

  /// Obtiene todas las invitaciones enviadas por la empresa, ordenadas por
  /// fecha de envío descendente.
  Future<Either<Failure, List<InvitationEntity>>> getCompanyInvitations(
    String companyId,
  );

  /// Cancela una invitación pendiente.
  ///
  /// Actualiza el campo `status` a 'cancelled' y `resolvedAt` en `invitations`.
  Future<Either<Failure, void>> cancelInvitation(String invitationId);

  /// Actualiza el nombre y representante legal de la empresa en Firestore.
  Future<Either<Failure, CompanyEntity>> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  });

  /// Registra un conductor nuevo en la plataforma desde la empresa.
  ///
  /// Crea cuenta en Firebase Auth, documento en `users` y vínculo en
  /// `company_drivers`. Envía correo de restablecimiento al conductor.
  Future<Either<Failure, void>> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  });

  /// Obtiene los viajes pendientes de aprobación de los conductores de esta empresa
  Future<Either<Failure, List<TripEntity>>> getPendingTrips(String companyId);

  /// Aprueba el cierre remoto de un viaje
  Future<Either<Failure, void>> approveTripClosure(String tripId);

  /// Rechaza el cierre de un viaje
  Future<Either<Failure, void>> rejectTripClosure(String tripId);

  /// Crea un viaje pendiente para un conductor con destino pactado
  Future<Either<Failure, TripEntity>> createTripWithDestination({
    required String companyId,
    required String driverId,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    DateTime? scheduledStartTime,
  });
}

