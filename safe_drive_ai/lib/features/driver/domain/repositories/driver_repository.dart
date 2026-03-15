import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../company/domain/entities/invitation_entity.dart';

/// Contrato del repositorio del feature driver.
///
/// La implementación concreta vive en la capa data.
/// Solo el dominio y la presentación conocen esta interfaz.
abstract class DriverRepository {
  /// Obtiene todas las invitaciones del conductor (pending, accepted, rejected).
  Future<Either<Failure, List<InvitationEntity>>> getDriverInvitations(
    String driverId,
  );

  /// Acepta una invitación y crea el vínculo en company_drivers.
  Future<Either<Failure, void>> acceptInvitation({
    required String invitationId,
    required String companyId,
    required String companyName,
    required String driverId,
    required String cargo,
    required String phone,
  });

  /// Rechaza una invitación pendiente.
  Future<Either<Failure, void>> rejectInvitation(String invitationId);

  /// Obtiene las empresas activas vinculadas al conductor.
  Future<Either<Failure, List<CompanyLinkEntity>>> getDriverLinkedCompanies(
    String driverId,
  );

  /// Actualiza el perfil del conductor (name y phone) y devuelve el perfil actualizado.
  Future<Either<Failure, UserEntity>> updateDriverProfile({
    required String driverId,
    required String name,
    required String phone,
  });
}
