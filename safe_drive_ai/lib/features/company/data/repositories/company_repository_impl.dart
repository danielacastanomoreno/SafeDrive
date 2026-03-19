import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../auth/domain/entities/company_link_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../domain/entities/invitation_entity.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/company_datasource.dart';

/// Implementación concreta del repositorio de empresa.
///
/// Su única responsabilidad es traducir excepciones de la capa data
/// en Failures del dominio. No contiene lógica de negocio propia.
class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl(this._datasource);

  final CompanyDatasource _datasource;

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> getCompanyDrivers(
    String companyId,
  ) async {
    try {
      final models = await _datasource.getCompanyDrivers(companyId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getDriverProfile(
    String driverId,
  ) async {
    try {
      final model = await _datasource.getDriverProfile(driverId);
      return Right(model);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> unlinkDriver(String linkId) async {
    try {
      await _datasource.unlinkDriver(linkId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverCedula,
    required String cargo,
    required String phone,
  }) async {
    try {
      await _datasource.sendInvitation(
        companyId: companyId,
        companyName: companyName,
        driverCedula: driverCedula,
        cargo: cargo,
        phone: phone,
      );
      return const Right(null);
    } on DriverNotFoundException {
      return const Left(
        ValidationFailure(
            message:
                'No existe ningún conductor registrado con esa cédula. Debes registrarlo primero.'),
      );
    } on InvitationAlreadyExistsException {
      return const Left(InvitationAlreadyExistsFailure());
    } on DriverAlreadyLinkedException {
      return const Left(DriverAlreadyLinkedFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<InvitationEntity>>> getCompanyInvitations(
    String companyId,
  ) async {
    try {
      final models = await _datasource.getCompanyInvitations(companyId);
      return Right(models);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> cancelInvitation(
    String invitationId,
  ) async {
    try {
      await _datasource.cancelInvitation(invitationId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  }) async {
    try {
      final entity = await _datasource.updateCompanyProfile(
        companyId: companyId,
        name: name,
        representativeName: representativeName,
      );
      return Right(entity);
    } on DocumentNotFoundException {
      return const Left(DocumentNotFoundFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  }) async {
    try {
      await _datasource.registerDriverByCompany(
        companyId: companyId,
        name: name,
        cedula: cedula,
        email: email,
        phone: phone,
        cargo: cargo,
      );
      return const Right(null);
    } on CedulaAlreadyRegisteredException {
      return const Left(CedulaAlreadyRegisteredFailure());
    } on EmailAlreadyRegisteredException {
      return const Left(EmailAlreadyRegisteredFailure());
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  // ── Aprobaciones de Viajes ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TripEntity>>> getPendingTrips(String companyId) async {
    try {
      final trips = await _datasource.getPendingTrips(companyId);
      return Right(trips);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> approveTripClosure(String tripId) async {
    try {
      await _datasource.approveTripClosure(tripId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> rejectTripClosure(String tripId) async {
    try {
      await _datasource.rejectTripClosure(tripId);
      return const Right(null);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, TripEntity>> createTripWithDestination({
    required String companyId,
    required String driverId,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    DateTime? scheduledStartTime,
  }) async {
    try {
      final trip = await _datasource.createTripWithDestination(
        companyId: companyId,
        driverId: driverId,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationAddress: destinationAddress,
        scheduledStartTime: scheduledStartTime,
      );
      return Right(trip);
    } on FirestoreException catch (e) {
      return Left(FirestoreFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

