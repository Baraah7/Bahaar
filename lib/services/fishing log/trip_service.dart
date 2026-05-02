import 'dart:developer';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/services/offline/connectivity_service.dart';
import 'package:bahaar/services/offline/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

/// Manages trips and catches via SQLite (offline-first) with Firestore sync.
/// All data is scoped to the currently authenticated user.
class TripService {
  TripService._();
  static final TripService instance = TripService._();

  final _db = DatabaseService.instance;
  final _connectivity = ConnectivityService.instance;
  Trip? _activeTrip;
  bool _initialized = false;
  String? _currentUid;

  Trip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  /// Must be called whenever the authenticated user changes (login / logout).
  /// Re-initializes state scoped to [uid]. Pass null for guest/no user.
  Future<void> initialize({String? uid}) async {
    // Re-initialize if the user has changed
    if (_initialized && _currentUid == uid) return;
    _currentUid = uid;
    _initialized = true;
    _activeTrip = null;

    if (uid == null) return;

    // Restore the active trip for this user from SQLite
    final openRows = await _db.getOpenTrips(userId: uid);
    if (openRows.isNotEmpty) {
      // Close all but the most recent open trip
      final toClose = openRows.sublist(0, openRows.length - 1);
      final now = DateTime.now().toIso8601String();
      for (final row in toClose) {
        await _db.updateTrip(row['id'] as String, {'end_time': now});
        log('TripService: auto-closed orphaned trip ${row['id']}');
      }
      final activeRow = openRows.last;
      final catchRows =
          await _db.getCatchesForTrip(activeRow['id'] as String);
      final catches = catchRows.map(CatchEntry.fromRow).toList();
      _activeTrip = Trip.fromRow(activeRow, catches);
      log('TripService: restored active trip ${_activeTrip!.id}');
    }

    // Seed local SQLite from Firestore if this user has no local data
    final localCount = await _db.tripCountForUser(uid);
    if (localCount == 0 && _connectivity.isOnline) {
      await _seedFromFirestore(uid);
    }
  }

  // ─── Trip CRUD ───────────────────────────────────────────────

  Future<Trip> startTrip({LatLng? location, String? notes}) async {
    if (_activeTrip != null) {
      // Verify the in-memory active trip still exists in the DB (guards against
      // stale state after deletion without a matching deleteTrip call).
      final existing = await _db.getTrip(_activeTrip!.id);
      if (existing == null) {
        log('TripService: clearing stale _activeTrip ${_activeTrip!.id} — not in DB');
        _activeTrip = null;
      } else {
        log('TripService: startTrip blocked — trip ${_activeTrip!.id} already active');
        return _activeTrip!;
      }
    }
    final trip = Trip(
      id: const Uuid().v4(),
      userId: _currentUid,
      startTime: DateTime.now(),
      startLat: location?.latitude,
      startLon: location?.longitude,
      notes: notes,
    );
    await _db.insertTrip(trip.toRow());
    _activeTrip = trip;
    log('TripService: started trip ${trip.id}');
    return trip;
  }

  Future<Trip> resumeTrip(Trip trip) async {
    if (_activeTrip != null && _activeTrip!.id != trip.id) {
      log('TripService: resumeTrip blocked — trip ${_activeTrip!.id} already active');
      return _activeTrip!;
    }
    // Re-fetch from DB so we have the freshest pausedSeconds before computing.
    final freshRow = await _db.getTrip(trip.id);
    final fresh = freshRow != null
        ? Trip.fromRow(freshRow, trip.catches)
        : trip;

    final breakSeconds = fresh.endTime != null
        ? DateTime.now().difference(fresh.endTime!).inSeconds
        : 0;
    final newPaused = fresh.pausedSeconds + breakSeconds;
    await _db.clearTripEndTime(trip.id);
    await _db.updateTrip(trip.id, {'paused_seconds': newPaused});
    final resumed = fresh.copyWith(endTime: null, pausedSeconds: newPaused);
    _activeTrip = resumed;
    log('TripService: resumed trip ${trip.id}, paused so far: ${newPaused}s');
    return resumed;
  }

  Future<Trip> endTrip() async {
    if (_activeTrip == null) throw StateError('No active trip');
    final ended = _activeTrip!.copyWith(endTime: DateTime.now());
    await _db.updateTrip(
        ended.id, {'end_time': ended.endTime!.toIso8601String()});
    _activeTrip = null;

    if (_connectivity.isOnline) {
      await _syncTripToFirestore(ended);
    }
    return ended;
  }

  Future<List<Trip>> getAllTrips() async {
    final rows = await _db.getAllTrips(userId: _currentUid);
    final trips = <Trip>[];
    for (final row in rows) {
      final catchRows =
          await _db.getCatchesForTrip(row['id'] as String);
      final catches = catchRows.map(CatchEntry.fromRow).toList();
      trips.add(Trip.fromRow(row, catches));
    }
    return trips;
  }

  Future<Trip?> getTrip(String id) async {
    final row = await _db.getTrip(id);
    if (row == null) return null;
    final catchRows = await _db.getCatchesForTrip(id);
    final catches = catchRows.map(CatchEntry.fromRow).toList();
    return Trip.fromRow(row, catches);
  }

