import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain models
// ─────────────────────────────────────────────────────────────────────────────

class Port {
  final int?   id;
  final String name;
  final double lat;
  final double lng;
  final String notes;
  final DateTime createdAt;

  const Port({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.notes = '',
    required this.createdAt,
  });

  Port copyWith({int? id, String? name, double? lat, double? lng, String? notes}) =>
      Port(
        id:        id        ?? this.id,
        name:      name      ?? this.name,
        lat:       lat       ?? this.lat,
        lng:       lng       ?? this.lng,
        notes:     notes     ?? this.notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name':       name,
    'lat':        lat,
    'lng':        lng,
    'notes':      notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory Port.fromMap(Map<String, dynamic> m) => Port(
    id:        m['id'] as int,
    name:      m['name'] as String,
    lat:       (m['lat'] as num).toDouble(),
    lng:       (m['lng'] as num).toDouble(),
    notes:     (m['notes'] as String?) ?? '',
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Persistent metadata about a trip.  Never stores location data.
class TripRecord {
  final int?     id;
  final int      departurePortId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool     active;

  const TripRecord({
    this.id,
    required this.departurePortId,
    required this.startTime,
    this.endTime,
    required this.active,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'departure_port_id': departurePortId,
    'start_time':        startTime.toIso8601String(),
    'end_time':          endTime?.toIso8601String(),
    'active':            active ? 1 : 0,
  };

  factory TripRecord.fromMap(Map<String, dynamic> m) => TripRecord(
    id:               m['id'] as int,
    departurePortId:  m['departure_port_id'] as int,
    startTime:        DateTime.parse(m['start_time'] as String),
    endTime:          m['end_time'] != null
                        ? DateTime.parse(m['end_time'] as String)
                        : null,
    active:           (m['active'] as int) == 1,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Fix type — determines reliability and display badge.
enum FixType {
  gps,         // live GPS fix
  celestial,   // DS-1 celestial fix
  deadReckoning; // computed from last known position + heading + speed

  String get label {
    switch (this) {
      case FixType.gps:          return 'GPS';
      case FixType.celestial:    return 'Celestial';
      case FixType.deadReckoning: return 'DR';
    }
  }
}

/// A single recorded position during a trip.
/// EPHEMERAL — deleted when the trip ends. Never survives a session.
class Waypoint {
  final int?     id;
  final int      tripId;
  final double   lat;
  final double   lng;
  final FixType  fixType;
  final double   accuracyNm;   // estimated position error in nautical miles
  final double?  headingDeg;   // COG at recording time
  final double?  speedKn;      // SOG at recording time
  final DateTime recordedAt;

  const Waypoint({
    this.id,
    required this.tripId,
    required this.lat,
    required this.lng,
    required this.fixType,
    required this.accuracyNm,
    this.headingDeg,
    this.speedKn,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'trip_id':     tripId,
    'lat':         lat,
    'lng':         lng,
    'fix_type':    fixType.name,
    'accuracy_nm': accuracyNm,
    'heading_deg': headingDeg,
    'speed_kn':    speedKn,
    'recorded_at': recordedAt.toIso8601String(),
  };

  factory Waypoint.fromMap(Map<String, dynamic> m) => Waypoint(
    id:          m['id'] as int,
    tripId:      m['trip_id'] as int,
    lat:         (m['lat'] as num).toDouble(),
    lng:         (m['lng'] as num).toDouble(),
    fixType:     FixType.values.firstWhere(
                   (e) => e.name == m['fix_type'],
                   orElse: () => FixType.gps,
                 ),
    accuracyNm:  (m['accuracy_nm'] as num).toDouble(),
    headingDeg:  m['heading_deg'] != null
                   ? (m['heading_deg'] as num).toDouble()
                   : null,
    speedKn:     m['speed_kn'] != null
                   ? (m['speed_kn'] as num).toDouble()
                   : null,
    recordedAt:  DateTime.parse(m['recorded_at'] as String),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TripDatabase — singleton SQLite manager
// ─────────────────────────────────────────────────────────────────────────────

class TripDatabase {
  TripDatabase._();
  static final instance = TripDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'trip_nav.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE ports (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT    NOT NULL,
            lat        REAL    NOT NULL,
            lng        REAL    NOT NULL,
            notes      TEXT    NOT NULL DEFAULT '',
            created_at TEXT    NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE trips (
            id                 INTEGER PRIMARY KEY AUTOINCREMENT,
            departure_port_id  INTEGER NOT NULL REFERENCES ports(id),
            start_time         TEXT    NOT NULL,
            end_time           TEXT,
            active             INTEGER NOT NULL DEFAULT 1
          )
        ''');

        // Waypoints are strictly temporary.
        // A trigger ensures they are purged when the trip is closed.
        await db.execute('''
          CREATE TABLE waypoints (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id     INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
            lat         REAL    NOT NULL,
            lng         REAL    NOT NULL,
            fix_type    TEXT    NOT NULL,
            accuracy_nm REAL    NOT NULL,
            heading_deg REAL,
            speed_kn    REAL,
            recorded_at TEXT    NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_waypoints_trip ON waypoints(trip_id)
        ''');
      },
    );
  }

  // ── Ports (PERMANENT) ─────────────────────────────────────────────────────

  Future<int> insertPort(Port port) async {
    final db = await database;
    return db.insert('ports', port.toMap());
  }

  Future<List<Port>> getAllPorts() async {
    final db = await database;
    final rows = await db.query('ports', orderBy: 'name ASC');
    return rows.map(Port.fromMap).toList();
  }

  Future<Port?> getPort(int id) async {
    final db = await database;
    final rows = await db.query('ports', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Port.fromMap(rows.first);
  }

  Future<void> updatePort(Port port) async {
    assert(port.id != null, 'Cannot update a port without an id');
    final db = await database;
    await db.update('ports', port.toMap(),
        where: 'id = ?', whereArgs: [port.id]);
  }

  /// Deletes a port. Will fail (FK constraint) if an active trip references it.
  Future<void> deletePort(int id) async {
    final db = await database;
    await db.delete('ports', where: 'id = ?', whereArgs: [id]);
  }

  // ── Trips ─────────────────────────────────────────────────────────────────

  Future<TripRecord> startTrip(int departurePortId) async {
    final db = await database;

    // Only one active trip at a time — safety invariant.
    final existing = await db.query('trips',
        where: 'active = 1', limit: 1);
    if (existing.isNotEmpty) {
      throw StateError(
          'DS-1: Cannot start a new trip while one is already active.');
    }

    final rec = TripRecord(
      departurePortId: departurePortId,
      startTime:       DateTime.now().toUtc(),
      active:          true,
    );
    final id = await db.insert('trips', rec.toMap());
    return rec.copyWith(id: id);
  }

  Future<TripRecord?> getActiveTrip() async {
    final db = await database;
    final rows = await db.query('trips', where: 'active = 1', limit: 1);
    return rows.isEmpty ? null : TripRecord.fromMap(rows.first);
  }

  /// Closes the trip AND immediately purges all associated waypoints.
  /// This is the ONLY place where waypoints are deleted — on trip end.
  Future<void> endTrip(int tripId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Purge waypoints first (ephemeral data)
      await txn.delete('waypoints',
          where: 'trip_id = ?', whereArgs: [tripId]);

      // Mark trip closed
      await txn.update(
        'trips',
        {'active': 0, 'end_time': DateTime.now().toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [tripId],
      );
    });
  }

  // ── Waypoints (EPHEMERAL) ─────────────────────────────────────────────────

  Future<int> insertWaypoint(Waypoint wp) async {
    final db = await database;
    return db.insert('waypoints', wp.toMap());
  }

  Future<List<Waypoint>> getWaypoints(int tripId) async {
    final db = await database;
    final rows = await db.query('waypoints',
        where:   'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'recorded_at ASC');
    return rows.map(Waypoint.fromMap).toList();
  }

  /// Emergency purge — call if the app was killed mid-trip on previous launch.
  Future<void> purgeOrphanedWaypoints() async {
    final db = await database;
    await db.rawDelete('''
      DELETE FROM waypoints
      WHERE trip_id IN (
        SELECT id FROM trips WHERE active = 0
      )
    ''');
  }
}

// Extension to allow copyWith on TripRecord
extension TripRecordX on TripRecord {
  TripRecord copyWith({int? id, bool? active, DateTime? endTime}) => TripRecord(
    id:               id       ?? this.id,
    departurePortId:  departurePortId,
    startTime:        startTime,
    endTime:          endTime  ?? this.endTime,
    active:           active   ?? this.active,
  );
}
