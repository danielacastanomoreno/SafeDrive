import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/company_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../models/invitation_model.dart';
import 'company_datasource.dart';

class CompanyDatasourceImpl implements CompanyDatasource {
  const CompanyDatasourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _auth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ── Conductores ─────────────────────────────────────────────────────────────

  @override
  Future<List<CompanyLinkModel>> getCompanyDrivers(String companyId) async {
    final snapshot = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    final companyDoc =
        await _firestore.collection('companies').doc(companyId).get();
    final companyName =
        companyDoc.exists ? (companyDoc.data()!['name'] as String? ?? '') : '';

    return snapshot.docs
        .map(
          (doc) => CompanyLinkModel.fromMap(doc.id, doc.data(), companyName),
        )
        .toList();
  }

  @override
  Future<UserModel> getDriverProfile(String driverId) async {
    final doc = await _firestore.collection('users').doc(driverId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil del conductor $driverId.',
      );
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Future<void> unlinkDriver(String linkId) async {
    await _firestore.collection('company_drivers').doc(linkId).update({
      'status': 'inactive',
      'unlinkedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Registro de conductor nuevo ──────────────────────────────────────────────

  @override
  Future<void> registerDriverByCompany({
    required String companyId,
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String cargo,
  }) async {
    // 1. Verificar que la cédula no esté registrada en `users`
    final cedulaQuery = await _firestore
        .collection('users')
        .where('cedula', isEqualTo: cedula)
        .limit(1)
        .get();

    if (cedulaQuery.docs.isNotEmpty) {
      throw const CedulaAlreadyRegisteredException();
    }

    // 2. Crear usuario en Firebase Auth con instancia secundaria para no
    //    cerrar la sesión activa de la empresa.
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: 'TmpSD${DateTime.now().millisecondsSinceEpoch}!',
      );
      final driverUid = credential.user!.uid;

      // 3. Crear documento en `users`
      await _firestore.collection('users').doc(driverUid).set({
        'name': name,
        'cedula': cedula,
        'email': email,
        'role': 'driver',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Crear vínculo en `company_drivers`
      await _firestore.collection('company_drivers').add({
        'companyId': companyId,
        'driverId': driverUid,
        'cargo': cargo,
        'phone': phone,
        'status': 'active',
        'linkedAt': FieldValue.serverTimestamp(),
        'unlinkedAt': null,
      });

      // 5. Enviar correo de restablecimiento con el auth PRIMARIO para que
      //    el conductor pueda establecer su propia contraseña.
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const EmailAlreadyRegisteredException();
      }
      rethrow;
    } finally {
      // 6. Siempre eliminar la instancia secundaria para liberar recursos.
      await secondaryApp.delete();
    }
  }

  // ── Invitaciones ────────────────────────────────────────────────────────────

  @override
  Future<void> sendInvitation({
    required String companyId,
    required String companyName,
    required String driverCedula,
    required String cargo,
    required String phone,
  }) async {
    // 1. Buscar conductor por cédula
    final usersQuery = await _firestore
        .collection('users')
        .where('cedula', isEqualTo: driverCedula)
        .limit(1)
        .get();

    if (usersQuery.docs.isEmpty) {
      throw const DriverNotFoundException();
    }

    final driverDoc = usersQuery.docs.first;
    final driverId = driverDoc.id;

    // 2. Verificar que no exista ya una invitación pendiente
    final existingInvitation = await _firestore
        .collection('invitations')
        .where('companyId', isEqualTo: companyId)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw const InvitationAlreadyExistsException();
    }

    // 3. Verificar que el conductor no esté ya activo en la empresa
    final existingLink = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existingLink.docs.isNotEmpty) {
      throw const DriverAlreadyLinkedException();
    }

    // 4. Crear la invitación
    await _firestore.collection('invitations').add({
      'companyId': companyId,
      'companyName': companyName,
      'driverId': driverId,
      'cargo': cargo,
      'phone': phone,
      'status': 'pending',
      'sentAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  @override
  Future<List<InvitationModel>> getCompanyInvitations(
    String companyId,
  ) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('companyId', isEqualTo: companyId)
        .orderBy('sentAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> cancelInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'cancelled',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Perfil empresa ───────────────────────────────────────────────────────────

  @override
  Future<CompanyEntity> updateCompanyProfile({
    required String companyId,
    required String name,
    required String representativeName,
  }) async {
    await _firestore.collection('companies').doc(companyId).update({
      'name': name,
      'representativeName': representativeName,
    });

    final doc =
        await _firestore.collection('companies').doc(companyId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil de la empresa $companyId.',
      );
    }
    return CompanyModel.fromMap(doc.id, doc.data()!);
  }
}
