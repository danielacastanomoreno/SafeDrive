import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/company_link_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  // ── Helpers de traducción de excepciones ─────────────────────────────────────

  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return AuthFailure(message: e.message ?? 'Error inesperado.');
    }
  }

  // ── Autenticación ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> loginDriver(
    String email,
    String password,
  ) async {
    try {
      final model = await _datasource.loginDriver(email, password);
      return Right(model);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> loginCompany(
    String email,
    String password,
  ) async {
    try {
      final model = await _datasource.loginCompany(email, password);
      return Right(model);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity>> registerCompany(
    String name,
    String nit,
    String email,
    String password,
    String representativeName,
  ) async {
    try {
      final model = await _datasource.registerCompany(
        name,
        nit,
        email,
        password,
        representativeName,
      );
      return Right(model);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerDriver(
    String name,
    String cedula,
    String email,
    String password,
  ) async {
    try {
      final model = await _datasource.registerDriver(
        name,
        cedula,
        email,
        password,
      );
      return Right(model);
    } on CedulaAlreadyRegisteredException {
      return const Left(CedulaAlreadyRegisteredFailure());
    } on EmailAlreadyRegisteredException {
      return const Left(EmailAlreadyRegisteredFailure());
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _datasource.logout();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await _datasource.sendPasswordReset(email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Sesión actual ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserEntity?>> getCurrentDriver() async {
    try {
      final model = await _datasource.getCurrentDriver();
      return Right(model);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CompanyEntity?>> getCurrentCompany() async {
    try {
      final model = await _datasource.getCurrentCompany();
      return Right(model);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Vínculos conductor-empresa ───────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CompanyLinkEntity>>> getDriverCompanies(
    String driverId,
  ) async {
    try {
      final models = await _datasource.getDriverCompanies(driverId);
      return Right(models);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── SharedPreferences ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> setActiveCompany(String companyId) async {
    try {
      await _datasource.setActiveCompany(companyId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getActiveCompanyId() async {
    try {
      final id = await _datasource.getActiveCompanyId();
      return Right(id);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getSavedRole() async {
    try {
      final role = await _datasource.getSavedRole();
      return Right(role);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSession(
    String userId,
    String role,
    String? activeCompanyId,
  ) async {
    try {
      await _datasource.saveSession(userId, role, activeCompanyId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearSession() async {
    try {
      await _datasource.clearSession();
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
