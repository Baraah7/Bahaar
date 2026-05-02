import 'package:latlong2/latlong.dart';

class Trip {
  final String id;
  final String? userId;
  final String? title;
  final DateTime startTime;
  final DateTime? endTime;
  final int pausedSeconds; // total seconds spent paused (breaks)
  final double? startLat;
  final double? startLon;
  final List<CatchEntry> catches;
  final String? notes;
  final bool synced;

  const Trip({
    required this.id,
    this.userId,
    this.title,
    required this.startTime,
    this.endTime,
    this.pausedSeconds = 0,
    this.startLat,
    this.startLon,
    this.catches = const [],
    this.notes,
    this.synced = false,
  });

  LatLng? get startLocation =>
      startLat != null && startLon != null ? LatLng(startLat!, startLon!) : null;

  bool get isActive => endTime == null;

  /// Active fishing duration, excluding paused breaks.
  Duration get duration {
    final end = endTime ?? DateTime.now();
    final raw = end.difference(startTime);
    final paused = Duration(seconds: pausedSeconds);
    final net = raw - paused;
    return net.isNegative ? Duration.zero : net;
  }

  double get totalWeightKg => catches.fold(0, (sum, c) => sum + (c.weightKg ?? 0));

  Trip copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? pausedSeconds,
    double? startLat,
    double? startLon,
    List<CatchEntry>? catches,
    String? notes,
    bool? synced,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      startLat: startLat ?? this.startLat,
      startLon: startLon ?? this.startLon,
      catches: catches ?? this.catches,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'paused_seconds': pausedSeconds,
        'start_lat': startLat,
        'start_lon': startLon,
        'notes': notes,
        'synced': synced ? 1 : 0,
      };

  factory Trip.fromRow(Map<String, dynamic> row, List<CatchEntry> catches) {
    return Trip(
      id: row['id'] as String,
      userId: row['user_id'] as String?,
      title: row['title'] as String?,
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: row['end_time'] != null
          ? DateTime.parse(row['end_time'] as String)
          : null,
      pausedSeconds: row['paused_seconds'] as int? ?? 0,
      startLat: row['start_lat'] as double?,
      startLon: row['start_lon'] as double?,
      notes: row['notes'] as String?,
      catches: catches,
      synced: (row['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        'paused_seconds': pausedSeconds,
        if (startLat != null) 'start_lat': startLat,
        if (startLon != null) 'start_lon': startLon,
        if (notes != null) 'notes': notes,
        'catches': catches.map((c) => c.toJson()).toList(),
      };
}

class CatchEntry {
  final String id;
  final String tripId;
  final DateTime timestamp;
  final String species;
  final double? weightKg;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? imagePath;
  final bool synced;

  const CatchEntry({
    required this.id,
    required this.tripId,
    required this.timestamp,
    required this.species,
    this.weightKg,
    this.latitude,
    this.longitude,
    this.notes,
    this.imagePath,
    this.synced = false,
  });

  LatLng? get location =>
      latitude != null && longitude != null ? LatLng(latitude!, longitude!) : null;

  Map<String, dynamic> toRow() => {
        'id': id,
        'trip_id': tripId,
        'timestamp': timestamp.toIso8601String(),
        'species': species,
        'weight_kg': weightKg,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'image_path': imagePath,
        'synced': synced ? 1 : 0,
      };

  factory CatchEntry.fromRow(Map<String, dynamic> row) {
    return CatchEntry(
      id: row['id'] as String,
      tripId: row['trip_id'] as String,
      timestamp: DateTime.parse(row['timestamp'] as String),
      species: row['species'] as String,
      weightKg: row['weight_kg'] as double?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      notes: row['notes'] as String?,
      imagePath: row['image_path'] as String?,
      synced: (row['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'timestamp': timestamp.toIso8601String(),
        'species': species,
        if (weightKg != null) 'weight_kg': weightKg,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
        if (imagePath != null) 'image_path': imagePath,
      };
}
