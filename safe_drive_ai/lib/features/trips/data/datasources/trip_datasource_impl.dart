import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/trip_entity.dart';
import '../models/route_point_model.dart';
import '../models/trip_model.dart';
import 'trip_datasource.dart';

class TripDatasourceImpl implements TripDatasource {
  const TripDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<TripModel> startTrip({
    required String driverId,
    required bool hasCameraPermission,
  }) async {
    final existing = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const TripAlreadyActiveException();
    }

    final now = DateTime.now();
    final docRef = await _firestore.collection('trips').add({
      'driverId': driverId,
      'startTime': Timestamp.fromDate(now),
      'endTime': null,
      'hasCameraPermission': hasCameraPermission,
      'status': 'active',
    });

    return TripModel(
      id: docRef.id,
      driverId: driverId,
      startTime: now,
      hasCameraPermission: hasCameraPermission,
      status: TripStatus.active,
    );
  }

  @override
  Future<TripModel> endTrip(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final now = DateTime.now();
    await _firestore.collection('trips').doc(tripId).update({
      'endTime': Timestamp.fromDate(now),
      'status': 'completed',
    });

    final data = doc.data()!;
    return TripModel(
      id: tripId,
      driverId: data['driverId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: now,
      hasCameraPermission: data['hasCameraPermission'] as bool? ?? false,
      status: TripStatus.completed,
    );
  }

  @override
  Future<TripModel?> getActiveTrip(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return TripModel.fromMap(doc.id, doc.data());
  }

  @override
  Future<void> saveRoutePoint({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('route_points')
        .add({
      'lat': lat,
      'lng': lng,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<RoutePointModel>> getTripRoute(String tripId) async {
    final snapshot = await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('route_points')
        .orderBy('recordedAt')
        .get();
    return snapshot.docs
        .map((doc) => RoutePointModel.fromMap(doc.data()))
        .toList();
  }
}
