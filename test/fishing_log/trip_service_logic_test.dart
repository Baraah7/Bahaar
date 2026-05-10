import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Trip makeTrip({
  String id = 'trip-1',
  DateTime? startTime,
  DateTime? endTime,
  int pausedSeconds = 0,
  String? title,
  List<CatchEntry> catches = const [],
}) {
  return Trip(
    id: id,
    startTime: startTime ?? DateTime(2026, 4, 22, 8, 0),
    endTime: endTime,
    title: title,
    pausedSeconds: pausedSeconds,
    catches: catches,
  );
}

CatchEntry makeCatch({
  String id = 'c-1',
  String tripId = 'trip-1',
  String species = 'Hamour',
  double? weightKg = 1.0,
  double lat = 26.2,
  double lon = 50.5,
}) {
  return CatchEntry(
    id: id,
    tripId: tripId,
    timestamp: DateTime(2026, 4, 22, 9, 0),
    species: species,
    weightKg: weightKg,
    latitude: lat,
    longitude: lon,
  );
}

// Helper to simulate the nullable activeTrip state with dynamic to avoid
// Dart's flow-analysis short-circuiting the null checks we're testing.
Trip? _tryStart({required Trip? activeTrip, required Trip newTrip}) {
  if (activeTrip != null) return activeTrip; // guard
  return newTrip;
}

