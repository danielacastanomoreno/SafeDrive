import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../models/company_link_model.dart';
import '../models/company_model.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required SharedPreferences sharedPreferences,
  })  : _auth = firebaseAuth,
        _firestore = firestore,
        _prefs = sharedPreferences;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyActiveCompanyId = 'active_company_id';

  // ── Autenticación ────────────────────────────────────────────────────────────

  @override
  Future<UserModel> loginDriver(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw const AuthException('No se encontró el perfil del conductor.');
    }
    final data = doc.data()!;
    if (data['role'] != 'driver') {
      await _auth.signOut();
      throw const AuthException(
          'Acceso denegado: esta cuenta no es de conductor.');
    }
    return UserModel.fromMap(uid, data);
  }

  @override
  Future<CompanyModel> loginCompany(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await _firestore.collection('companies').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw const AuthException('No se encontró el perfil de la empresa.');
    }
    final data = doc.data()!;
    if (data['role'] != 'company') {
      await _auth.signOut();
      throw const AuthException(
          'Acceso denegado: esta cuenta no es de empresa.');
    }
    return CompanyModel.fromMap(uid, data);
  }

  @override
  Future<CompanyModel> registerCompany(
    String name,
    String nit,
    String email,
    String password,
    String representativeName,
  ) async {
    final nitQuery = await _firestore
        .collection('companies')
        .where('nit', isEqualTo: nit)
        .limit(1)
        .get();
    if (nitQuery.docs.isNotEmpty) {
      throw const AuthException('NIT ya registrado.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final model = CompanyModel(
      id: uid,
      name: name,
      nit: nit,
      email: email,
      representativeName: representativeName,
      role: UserRole.company,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('companies').doc(uid).set(model.toMap());

    return model;
  }

  @override
  Future<UserModel> registerDriver(
    String name,
    String cedula,
    String email,
    String password,
  ) async {
    final cedulaQuery = await _firestore
        .collection('users')
        .where('cedula', isEqualTo: cedula)
        .limit(1)
        .get();
    if (cedulaQuery.docs.isNotEmpty) {
      throw const CedulaAlreadyRegisteredException();
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final model = UserModel(
        id: uid,
        name: name,
        cedula: cedula,
        email: email,
        role: UserRole.driver,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const EmailAlreadyRegisteredException();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Sesión actual ────────────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentDriver() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(user.uid, doc.data()!);
  }

  @override
  Future<CompanyModel?> getCurrentCompany() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('companies').doc(user.uid).get();
    if (!doc.exists) return null;
    return CompanyModel.fromMap(user.uid, doc.data()!);
  }

  // ── Vínculos conductor-empresa ───────────────────────────────────────────────

  @override
  Future<List<CompanyLinkModel>> getDriverCompanies(String driverId) async {
    final snapshot = await _firestore
        .collection('company_drivers')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .get();

    final links = <CompanyLinkModel>[];

    for (final linkDoc in snapshot.docs) {
      final data = linkDoc.data();
      final companyId = data['companyId'] as String;

      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();
      final companyName = companyDoc.exists
          ? (companyDoc.data()!['name'] as String)
          : companyId;

      links.add(CompanyLinkModel.fromMap(linkDoc.id, data, companyName));
    }

    return links;
  }

  // ── SharedPreferences ────────────────────────────────────────────────────────

  @override
  Future<void> setActiveCompany(String companyId) async {
    await _prefs.setString(_keyActiveCompanyId, companyId);
  }

  @override
  Future<String?> getActiveCompanyId() async {
    return _prefs.getString(_keyActiveCompanyId);
  }

  @override
  Future<String?> getSavedRole() async {
    return _prefs.getString(_keyUserRole);
  }

  @override
  Future<void> saveSession(
    String userId,
    String role,
    String? activeCompanyId,
  ) async {
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setString(_keyUserRole, role);
    if (activeCompanyId != null) {
      await _prefs.setString(_keyActiveCompanyId, activeCompanyId);
    }
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserRole);
    await _prefs.remove(_keyActiveCompanyId);
  }
}
