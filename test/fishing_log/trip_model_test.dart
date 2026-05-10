import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:latlong2/latlong.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Trip makeTrip({
  String id = 'trip-1',
  String? title,
  DateTime? startTime,
  DateTime? endTime,
  int pausedSeconds = 0,
  double? startLat,
  double? startLon,
  List<CatchEntry> catches = const [],
  String? notes,
  bool synced = false,
}) {
  return Trip(
    id: id,
    startTime: startTime ?? DateTime(2026, 4, 22, 8, 0),
    endTime: endTime,
    title: title,
    pausedSeconds: pausedSeconds,
    startLat: startLat,
    startLon: startLon,
    catches: catches,
    notes: notes,
    synced: synced,
  );
}

CatchEntry makeCatch({
  String id = 'catch-1',
  String tripId = 'trip-1',
  String species = 'Hamour',
  double? weightKg,
  double latitude = 26.2,
  double longitude = 50.5,
  String? notes,
  String? imagePath,
  bool synced = false,
}) {
  return CatchEntry(
    id: id,
    tripId: tripId,
    timestamp: DateTime(2026, 4, 22, 9, 0),
    species: species,
    weightKg: weightKg,
    latitude: latitude,
    longitude: longitude,
    notes: notes,
    imagePath: imagePath,
    synced: synced,
  );
}

