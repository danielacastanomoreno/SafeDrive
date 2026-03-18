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
    // Check for existing active trips
    final existing = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw const TripAlreadyActiveException();
    }

    // Check for pending trips - accept the first one
    final pending = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (pending.docs.isNotEmpty) {
      // Accept the pending trip - change status to active
      final docRef = pending.docs.first.reference;
      final now = DateTime.now();
      await docRef.update({
        'startTime': Timestamp.fromDate(now),
        'hasCameraPermission': hasCameraPermission,
        'status': 'active',
      });

      final data = pending.docs.first.data();
      return TripModel(
        id: docRef.id,
        driverId: driverId,
        startTime: now,
        hasCameraPermission: hasCameraPermission,
        status: TripStatus.active,
      );
    }

    // No existing trip - create a new one
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
  Future<TripModel> endTripWithZoneCheck({
    required String tripId,
    required double currentLat,
    required double currentLng,
  }) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists) {
      throw DocumentNotFoundException('No se encontró el viaje $tripId.');
    }

    final data = doc.data()!;
    final destinationLat = data['destinationLat'] as double?;
    final destinationLng = data['destinationLng'] as double?;

    final now = DateTime.now();

    if (destinationLat != null && destinationLng != null) {
      final distance = _calculateDistance(
        currentLat,
        currentLng,
        destinationLat,
        destinationLng,
      );

      const double zoneRadiusMeters = 100;

      if (distance <= zoneRadiusMeters) {
        await _firestore.collection('trips').doc(tripId).update({
          'endTime': Timestamp.fromDate(now),
          'status': 'completed',
          'isOutOfZone': false,
        });

        return TripModel(
          id: tripId,
          driverId: data['driverId'] as String,
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: now,
          hasCameraPermission: data['hasCameraPermission'] as bool? ?? false,
          status: TripStatus.completed,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          isOutOfZone: false,
        );
      } else {
        await _firestore.collection('trips').doc(tripId).update({
          'endTime': Timestamp.fromDate(now),
          'status': 'pendingApproval',
          'isOutOfZone': true,
        });

        return TripModel(
          id: tripId,
          driverId: data['driverId'] as String,
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: now,
          hasCameraPermission: data['hasCameraPermission'] as bool? ?? false,
          status: TripStatus.pendingApproval,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          destinationAddress: data['destinationAddress'] as String?,
          isOutOfZone: true,
        );
      }
    }

    await _firestore.collection('trips').doc(tripId).update({
      'endTime': Timestamp.fromDate(now),
      'status': 'completed',
    });

    return TripModel(
      id: tripId,
      driverId: data['driverId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: now,
      hasCameraPermission: data['hasCameraPermission'] as bool? ?? false,
      status: TripStatus.completed,
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorCos(x);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approxAtan2(y, x);

  double _taylorSin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _taylorCos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approxAtan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return 3.141592653589793 / 2;
      if (y < 0) return -3.141592653589793 / 2;
      return 0;
    }
    double atan = _approxAtan(y / x);
    if (x < 0) {
      if (y >= 0) return atan + 3.141592653589793;
      return atan - 3.141592653589793;
    }
    return atan;
  }

  double _approxAtan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * (3.141592653589793 / 2 - _approxAtan(1 / x));
    }
    double result = x;
    double term = x;
    for (int i = 1; i <= 20; i++) {
      term *= -x * x;
      result += term / (2 * i + 1);
    }
    return result;
  }

  @override
  Future<TripModel?> getActiveTrip(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return TripModel.fromMap(doc.id, doc.data());
    }

    final pendingSnapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (pendingSnapshot.docs.isNotEmpty) {
      final doc = pendingSnapshot.docs.first;
      return TripModel.fromMap(doc.id, doc.data());
    }

    return null;
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

  @override
  Future<List<TripModel>> getDriverTrips(String driverId) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // --- Cierre de viaje ---

  @override
  Future<void> requestRemoteClosure(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'closureRequestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Error solicitando cierre remoto: $e');
    }
  }

  @override
  Stream<TripModel> listenToApprovalStream(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) throw const ServerException('El viaje no existe.');
      return TripModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  @override
  Stream<List<TripModel>> listenToPendingTrips(String driverId) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.id, doc.data()))
            .toList());
  }
}
