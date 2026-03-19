import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/company_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/company_entity.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../models/invitation_model.dart';
import 'company_datasource.dart';

class CompanyDatasourceImpl implements CompanyDatasource {
  const CompanyDatasourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

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

    // 2. Generar contraseña temporal segura
    final tempPassword = 'SD${DateTime.now().millisecondsSinceEpoch}!Ab';

    // 3. Crear usuario en Firebase Auth con instancia secundaria para no
    //    cerrar la sesión activa de la empresa.
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    String? driverUid;
    try {
      // Crear usuario con contraseña temporal en la instancia secundaria
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      driverUid = credential.user!.uid;

      // 4. Crear documento en `users`
      await _firestore.collection('users').doc(driverUid).set({
        'name': name,
        'cedula': cedula,
        'email': email,
        'role': 'driver',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Crear vínculo en `company_drivers`
      await _firestore.collection('company_drivers').add({
        'companyId': companyId,
        'driverId': driverUid,
        'cargo': cargo,
        'phone': phone,
        'status': 'active',
        'linkedAt': FieldValue.serverTimestamp(),
        'unlinkedAt': null,
      });

      // 6. Enviar correo de restablecimiento de contraseña DESPUÉS de crear
      //    el usuario usando la instancia secundaria donde se creó.
      await secondaryAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const EmailAlreadyRegisteredException();
      }
      // Re-lanzar otras excepciones de Firebase
      rethrow;
    } finally {
      // 7. Siempre eliminar la instancia secundaria para liberar recursos.
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

    final doc = await _firestore.collection('companies').doc(companyId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil de la empresa $companyId.',
      );
    }
    return CompanyModel.fromMap(doc.id, doc.data()!);
  }

  // ── Aprobaciones de Viajes ───────────────────────────────────────────────────

  @override
  Future<List<TripModel>> getPendingTrips(String companyId) async {
    // 1. Obtener todos los conductores vinculados y activos de la empresa
    final driversQuery = await _firestore
        .collection('company_drivers')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .get();

    if (driversQuery.docs.isEmpty) return [];

    final driverIds = driversQuery.docs.map((d) => d['driverId'] as String).toList();

    // 2. Fragmentar la lista de IDs (Firestore admite máximo 10 en 'whereIn')
    final List<TripModel> pendingTrips = [];
    
    // Firestore solo soporta 10 elementos en IN, agrupamos.
    for (var i = 0; i < driverIds.length; i += 10) {
      final chunk = driverIds.sublist(i, (i + 10) > driverIds.length ? driverIds.length : (i + 10));
      
      final tripsQuery = await _firestore
          .collection('trips')
          .where('driverId', whereIn: chunk)
          .where('status', isEqualTo: 'active')
          // no se puede usar where('closureRequestedAt', isNotEqualTo: null) porque Firebase restringe multiples inegualdades
          .get();

      // Filtramos en cliente por si acaso y verificamos el closureRequestedAt
      for (final doc in tripsQuery.docs) {
        final data = doc.data();
        if (data['closureRequestedAt'] != null && data['isClosureApproved'] != true) {
          pendingTrips.add(TripModel.fromMap(doc.id, data));
        }
      }
    }

    // Ordenar por fecha de solicitud de cierre (opcional, en memoria)
    pendingTrips.sort((a, b) {
       final aTime = a.closureRequestedAt;
       final bTime = b.closureRequestedAt;
       if (aTime == null && bTime == null) return 0;
       if (aTime == null) return 1;
       if (bTime == null) return -1;
       return bTime.compareTo(aTime); // Descendente
    });

    return pendingTrips;
  }

  @override
  Future<void> approveTripClosure(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'isClosureApproved': true,
    });
  }

  @override
  Future<TripModel> createTripWithDestination({
    required String companyId,
    required String driverId,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    DateTime? scheduledStartTime,
  }) async {
    final now = DateTime.now();
    final tripData = <String, dynamic>{
      'driverId': driverId,
      'companyId': companyId,
      'startTime': null,
      'endTime': null,
      'hasCameraPermission': false,
      'status': 'pending',
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationAddress': destinationAddress,
      'isOutOfZone': false,
      'createdAt': Timestamp.fromDate(now),
    };

    if (scheduledStartTime != null) {
      tripData['scheduledStartTime'] = Timestamp.fromDate(scheduledStartTime);
    }

    final docRef = await _firestore.collection('trips').add(tripData);

    return TripModel(
      id: docRef.id,
      driverId: driverId,
      startTime: now,
      hasCameraPermission: false,
      status: TripStatus.pending,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      destinationAddress: destinationAddress,
      scheduledStartTime: scheduledStartTime,
    );
  }

  @override
  Future<void> rejectTripClosure(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'status': 'completed',
      'isClosureApproved': false,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}