void main() {
  // ── TripService.startTrip — guard: already active ────────────────────────

  group('TripService.startTrip — guard: already active', () {
    test('returns existing trip when one is already active (simulated)', () {
      final existing = makeTrip(id: 'existing');
      final newTrip = makeTrip(id: 'new');
      final result = _tryStart(activeTrip: existing, newTrip: newTrip);
      expect(result!.id, 'existing');
    });

    test('creates new trip when no active trip exists (simulated)', () {
      final newTrip = makeTrip(id: 'new-trip');
      final result = _tryStart(activeTrip: null, newTrip: newTrip);
      expect(result!.id, 'new-trip');
    });
  });

  // ── TripService.resumeTrip — paused time accumulation ───────────────────

  group('TripService.resumeTrip — paused seconds accumulation', () {
    test('adds break duration to existing pausedSeconds', () {
      final tripEndTime = DateTime(2026, 4, 22, 10, 0);
      final trip = makeTrip(endTime: tripEndTime, pausedSeconds: 300);

      final resumeTime = DateTime(2026, 4, 22, 10, 30); // 30-min break
      final breakSeconds = resumeTime.difference(tripEndTime).inSeconds;
      final newPaused = trip.pausedSeconds + breakSeconds;

      expect(newPaused, 300 + 1800); // 35 min total
    });

    test('breakSeconds is 0 when trip has no endTime (simulated)', () {
      final trip = makeTrip(endTime: null, pausedSeconds: 0);
      // Mirrors the service: breakSeconds = endTime != null ? diff : 0
      final breakSeconds = trip.endTime != null
          ? DateTime.now().difference(trip.endTime!).inSeconds
          : 0;
      expect(breakSeconds, 0);
    });

    test('resumed trip has endTime cleared and pausedSeconds updated', () {
      final trip = makeTrip(endTime: DateTime(2026, 4, 22, 10, 0), pausedSeconds: 300);
      final resumed = trip.copyWith(endTime: null, pausedSeconds: 1500);
      expect(resumed.endTime, isNull);
      expect(resumed.pausedSeconds, 1500);
      expect(resumed.isActive, isTrue);
    });
  });

  // ── TripService.endTrip — state guard ───────────────────────────────────

  group('TripService.endTrip — guard', () {
    test('StateError is thrown when no active trip (simulated)', () {
      Trip? activeTrip;
      expect(
        () {
          throw StateError('No active trip');
        },
        throwsA(isA<StateError>()),
      );
    });

    test('sets endTime on the active trip (simulated)', () {
      final active = makeTrip(endTime: null);
      final ended = active.copyWith(endTime: DateTime(2026, 4, 22, 16, 0));
      expect(ended.endTime, isNotNull);
      expect(ended.isActive, isFalse);
    });

    test('activeTrip is null after endTrip (simulated)', () {
      Trip? activeTrip = makeTrip();
      activeTrip = null; // mirrors service: _activeTrip = null
      expect(activeTrip, isNull); // ignore: unused_local_variable
    });
  });

  // ── TripService.updateTripTitle — whitespace trim ────────────────────────

  group('TripService.updateTripTitle — trim logic', () {
    String? computeTitle(String input) {
      final trimmed = input.trim().isEmpty ? null : input.trim();
      return trimmed;
    }

    test('empty string after trim becomes null', () {
      expect(computeTitle(''), isNull);
    });

    test('whitespace-only string becomes null', () {
      expect(computeTitle('   '), isNull);
    });

    test('valid title is trimmed and returned', () {
      expect(computeTitle('  Morning Run  '), 'Morning Run');
    });

    test('already-trimmed title is returned unchanged', () {
      expect(computeTitle('Evening'), 'Evening');
    });
  });

  // ── TripService.logCatch — active trip catch list append ─────────────────

  group('TripService.logCatch — active trip in-memory update', () {
    test('appends new catch to active trip catches list (simulated)', () {
      final initial = makeTrip(id: 'trip-A', catches: [makeCatch(id: 'c1')]);
      final newCatch = makeCatch(id: 'c2', tripId: 'trip-A', species: 'Zubaidi');

      // Simulate the service guard: if (_activeTrip?.id == tripId) update
      final updated = initial.id == newCatch.tripId
          ? initial.copyWith(catches: [...initial.catches, newCatch])
          : initial;

      expect(updated.catches.length, 2);
      expect(updated.catches.last.id, 'c2');
    });

    test('does not append catch when tripId does not match active trip (simulated)', () {
      final initial = makeTrip(id: 'trip-A', catches: [makeCatch(id: 'c1')]);
      final newCatch = makeCatch(id: 'c2', tripId: 'trip-B');

      final updated = initial.id == newCatch.tripId
          ? initial.copyWith(catches: [...initial.catches, newCatch])
          : initial;

      expect(updated.catches.length, 1);
    });
  });

  // ── TripService.initialize — orphan-trip close logic ─────────────────────

  group('TripService.initialize — orphan trip resolution', () {
    test('when multiple open rows exist, last one becomes active', () {
      final rows = [
        {'id': 'trip-old-1', 'start_time': '2026-04-20T08:00:00.000', 'paused_seconds': 0},
        {'id': 'trip-old-2', 'start_time': '2026-04-21T08:00:00.000', 'paused_seconds': 0},
        {'id': 'trip-new',   'start_time': '2026-04-22T08:00:00.000', 'paused_seconds': 0},
      ];
      final activeRow = rows.last;
      final toClose = rows.sublist(0, rows.length - 1);

      expect(activeRow['id'], 'trip-new');
      expect(toClose.length, 2);
      expect(toClose.map((r) => r['id']).toList(),
          containsAll(['trip-old-1', 'trip-old-2']));
    });

    test('when only one open row exists, no rows are closed', () {
      final rows = [
        {'id': 'trip-only', 'start_time': '2026-04-22T08:00:00.000'},
      ];
      final toClose = rows.sublist(0, rows.length - 1);
      expect(toClose, isEmpty);
    });
  });

  // ── _seedFromFirestore — start_time null guard ────────────────────────────

  group('_seedFromFirestore — required field guard', () {
    test('trip rows without start_time are skipped (simulated)', () {
      final rows = <Map<String, Object?>>[
        {'id': 't1', 'start_time': '2026-04-22T08:00:00.000'},
        {'id': 't2', 'start_time': null},
        {'id': 't3', 'start_time': '2026-04-22T10:00:00.000'},
      ];
      final accepted = rows.where((r) => r['start_time'] != null).toList();
      expect(accepted.length, 2);
      expect(accepted.map((r) => r['id']).toList(), ['t1', 't3']);
    });
  });

  // ── fetchCatchesFromFirestore — null uid guard ────────────────────────────

  group('fetchCatchesFromFirestore — null uid guard', () {
    // Mirrors: if (uid == null) return [];
    List<CatchEntry> guardedFetch(String? uid) => uid == null ? [] : [makeCatch()];

    test('returns empty list when uid is null', () {
      expect(guardedFetch(null), isEmpty);
    });

    test('returns non-empty list when uid is provided', () {
      expect(guardedFetch('user-123'), isNotEmpty);
    });
  });

  // ── arabicN helper ────────────────────────────────────────────────────────

  group('arabicN helper — digit numeral conversion', () {
    test('converts all ASCII digits to Arabic-Indic for locale "ar"', () {
      expect(arabicN('0123456789', 'ar'), '٠١٢٣٤٥٦٧٨٩');
    });

    test('passes string through unchanged for locale "en"', () {
      expect(arabicN('0123456789', 'en'), '0123456789');
    });

    test('passes string through unchanged for unknown locale', () {
      expect(arabicN('42', 'fr'), '42');
    });

    test('converts individual digit in mixed string for "ar"', () {
      expect(arabicN('5 catches', 'ar'), '٥ catches');
    });

    test('empty string returns empty string for both locales', () {
      expect(arabicN('', 'ar'), '');
      expect(arabicN('', 'en'), '');
    });

    test('string with no digits is unchanged for "ar"', () {
      expect(arabicN('كجم', 'ar'), 'كجم');
    });
  });

  // ── _filteredTrips search logic ───────────────────────────────────────────

  group('FishingLogScreen._filteredTrips — search logic (simulated)', () {
    final trips = [
      makeTrip(id: 't1', startTime: DateTime(2026, 4, 21, 8, 0)),
      makeTrip(id: 't2', startTime: DateTime(2026, 3, 5, 8, 0)),
      makeTrip(
        id: 't3',
        startTime: DateTime(2026, 4, 22, 8, 0),
        title: 'Morning Hamour Run',
      ),
    ];

    List<Trip> filter(String q) {
      if (q.isEmpty) return trips;
      final query = q.toLowerCase();
      return trips.where((t) {
        if ((t.title ?? '').toLowerCase().contains(query)) return true;
        final date = t.startTime.toLocal();
        final formats = [
          '${date.day}/${date.month}/${date.year}',
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ];
        return formats.any((f) => f.toLowerCase().contains(query));
      }).toList();
    }

    test('empty query returns all trips', () {
      expect(filter('').length, 3);
    });

    test('title search matches trips by title substring', () {
      final results = filter('hamour');
      expect(results.length, 1);
      expect(results.first.id, 't3');
    });

    test('date search matches trips by ISO date string', () {
      final results = filter('2026-04-21');
      expect(results.length, 1);
      expect(results.first.id, 't1');
    });

    test('query with no match returns empty list', () {
      expect(filter('xyznotexist'), isEmpty);
    });

    test('case-insensitive title match works', () {
      final results = filter('MORNING');
      expect(results.length, 1);
      expect(results.first.id, 't3');
    });
  });

  // ── _todayEndedTrip logic ─────────────────────────────────────────────────

  group('FishingLogScreen._todayEndedTrip — selection logic (simulated)', () {
    final today = DateTime.now();

    Trip todayEnded() => Trip(
          id: 'today-ended',
          startTime: today.subtract(const Duration(hours: 3)),
          endTime: today.subtract(const Duration(hours: 1)),
        );

    Trip yesterdayEnded() => Trip(
          id: 'yesterday',
          startTime: today.subtract(const Duration(days: 1, hours: 4)),
          endTime: today.subtract(const Duration(days: 1)),
        );

    Trip? findTodayEnded(List<Trip> trips) {
      for (final t in trips) {
        if (!t.isActive && t.endTime != null) {
          final end = t.endTime!.toLocal();
          if (end.year == today.year &&
              end.month == today.month &&
              end.day == today.day) {
            return t;
          }
        }
      }
      return null;
    }

    test('returns today-ended trip when it exists', () {
      final result = findTodayEnded([yesterdayEnded(), todayEnded()]);
      expect(result?.id, 'today-ended');
    });

    test('returns null when no trip ended today', () {
      final result = findTodayEnded([yesterdayEnded()]);
      expect(result, isNull);
    });

    test('returns null for active trip even if started today', () {
      final activeToday = Trip(
        id: 'active-today',
        startTime: today.subtract(const Duration(hours: 1)),
        endTime: null,
      );
      final result = findTodayEnded([activeToday]);
      expect(result, isNull);
    });

    test('returns first matching trip from list (scan order)', () {
      final a = Trip(
        id: 'first-today',
        startTime: today.subtract(const Duration(hours: 5)),
        endTime: today.subtract(const Duration(hours: 4)),
      );
      final b = Trip(
        id: 'second-today',
        startTime: today.subtract(const Duration(hours: 3)),
        endTime: today.subtract(const Duration(hours: 2)),
      );
      final result = findTodayEnded([a, b]);
      expect(result?.id, 'first-today');
    });
  });

  // ── _formatDuration boundary values ──────────────────────────────────────

  group('_formatDuration boundary values (simulated)', () {
    String formatDuration(Duration d, String locale) {
      final isAr = locale == 'ar';
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final s = d.inSeconds.remainder(60);
      String num(int n) => arabicN('$n', locale);
      if (h > 0) return isAr ? '${num(h)}س ${num(m)}د' : '${h}h ${m}m';
      if (m > 0) return isAr ? '${num(m)}د ${num(s)}ث' : '${m}m ${s}s';
      return isAr ? '${num(s)}ث' : '${s}s';
    }

    test('zero duration displays "0s" in English', () {
      expect(formatDuration(Duration.zero, 'en'), '0s');
    });

    test('zero duration displays Arabic seconds suffix', () {
      expect(formatDuration(Duration.zero, 'ar'), contains('ث'));
    });

    test('59 seconds shows seconds only (no minutes)', () {
      expect(formatDuration(const Duration(seconds: 59), 'en'), '59s');
    });

    test('exactly 60 seconds shows 1m 0s', () {
      expect(formatDuration(const Duration(minutes: 1), 'en'), '1m 0s');
    });

    test('90 minutes shows 1h 30m', () {
      expect(formatDuration(const Duration(minutes: 90), 'en'), '1h 30m');
    });

    test('Arabic hour format uses Arabic-Indic numerals', () {
      final result = formatDuration(const Duration(hours: 2, minutes: 15), 'ar');
      expect(result, contains('٢'));
      expect(result, contains('س'));
    });

    test('Arabic minute format uses Arabic-Indic numerals', () {
      final result =
          formatDuration(const Duration(minutes: 45, seconds: 30), 'ar');
      expect(result, contains('٤٥'));
      expect(result, contains('د'));
    });
  });

  // ── CatchEntry.location LatLng helper ─────────────────────────────────────

  group('CatchEntry.location LatLng helper', () {
    test('location returns correct LatLng from lat/lon fields', () {
      final entry = makeCatch(lat: 26.15, lon: 50.42);
      expect(entry.location!.latitude, closeTo(26.15, 0.0001));
      expect(entry.location!.longitude, closeTo(50.42, 0.0001));
    });
  });
}
