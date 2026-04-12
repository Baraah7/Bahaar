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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            title TEXT,
            start_time TEXT NOT NULL,
            end_time TEXT,
            paused_seconds INTEGER DEFAULT 0,
            start_lat REAL,
            start_lon REAL,
            notes TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE catches (
            id TEXT PRIMARY KEY,
            user_id TEXT,
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
        log('DatabaseService: tables created (v3)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE trips ADD COLUMN title TEXT');
          await db.execute(
              'ALTER TABLE trips ADD COLUMN paused_seconds INTEGER DEFAULT 0');
          log('DatabaseService: migrated to v2');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE trips ADD COLUMN user_id TEXT');
          await db.execute('ALTER TABLE catches ADD COLUMN user_id TEXT');
          log('DatabaseService: migrated to v3 (user_id)');
        }
      },
    );
  }

  // ─── Trips ───────────────────────────────────────────────────

  Future<void> insertTrip(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('trips', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('trips', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllTrips({String? userId}) async {
    final db = await database;
    if (userId != null) {
      return db.query('trips',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'start_time DESC');
    }
    return [];
  }

  /// Returns all trips that have no end_time, ordered oldest-first.
  Future<List<Map<String, dynamic>>> getOpenTrips({String? userId}) async {
    final db = await database;
    if (userId != null) {
      return db.query(
        'trips',
        where: 'user_id = ? AND end_time IS NULL',
        whereArgs: [userId],
        orderBy: 'start_time ASC',
      );
    }
    return db.query(
      'trips',
      where: 'end_time IS NULL',
      orderBy: 'start_time ASC',
    );
  }

  Future<Map<String, dynamic>?> getTrip(String id) async {
    final db = await database;
    final rows =
        await db.query('trips', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('catches', where: 'trip_id = ?', whereArgs: [id]);
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTripEndTime(String id) async {
    final db = await database;
    await db.update(
      'trips',
      {'end_time': null, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Catches ─────────────────────────────────────────────────

  Future<void> insertCatch(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('catches', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCatchesForTrip(
      String tripId) async {
    final db = await database;
    return db.query(
      'catches',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> updateCatch(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('catches', values,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCatch(String id) async {
    final db = await database;
    await db.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Unsynced rows for Firestore sync ────────────────────────

  Future<List<Map<String, dynamic>>> getUnsyncedTrips(
      {String? userId}) async {
    final db = await database;
    if (userId != null) {
      return db.query('trips',
          where: 'synced = 0 AND user_id = ?', whereArgs: [userId]);
    }
    return db.query('trips', where: 'synced = 0');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCatches(
      {String? userId}) async {
    final db = await database;
    if (userId != null) {
      return db.query('catches',
          where: 'synced = 0 AND user_id = ?', whereArgs: [userId]);
    }
    return db.query('catches', where: 'synced = 0');
  }

  Future<void> markTripSynced(String id) async {
    final db = await database;
    await db
        .update('trips', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markCatchSynced(String id) async {
    final db = await database;
    await db.update('catches', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Returns the count of trips for a given user (for Firestore seed check).
  Future<int> tripCountForUser(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM trips WHERE user_id = ?', [userId]);
    return result.first['cnt'] as int? ?? 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