void main() {
  // ── Trip.isActive ─────────────────────────────────────────────────────────

  group('Trip.isActive', () {
    test('returns true when endTime is null', () {
      expect(makeTrip(endTime: null).isActive, isTrue);
    });

    test('returns false when endTime is set', () {
      expect(makeTrip(endTime: DateTime(2026, 4, 22, 16, 0)).isActive, isFalse);
    });
  });

  // ── Trip.startLocation ───────────────────────────────────────────────────

  group('Trip.startLocation', () {
    test('returns LatLng when both lat and lon are set', () {
      final t = makeTrip(startLat: 26.2, startLon: 50.5);
      expect(t.startLocation, isNotNull);
      expect(t.startLocation!.latitude, closeTo(26.2, 0.0001));
      expect(t.startLocation!.longitude, closeTo(50.5, 0.0001));
    });

    test('returns null when startLat is null', () {
      expect(makeTrip(startLat: null, startLon: 50.5).startLocation, isNull);
    });

    test('returns null when startLon is null', () {
      expect(makeTrip(startLat: 26.2, startLon: null).startLocation, isNull);
    });

    test('returns null when both are null', () {
      expect(makeTrip().startLocation, isNull);
    });
  });

  // ── Trip.duration ─────────────────────────────────────────────────────────

  group('Trip.duration', () {
    test('computes net duration by subtracting pausedSeconds', () {
      final start = DateTime(2026, 4, 22, 8, 0);
      final end = DateTime(2026, 4, 22, 10, 0); // 2 hours raw
      final t = makeTrip(startTime: start, endTime: end, pausedSeconds: 1800);
      // 7200 - 1800 = 5400 s = 90 min
      expect(t.duration.inMinutes, 90);
    });

    test('returns Duration.zero when paused time exceeds raw duration', () {
      final start = DateTime(2026, 4, 22, 8, 0);
      final end = DateTime(2026, 4, 22, 8, 30); // 30 min raw
      final t = makeTrip(startTime: start, endTime: end, pausedSeconds: 3600);
      expect(t.duration, Duration.zero);
    });

    test('is positive for active trip (uses DateTime.now as end)', () {
      final t = makeTrip(
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: null,
      );
      expect(t.duration.inSeconds, greaterThan(0));
    });

    test('returns zero duration when pausedSeconds equals raw duration exactly', () {
      final start = DateTime(2026, 4, 22, 8, 0);
      final end = DateTime(2026, 4, 22, 9, 0); // 3600 s raw
      final t = makeTrip(startTime: start, endTime: end, pausedSeconds: 3600);
      expect(t.duration, Duration.zero);
    });
  });

  // ── Trip.totalWeightKg ────────────────────────────────────────────────────

  group('Trip.totalWeightKg', () {
    test('returns 0 when catches list is empty', () {
      expect(makeTrip().totalWeightKg, 0.0);
    });

    test('sums weight of all catches', () {
      final catches = [
        makeCatch(id: 'c1', weightKg: 1.5),
        makeCatch(id: 'c2', weightKg: 2.0),
        makeCatch(id: 'c3', weightKg: 0.8),
      ];
      expect(makeTrip(catches: catches).totalWeightKg, closeTo(4.3, 0.0001));
    });

    test('ignores catches with null weightKg', () {
      final catches = [
        makeCatch(id: 'c1', weightKg: 2.0),
        makeCatch(id: 'c2', weightKg: null),
      ];
      expect(makeTrip(catches: catches).totalWeightKg, closeTo(2.0, 0.0001));
    });

    test('returns 0 when all catches have null weight', () {
      final catches = [
        makeCatch(id: 'c1', weightKg: null),
        makeCatch(id: 'c2', weightKg: null),
      ];
      expect(makeTrip(catches: catches).totalWeightKg, 0.0);
    });
  });

  // ── Trip.copyWith ─────────────────────────────────────────────────────────

  group('Trip.copyWith', () {
    test('updates title without affecting other fields', () {
      final t = makeTrip(startLat: 26.2, startLon: 50.5);
      final copy = t.copyWith(title: 'Morning Run');
      expect(copy.title, 'Morning Run');
      expect(copy.startLat, t.startLat);
      expect(copy.startLon, t.startLon);
      expect(copy.id, t.id);
    });

    test('sets endTime independently', () {
      final t = makeTrip(endTime: null);
      final end = DateTime(2026, 4, 22, 17, 0);
      final copy = t.copyWith(endTime: end);
      expect(copy.endTime, end);
      expect(copy.startTime, t.startTime);
    });

    test('updates synced flag independently', () {
      final t = makeTrip(synced: false);
      expect(t.copyWith(synced: true).synced, isTrue);
    });

    test('copyWith with no args returns identical values', () {
      final t = makeTrip(title: 'Test', pausedSeconds: 300, synced: true);
      final copy = t.copyWith();
      expect(copy.title, t.title);
      expect(copy.pausedSeconds, t.pausedSeconds);
      expect(copy.synced, t.synced);
    });
  });

  // ── Trip.toRow / fromRow ──────────────────────────────────────────────────

  group('Trip.toRow / fromRow', () {
    test('toRow serializes synced as 1 for true', () {
      final row = makeTrip(synced: true).toRow();
      expect(row['synced'], 1);
    });

    test('toRow serializes synced as 0 for false', () {
      final row = makeTrip(synced: false).toRow();
      expect(row['synced'], 0);
    });

    test('toRow serializes startTime as ISO 8601 string', () {
      final t = makeTrip(startTime: DateTime(2026, 4, 22, 8, 0));
      expect(t.toRow()['start_time'], isA<String>());
      expect(() => DateTime.parse(t.toRow()['start_time'] as String), returnsNormally);
    });

    test('toRow serializes endTime as null when not set', () {
      final row = makeTrip(endTime: null).toRow();
      expect(row['end_time'], isNull);
    });

    test('fromRow roundtrip preserves id, title, pausedSeconds, synced', () {
      final original = makeTrip(
        id: 'trip-abc',
        title: 'Evening',
        pausedSeconds: 600,
        synced: true,
        startLat: 26.1,
        startLon: 50.4,
      );
      final restored = Trip.fromRow(original.toRow(), []);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.pausedSeconds, original.pausedSeconds);
      expect(restored.synced, original.synced);
      expect(restored.startLat, original.startLat);
      expect(restored.startLon, original.startLon);
    });

    test('fromRow sets synced=false when row value is 0', () {
      final row = makeTrip(synced: false).toRow();
      final restored = Trip.fromRow(row, []);
      expect(restored.synced, isFalse);
    });

    test('fromRow defaults pausedSeconds to 0 when missing from row', () {
      final row = makeTrip().toRow()..remove('paused_seconds');
      final restored = Trip.fromRow(row, []);
      expect(restored.pausedSeconds, 0);
    });
  });

  // ── Trip.toJson ───────────────────────────────────────────────────────────

  group('Trip.toJson', () {
    test('omits title when null', () {
      final json = makeTrip(title: null).toJson();
      expect(json.containsKey('title'), isFalse);
    });

    test('includes title when set', () {
      final json = makeTrip(title: 'Night Run').toJson();
      expect(json['title'], 'Night Run');
    });

    test('omits endTime when null', () {
      final json = makeTrip(endTime: null).toJson();
      expect(json.containsKey('end_time'), isFalse);
    });

    test('omits notes when null', () {
      final json = makeTrip(notes: null).toJson();
      expect(json.containsKey('notes'), isFalse);
    });

    test('includes catches array', () {
      final json = makeTrip(catches: [makeCatch()]).toJson();
      final catchList = json['catches'] as List;
      expect(catchList.length, 1);
    });

    test('catches list is empty when no catches', () {
      final json = makeTrip().toJson();
      expect((json['catches'] as List).isEmpty, isTrue);
    });
  });

  // ── CatchEntry.location ───────────────────────────────────────────────────

  group('CatchEntry.location', () {
    test('returns LatLng with correct lat/lon', () {
      final entry = makeCatch(latitude: 26.3, longitude: 50.6);
      final loc = entry.location;
      expect(loc, isA<LatLng>());
      expect(loc!.latitude, closeTo(26.3, 0.0001));
      expect(loc.longitude, closeTo(50.6, 0.0001));
    });
  });

  // ── CatchEntry.toRow / fromRow ────────────────────────────────────────────

  group('CatchEntry.toRow / fromRow', () {
    test('toRow serializes synced as 1 for true', () {
      final row = makeCatch(synced: true).toRow();
      expect(row['synced'], 1);
    });

    test('toRow serializes synced as 0 for false', () {
      final row = makeCatch(synced: false).toRow();
      expect(row['synced'], 0);
    });

    test('toRow serializes timestamp as ISO 8601 string', () {
      final entry = makeCatch();
      final ts = entry.toRow()['timestamp'] as String;
      expect(() => DateTime.parse(ts), returnsNormally);
    });

    test('fromRow roundtrip preserves species, weight, lat, lon', () {
      final original = makeCatch(
        id: 'c-99',
        species: 'Zubaidi',
        weightKg: 3.25,
        latitude: 26.15,
        longitude: 50.42,
      );
      final restored = CatchEntry.fromRow(original.toRow());
      expect(restored.id, original.id);
      expect(restored.species, original.species);
      expect(restored.weightKg, closeTo(3.25, 0.0001));
      expect(restored.latitude, closeTo(26.15, 0.0001));
      expect(restored.longitude, closeTo(50.42, 0.0001));
    });

    test('fromRow defaults synced to false when missing', () {
      final row = makeCatch().toRow()..remove('synced');
      final restored = CatchEntry.fromRow(row);
      expect(restored.synced, isFalse);
    });

    test('fromRow preserves null weightKg', () {
      final row = makeCatch(weightKg: null).toRow();
      final restored = CatchEntry.fromRow(row);
      expect(restored.weightKg, isNull);
    });
  });

  // ── CatchEntry.toJson ─────────────────────────────────────────────────────

  group('CatchEntry.toJson', () {
    test('omits weightKg when null', () {
      final json = makeCatch(weightKg: null).toJson();
      expect(json.containsKey('weight_kg'), isFalse);
    });

    test('includes weightKg when set', () {
      final json = makeCatch(weightKg: 1.8).toJson();
      expect(json['weight_kg'], closeTo(1.8, 0.0001));
    });

    test('omits notes when null', () {
      final json = makeCatch(notes: null).toJson();
      expect(json.containsKey('notes'), isFalse);
    });

    test('includes notes when set', () {
      final json = makeCatch(notes: 'Large one').toJson();
      expect(json['notes'], 'Large one');
    });

    test('omits imagePath when null', () {
      final json = makeCatch(imagePath: null).toJson();
      expect(json.containsKey('image_path'), isFalse);
    });

    test('timestamp serialized as ISO 8601 string', () {
      final json = makeCatch().toJson();
      expect(() => DateTime.parse(json['timestamp'] as String), returnsNormally);
    });
  });
}