  Future<void> updateTripStartLocation(String id, LatLng location) async {
    await _db.updateTrip(id, {
      'start_lat': location.latitude,
      'start_lon': location.longitude,
    });
    if (_activeTrip?.id == id) {
      _activeTrip = _activeTrip!.copyWith(
        startLat: location.latitude,
        startLon: location.longitude,
      );
    }
  }

  Future<void> updateTripTitle(String id, String title) async {
    final trimmed = title.trim().isEmpty ? null : title.trim();
    await _db.updateTrip(id, {'title': trimmed});
    if (_activeTrip?.id == id) {
      _activeTrip = _activeTrip!.copyWith(title: trimmed);
    }
  }

  Future<void> deleteTrip(String id) async {
    await _db.deleteTrip(id);
    if (_activeTrip?.id == id) _activeTrip = null;
  }

  // ─── Catch CRUD ──────────────────────────────────────────────

  Future<CatchEntry> logCatch({
    required String tripId,
    required String species,
    LatLng? location,
    double? weightKg,
    String? notes,
    String? imagePath,
    DateTime? timestamp,
  }) async {
    final entry = CatchEntry(
      id: const Uuid().v4(),
      tripId: tripId,
      timestamp: timestamp ?? DateTime.now(),
      species: species,
      weightKg: weightKg,
      latitude: location?.latitude,
      longitude: location?.longitude,
      notes: notes,
      imagePath: imagePath,
    );
    // Include user_id in catch row
    final row = entry.toRow();
    row['user_id'] = _currentUid;
    await _db.insertCatch(row);

    if (_activeTrip?.id == tripId) {
      _activeTrip = _activeTrip!.copyWith(
        catches: [..._activeTrip!.catches, entry],
      );
    }

    log('TripService: logged catch ${entry.id} for trip $tripId');
    return entry;
  }

  Future<void> updateCatch(CatchEntry entry) async {
    await _db.updateCatch(entry.id, {
      'species': entry.species,
      'weight_kg': entry.weightKg,
      'latitude': entry.latitude,
      'longitude': entry.longitude,
      'notes': entry.notes,
      'synced': 0,
    });
  }

  Future<void> deleteCatch(String catchId) async {
    await _db.deleteCatch(catchId);
  }

  // ─── Firestore Sync ──────────────────────────────────────────

  Future<void> syncPendingToFirestore() async {
    if (!_connectivity.isOnline) return;
    final uid = _currentUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final trips = await _db.getUnsyncedTrips(userId: uid);
      for (final row in trips) {
        await _syncTripRowToFirestore(uid, row);
        await _db.markTripSynced(row['id'] as String);
      }

      final catches = await _db.getUnsyncedCatches(userId: uid);
      for (final row in catches) {
        await _syncCatchRowToFirestore(uid, row);
        await _db.markCatchSynced(row['id'] as String);
      }
      log('TripService: sync complete');
    } catch (e) {
      log('TripService: sync failed — $e');
    }
  }

  Future<void> _syncTripToFirestore(Trip trip) async {
    final uid = trip.userId ?? _currentUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(trip.id)
          .set(trip.toJson());
      await _db.markTripSynced(trip.id);
    } catch (e) {
      log('TripService: Firestore trip sync failed — $e');
    }
  }

  Future<void> _syncTripRowToFirestore(
      String uid, Map<String, dynamic> row) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(row['id'] as String)
        .set(Map<String, dynamic>.from(row)..remove('user_id'));
  }

  Future<void> _syncCatchRowToFirestore(
      String uid, Map<String, dynamic> row) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('catches')
        .doc(row['id'] as String)
        .set(Map<String, dynamic>.from(row)..remove('user_id'));
  }

  /// Seeds local SQLite with this user's data from Firestore (first-time
  /// login on a new device or after reinstall).
  Future<void> _seedFromFirestore(String uid) async {
    try {
      // Load catches first (referenced by trips)
      final catchesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('catches')
          .get();
      for (final doc in catchesSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['user_id'] = uid;
        data['synced'] = 1;
        await _db.insertCatch(data);
      }

      // Load trips
      final tripsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .get();
      for (final doc in tripsSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('catches'); // catches stored separately in SQLite
        data['user_id'] = uid;
        data['synced'] = 1;
        // Ensure required fields exist
        if (data['start_time'] == null) continue;
        await _db.insertTrip(data);
      }

      log('TripService: seeded ${tripsSnap.docs.length} trips + '
          '${catchesSnap.docs.length} catches from Firestore for $uid');
    } catch (e) {
      log('TripService: Firestore seed failed — $e');
    }
  }

  /// Loads all catches for the current user from Firestore.
  Future<List<CatchEntry>> fetchCatchesFromFirestore() async {
    final uid = _currentUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('catches')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) => CatchEntry.fromRow(doc.data()))
          .toList();
    } catch (e) {
      log('TripService: fetchCatchesFromFirestore failed — $e');
      return [];
    }
  }
}
