import 'dart:developer';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite singleton for offline trip and catch storage.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bahaar.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id TEXT PRIMARY KEY,
            start_time TEXT NOT NULL,
            end_time TEXT,
            start_lat REAL,
            start_lon REAL,
            notes TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE catches (
            id TEXT PRIMARY KEY,
            trip_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            species TEXT NOT NULL,
            weight_kg REAL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            notes TEXT,
            image_path TEXT,
            synced INTEGER DEFAULT 0,
            FOREIGN KEY (trip_id) REFERENCES trips(id)
          )
        ''');
        log('DatabaseService: tables created');
      },
    );
  }

  // ─── Trips ───────────────────────────────────────────────────

  Future<void> insertTrip(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('trips', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('trips', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllTrips() async {
    final db = await database;
    return db.query('trips', orderBy: 'start_time DESC');
  }

<<<<<<< HEAD
=======
  /// Returns all trips that have no end_time, ordered oldest-first.
  Future<List<Map<String, dynamic>>> getOpenTrips() async {
    final db = await database;
    return db.query(
      'trips',
      where: 'end_time IS NULL',
      orderBy: 'start_time ASC',
    );
  }

>>>>>>> origin/exp
  Future<Map<String, dynamic>?> getTrip(String id) async {
    final db = await database;
    final rows = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('catches', where: 'trip_id = ?', whereArgs: [id]);
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

<<<<<<< HEAD
=======
  Future<void> clearTripEndTime(String id) async {
    final db = await database;
    await db.update(
      'trips',
      {'end_time': null, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

>>>>>>> origin/exp
  // ─── Catches ─────────────────────────────────────────────────

  Future<void> insertCatch(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('catches', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCatchesForTrip(String tripId) async {
    final db = await database;
    return db.query(
      'catches',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

<<<<<<< HEAD
=======
  Future<void> updateCatch(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('catches', values, where: 'id = ?', whereArgs: [id]);
  }

>>>>>>> origin/exp
  Future<void> deleteCatch(String id) async {
    final db = await database;
    await db.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Unsynced rows for Firestore sync ────────────────────────

  Future<List<Map<String, dynamic>>> getUnsyncedTrips() async {
    final db = await database;
    return db.query('trips', where: 'synced = 0');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCatches() async {
    final db = await database;
    return db.query('catches', where: 'synced = 0');
  }

  Future<void> markTripSynced(String id) async {
    final db = await database;
    await db.update('trips', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markCatchSynced(String id) async {
    final db = await database;
    await db.update('catches', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
