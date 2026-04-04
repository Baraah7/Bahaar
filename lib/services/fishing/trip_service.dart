import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:Bahaar/models/fishing/trip_model.dart';
import 'package:Bahaar/services/offline/database_service.dart';
import 'package:Bahaar/services/offline/connectivity_service.dart';

/// Manages trips and catches via SQLite (offline-first) with Firestore sync.
class TripService {
  TripService._();
  static final TripService instance = TripService._();

  final _db = DatabaseService.instance;
  final _connectivity = ConnectivityService.instance;
  Trip? _activeTrip;
  bool _initialized = false;

  Trip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  /// Must be called once before using the service (e.g. on app start).
  /// Restores the active trip from SQLite and cleans up any orphaned open trips.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final openRows = await _db.getOpenTrips();
    if (openRows.isEmpty) return;

    // Close all but the most recent open trip (oldest-first order, so last = newest)
    final toClose = openRows.sublist(0, openRows.length - 1);
    final now = DateTime.now().toIso8601String();
    for (final row in toClose) {
      await _db.updateTrip(row['id'] as String, {'end_time': now});
      log('TripService: auto-closed orphaned trip ${row['id']}');
    }

    // Restore the most recent open trip as the active trip
    final activeRow = openRows.last;
    final catchRows = await _db.getCatchesForTrip(activeRow['id'] as String);
    final catches = catchRows.map(CatchEntry.fromRow).toList();
    _activeTrip = Trip.fromRow(activeRow, catches);
    log('TripService: restored active trip ${_activeTrip!.id}');
  }

  // ─── Trip CRUD ───────────────────────────────────────────────

  Future<Trip> startTrip({LatLng? location, String? notes}) async {
    // Block starting a second session while one is active
    if (_activeTrip != null) {
      log('TripService: startTrip blocked — trip ${_activeTrip!.id} already active');
      return _activeTrip!;
    }
    final trip = Trip(
      id: const Uuid().v4(),
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

  /// Re-open a finished trip. Records the break duration so it is excluded
  /// from the active fishing time shown to the user.
  Future<Trip> resumeTrip(Trip trip) async {
    // Block resuming if another trip is already active
    if (_activeTrip != null && _activeTrip!.id != trip.id) {
      log('TripService: resumeTrip blocked — trip ${_activeTrip!.id} already active');
      return _activeTrip!;
    }
    // Calculate how long the trip was paused and add to existing pausedSeconds
    final breakSeconds = trip.endTime != null
        ? DateTime.now().difference(trip.endTime!).inSeconds
        : 0;
    final newPaused = trip.pausedSeconds + breakSeconds;
    await _db.clearTripEndTime(trip.id);
    await _db.updateTrip(trip.id, {'paused_seconds': newPaused});
    final resumed = trip.copyWith(endTime: null, pausedSeconds: newPaused);
    _activeTrip = resumed;
    log('TripService: resumed trip ${trip.id}, paused so far: ${newPaused}s');
    return resumed;
  }

  Future<Trip> endTrip() async {
    if (_activeTrip == null) throw StateError('No active trip');
    final ended = _activeTrip!.copyWith(endTime: DateTime.now());
    await _db.updateTrip(ended.id, {'end_time': ended.endTime!.toIso8601String()});
    _activeTrip = null;

    if (_connectivity.isOnline) {
      await _syncTripToFirestore(ended);
    }
    return ended;
  }

  Future<List<Trip>> getAllTrips() async {
    final rows = await _db.getAllTrips();
    final trips = <Trip>[];
    for (final row in rows) {
      final catchRows = await _db.getCatchesForTrip(row['id'] as String);
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

  Future<void> updateTripTitle(String id, String title) async {
    await _db.updateTrip(id, {'title': title.trim().isEmpty ? null : title.trim()});
    if (_activeTrip?.id == id) {
      _activeTrip = _activeTrip!.copyWith(title: title.trim().isEmpty ? null : title.trim());
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
    required LatLng location,
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
      latitude: location.latitude,
      longitude: location.longitude,
      notes: notes,
      imagePath: imagePath,
    );
    await _db.insertCatch(entry.toRow());

    // Update active trip catches list in memory
    if (_activeTrip?.id == tripId) {
      final updated = _activeTrip!.copyWith(
        catches: [..._activeTrip!.catches, entry],
      );
      _activeTrip = updated;
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final trips = await _db.getUnsyncedTrips();
      for (final row in trips) {
        await _syncTripRowToFirestore(uid, row);
        await _db.markTripSynced(row['id'] as String);
      }

      final catches = await _db.getUnsyncedCatches();
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
        .set(row);
  }

  Future<void> _syncCatchRowToFirestore(
      String uid, Map<String, dynamic> row) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('catches')
        .doc(row['id'] as String)
        .set(row);
  }

  /// Loads all catches for the current user from Firestore.
  /// Returns an empty list if not authenticated or on error.
  Future<List<CatchEntry>> fetchCatchesFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
