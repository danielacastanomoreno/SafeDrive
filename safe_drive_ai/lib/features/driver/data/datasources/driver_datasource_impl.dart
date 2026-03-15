import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../auth/data/models/company_link_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../company/data/models/invitation_model.dart';
import 'driver_datasource.dart';

class DriverDatasourceImpl implements DriverDatasource {
  const DriverDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // ── Invitaciones ────────────────────────────────────────────────────────────

  @override
  Future<List<InvitationModel>> getDriverInvitations(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('invitations')
          .where('driverId', isEqualTo: driverId)
          .orderBy('sentAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      // El índice compuesto puede no existir aún en Firestore.
      // Se retrocede a query sin orderBy y se ordena en memoria.
      final snapshot = await _firestore
          .collection('invitations')
          .where('driverId', isEqualTo: driverId)
          .get();

      final models = snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return models;
    }
  }

  @override
  Future<void> acceptInvitation({
    required String invitationId,
    required String companyId,
    required String companyName,
    required String driverId,
    required String cargo,
    required String phone,
  }) async {
    final batch = _firestore.batch();

    // 1. Marcar invitación como aceptada
    final invitationRef =
        _firestore.collection('invitations').doc(invitationId);
    batch.update(invitationRef, {
      'status': 'accepted',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // 2. Crear vínculo activo en company_drivers
    final linkRef = _firestore.collection('company_drivers').doc();
    batch.set(linkRef, {
      'companyId': companyId,
      'driverId': driverId,
      'cargo': cargo,
      'phone': phone,
      'status': 'active',
      'linkedAt': FieldValue.serverTimestamp(),
      'unlinkedAt': null,
    });

    await batch.commit();
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'rejected',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Empresas vinculadas ──────────────────────────────────────────────────────

  @override
  Future<List<CompanyLinkModel>> getDriverLinkedCompanies(
    String driverId,
  ) async {
    final snapshot = await _firestore
        .collection('company_drivers')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .get();

    final List<CompanyLinkModel> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final companyId = data['companyId'] as String;

      String companyName = '';
      try {
        final companyDoc =
            await _firestore.collection('companies').doc(companyId).get();
        if (companyDoc.exists) {
          companyName = companyDoc.data()!['name'] as String? ?? '';
        }
      } catch (_) {
        companyName = '';
      }

      result.add(CompanyLinkModel.fromMap(doc.id, data, companyName));
    }

    return result;
  }

  // ── Perfil conductor ─────────────────────────────────────────────────────────

  @override
  Future<UserModel> updateDriverProfile({
    required String driverId,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(driverId).update({
      'name': name,
      'phone': phone,
    });

    final doc = await _firestore.collection('users').doc(driverId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException(
        'No se encontró el perfil del conductor $driverId.',
      );
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }
}
