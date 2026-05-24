import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

/// Status of an SOS submission attempt.
enum SosStatus { sending, sent, failed, acknowledged }

/// A single SOS alert record.
class SosAlert {
  final String id;
  final String userId;
  final LatLng position;
  final double? heading;
  final int? batteryPercent;
  final DateTime timestamp;
  SosStatus status;

  SosAlert({
    required this.id,
    required this.userId,
    required this.position,
    this.heading,
    this.batteryPercent,
    required this.timestamp,
    this.status = SosStatus.sending,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': heading,
        'batteryPercent': batteryPercent,
        'timestamp': Timestamp.fromDate(timestamp),
        'status': 'active',
        'resolved': false,
      };
}

/// Service that sends SOS alerts to Firebase Firestore with retry logic.
///
/// On success the document is written to the `sos_alerts` collection.
/// On failure it retries up to [maxRetries] times with exponential back-off.
class SosService {
  static const String _collection = 'sos_alerts';
  static const int maxRetries = 4;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SosService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Send an SOS alert for [position].
  ///
  /// Returns the created [SosAlert] with its final status.
  Future<SosAlert> sendSos({
    required LatLng position,
    double? heading,
    int? batteryPercent,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final alert = SosAlert(
      id: '',
      userId: userId,
      position: position,
      heading: heading,
      batteryPercent: batteryPercent,
      timestamp: DateTime.now(),
    );

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final ref = await _firestore
            .collection(_collection)
            .add(alert.toFirestore());
        alert.status = SosStatus.sent;
        log('SOS sent successfully: ${ref.id}');
        return alert;
      } catch (e) {
        log('SOS attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries) {
          // Exponential back-off: 1s, 2s, 4s, 8s
          final delay = Duration(seconds: 1 << attempt);
          await Future.delayed(delay);
        }
      }
    }

    alert.status = SosStatus.failed;
    log('SOS failed after $maxRetries retries');
    return alert;
  }

  /// Mark an SOS alert as resolved (acknowledged by rescue services).
  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection(_collection).doc(alertId).update({
        'resolved': true,
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      log('Failed to resolve SOS alert: $e');
    }
  }
}
