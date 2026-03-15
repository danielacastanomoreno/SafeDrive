import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../company/domain/entities/invitation_entity.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_datasource.dart';

/// Implementación del repositorio del feature driver.
///
/// Responsabilidad única: traducir excepciones de la capa data a Failures
/// del dominio. No contiene lógica de negocio.
class DriverRepositoryImpl implements DriverRepository {
  const DriverRepositoryImpl(this._datasource);

  final DriverDatasource _datasource;

  @override
  Future<Either<Failure, List<InvitationEntity>>> getDriverInvitations(
    String driverId,
  ) async {
    try {
      final models = await _datasource.getDriverInvitations(driverId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } on PermissionDeniedException {
      return const Left(PermissionDeniedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptInvitation({
    required String invitationId,
    required String companyId,
    required String companyName,
    required String driverId,
    required String cargo,
    required String phone,
  }) async {
    try {
      await _datasource.acceptInvitation(
        invitationId: invitationId,
        companyId: companyId,
        companyName: companyName,
        driverId: driverId,
        cargo: cargo,
        phone: phone,
      );
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } on PermissionDeniedException {
      return const Left(PermissionDeniedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectInvitation(String invitationId) async {
    try {
      await _datasource.rejectInvitation(invitationId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } on PermissionDeniedException {
      return const Left(PermissionDeniedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> getDriverLinkedCompanies(
    String driverId,
  ) async {
    try {
      final models = await _datasource.getDriverLinkedCompanies(driverId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } on PermissionDeniedException {
      return const Left(PermissionDeniedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateDriverProfile({
    required String driverId,
    required String name,
    required String phone,
  }) async {
    try {
      final model = await _datasource.updateDriverProfile(
        driverId: driverId,
        name: name,
        phone: phone,
      );
      return Right(model);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } on PermissionDeniedException {
      return const Left(PermissionDeniedFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
