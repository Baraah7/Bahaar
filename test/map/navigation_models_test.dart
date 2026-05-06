import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/utilities/map/navigation_constants.dart';
import 'package:bahaar/models/navigation/navigation_session_model.dart';
import 'package:bahaar/models/navigation/route_model.dart';
import 'package:bahaar/models/navigation/waypoint_model.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:latlong2/latlong.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

RouteValidation _valid() => RouteValidation(
      isValid: true,
      totalPoints: 10,
      waterPoints: 10,
      landPoints: 0,
      landPointIndices: [],
    );

RouteValidation _invalid() => RouteValidation(
      isValid: false,
      totalPoints: 10,
      waterPoints: 7,
      landPoints: 3,
      landPointIndices: [2, 5, 8],
    );

RouteMetrics _zeroMetrics() => const RouteMetrics(
      landDistance: 0,
      marineDistance: 0,
      landDuration: 0,
      marineDuration: 0,
    );

RouteSegment _landSegment({double distance = 1000, int duration = 120}) =>
    RouteSegment(
      type: SegmentType.land,
      geometry: [const LatLng(26.0, 50.0), const LatLng(26.1, 50.1)],
      distance: distance,
      duration: duration,
      transportMode: 'car',
    );

RouteSegment _marineSegment({double distance = 2000, int duration = 300}) =>
    RouteSegment(
      type: SegmentType.marine,
      geometry: [const LatLng(26.1, 50.1), const LatLng(26.2, 50.2)],
      distance: distance,
      duration: duration,
    );

NavigationRoute _makeRoute({
  List<RouteSegment>? segments,
  double totalDistance = 5000,
  int estimatedDuration = 600,
  RouteValidation? validation,
}) {
  return NavigationRoute(
    id: 'route-1',
    origin: const LatLng(26.0, 50.0),
    destination: const LatLng(26.5, 50.5),
    segments: segments ?? [_landSegment()],
    geometry: [const LatLng(26.0, 50.0), const LatLng(26.5, 50.5)],
    waypoints: [],
    totalDistance: totalDistance,
    estimatedDuration: estimatedDuration,
    validation: validation ?? _valid(),
    createdAt: DateTime(2026, 4, 22),
    metrics: _zeroMetrics(),
  );
}

NavigationSession _makeSession({
  NavigationRoute? route,
  NavigationState state = NavigationState.active,
  LatLng? currentLocation,
  double? currentSpeed,
  int currentWaypointIndex = 0,
  int currentSegmentIndex = 0,
  List<LatLng>? breadcrumbs,
  NavigationMetrics? metrics,
}) {
  return NavigationSession(
    id: 'session-1',
    route: route ?? _makeRoute(),
    state: state,
    currentLocation: currentLocation,
    currentBearing: 45.0,
    currentSpeed: currentSpeed,
    currentSegmentIndex: currentSegmentIndex,
    currentWaypointIndex: currentWaypointIndex,
    startTime: DateTime(2026, 4, 22, 10, 0),
    breadcrumbs: breadcrumbs ?? [const LatLng(26.0, 50.0)],
    metrics: metrics ??
        const NavigationMetrics(
          distanceTraveled: 0,
          elapsedTime: 0,
          maxSpeed: 0,
        ),
  );
}

Waypoint _makeWaypoint({
  WaypointType type = WaypointType.turn,
  required LatLng location,
}) =>
    Waypoint(
      id: 'wp-1',
      location: location,
      type: type,
      distanceFromStart: 100,
      segmentType: RouteSegmentType.land,
    );

void main() {
  // ── NavigationConstants — unit conversions ───────────────────────────────────

  group('NavigationConstants — unit conversions', () {
    test('metersToNauticalMiles: 1852 m = 1 NM', () {
      expect(NavigationConstants.metersToNauticalMiles(1852), closeTo(1.0, 0.0001));
    });

    test('metersToNauticalMiles: 0 m = 0 NM', () {
      expect(NavigationConstants.metersToNauticalMiles(0), 0.0);
    });

    test('nauticalMilesToMeters: 1 NM = 1852 m', () {
      expect(NavigationConstants.nauticalMilesToMeters(1.0), closeTo(1852.0, 0.01));
    });

    test('msToKnots: 1.94384 m/s ≈ 3.777 kn (double conversion)', () {
      expect(NavigationConstants.msToKnots(1.94384), closeTo(3.77761, 0.001));
    });

    test('knotsToMs: 1 knot = 0.5144 m/s', () {
      expect(NavigationConstants.knotsToMs(1.0), closeTo(0.5144, 0.001));
    });

    test('msToKnots and knotsToMs are inverses', () {
      const ms = 5.14;
      expect(NavigationConstants.knotsToMs(NavigationConstants.msToKnots(ms)),
          closeTo(ms, 0.001));
    });

    test('averageBoatSpeedMs is close to 10 knots in m/s', () {
      expect(NavigationConstants.averageBoatSpeedMs, closeTo(5.14, 0.01));
    });
  });

  // ── NavigationConstants — formatDistance ────────────────────────────────────

  group('NavigationConstants.formatDistance', () {
    test('below 1000 m → meters format', () {
      expect(NavigationConstants.formatDistance(500), '500 m');
    });

    test('exactly 1000 m → km format', () {
      expect(NavigationConstants.formatDistance(1000), '1.0 km');
    });

    test('above 1000 m → km format with 1 decimal', () {
      expect(NavigationConstants.formatDistance(2500), '2.5 km');
    });

    test('0 m → "0 m"', () {
      expect(NavigationConstants.formatDistance(0), '0 m');
    });
  });

  // ── NavigationConstants — formatDuration ────────────────────────────────────

  group('NavigationConstants.formatDuration', () {
    test('below 60 s → seconds format', () {
      expect(NavigationConstants.formatDuration(45), '45 sec');
    });

    test('60 s → minutes format', () {
      expect(NavigationConstants.formatDuration(60), '1 min');
    });

    test('90 s → "2 min" (rounded)', () {
      expect(NavigationConstants.formatDuration(90), '2 min');
    });

    test('3600 s → "1h 0m"', () {
      expect(NavigationConstants.formatDuration(3600), '1h 0m');
    });

    test('3660 s → "1h 1m"', () {
      expect(NavigationConstants.formatDuration(3660), '1h 1m');
    });

    test('7200 s → "2h 0m"', () {
      expect(NavigationConstants.formatDuration(7200), '2h 0m');
    });
  });

  // ── NavigationConstants — formatSpeed ───────────────────────────────────────

  group('NavigationConstants.formatSpeed', () {
    test('5.14 m/s → approximately "10.0 kn"', () {
      expect(NavigationConstants.formatSpeed(5.14), contains('kn'));
    });

    test('0 m/s → "0.0 kn"', () {
      expect(NavigationConstants.formatSpeed(0), '0.0 kn');
    });
  });

  // ── RouteMetrics ─────────────────────────────────────────────────────────────

  group('RouteMetrics', () {
    test('totalDistance = landDistance + marineDistance', () {
      const m = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 0,
        marineDuration: 0,
      );
      expect(m.totalDistance, closeTo(3000.0, 0.001));
    });

    test('totalDuration = landDuration + marineDuration', () {
      const m = RouteMetrics(
        landDistance: 0,
        marineDistance: 0,
        landDuration: 120,
        marineDuration: 300,
      );
      expect(m.totalDuration, 420);
    });

    test('landPercentage: 1000 of 4000 = 25%', () {
      const m = RouteMetrics(
        landDistance: 1000,
        marineDistance: 3000,
        landDuration: 0,
        marineDuration: 0,
      );
      expect(m.landPercentage, closeTo(25.0, 0.001));
    });

    test('marinePercentage: 3000 of 4000 = 75%', () {
      const m = RouteMetrics(
        landDistance: 1000,
        marineDistance: 3000,
        landDuration: 0,
        marineDuration: 0,
      );
      expect(m.marinePercentage, closeTo(75.0, 0.001));
    });

    test('landPercentage is 0 when totalDistance is 0', () {
      const m = RouteMetrics(
        landDistance: 0,
        marineDistance: 0,
        landDuration: 0,
        marineDuration: 0,
      );
      expect(m.landPercentage, 0.0);
    });

    test('toJson / fromJson roundtrip preserves all fields', () {
      const original = RouteMetrics(
        landDistance: 1500.0,
        marineDistance: 2500.0,
        landDuration: 180,
        marineDuration: 360,
        numRestrictedAreaViolations: 2,
      );
      final restored = RouteMetrics.fromJson(original.toJson());
      expect(restored.landDistance, original.landDistance);
      expect(restored.marineDistance, original.marineDistance);
      expect(restored.landDuration, original.landDuration);
      expect(restored.marineDuration, original.marineDuration);
      expect(restored.numRestrictedAreaViolations, 2);
    });

    test('copyWith updates specified field without affecting others', () {
      const original = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 120,
        marineDuration: 300,
      );
      final copy = original.copyWith(landDistance: 1500);
      expect(copy.landDistance, 1500);
      expect(copy.marineDistance, 2000);
      expect(copy.landDuration, 120);
    });
  });

  // ── NavigationRoute ──────────────────────────────────────────────────────────

  group('NavigationRoute', () {
    test('isHybrid is true when both land and marine segments exist', () {
      final route = _makeRoute(segments: [_landSegment(), _marineSegment()]);
      expect(route.isHybrid, isTrue);
    });

    test('isHybrid is false when only land segments exist', () {
      final route = _makeRoute(segments: [_landSegment()]);
      expect(route.isHybrid, isFalse);
    });

    test('isHybrid is false when only marine segments exist', () {
      final route = _makeRoute(segments: [_marineSegment()]);
      expect(route.isHybrid, isFalse);
    });

    test('crossesRestrictedAreas is true when validation.isValid is false', () {
      final route = _makeRoute(validation: _invalid());
      expect(route.crossesRestrictedAreas, isTrue);
    });

    test('crossesRestrictedAreas is false when validation.isValid is true', () {
      final route = _makeRoute(validation: _valid());
      expect(route.crossesRestrictedAreas, isFalse);
    });

    test('progressPercentage: 2500 of 5000 = 50%', () {
      final route = _makeRoute(totalDistance: 5000);
      expect(route.progressPercentage(2500), closeTo(50.0, 0.001));
    });

    test('progressPercentage is 0 when totalDistance is 0', () {
      final route = _makeRoute(totalDistance: 0);
      expect(route.progressPercentage(0), 0.0);
    });

    test('progressPercentage is clamped to 100 when overshoot', () {
      final route = _makeRoute(totalDistance: 1000);
      expect(route.progressPercentage(1500), closeTo(100.0, 0.001));
    });

    test('copyWith updates id while preserving other fields', () {
      final original = _makeRoute();
      final copy = original.copyWith(id: 'route-2');
      expect(copy.id, 'route-2');
      expect(copy.origin, original.origin);
      expect(copy.totalDistance, original.totalDistance);
    });
  });

  // ── RouteSegment ─────────────────────────────────────────────────────────────

  group('RouteSegment', () {
    test('toJson serializes type as string', () {
      final seg = _landSegment();
      final json = seg.toJson();
      expect(json['type'], 'land');
    });

    test('toJson serializes geometry as list of lat/lon maps', () {
      final seg = _landSegment();
      final json = seg.toJson();
      final geom = json['geometry'] as List;
      expect(geom.first['lat'], closeTo(26.0, 0.0001));
      expect(geom.first['lon'], closeTo(50.0, 0.0001));
    });

    test('toJson includes transport_mode when present', () {
      final json = _landSegment().toJson();
      expect(json['transport_mode'], 'car');
    });

    test('toJson omits transport_mode when null', () {
      final json = _marineSegment().toJson();
      expect(json.containsKey('transport_mode'), isFalse);
    });

    test('SegmentType.land has displayName "Land"', () {
      expect(SegmentType.land.displayName, 'Land');
    });

    test('SegmentType.marine has displayName "Marine"', () {
      expect(SegmentType.marine.displayName, 'Marine');
    });
  });

  // ── NavigationSession ────────────────────────────────────────────────────────

  group('NavigationSession', () {
    test('distanceRemaining = totalDistance - distanceTraveled', () {
      const metrics = NavigationMetrics(
        distanceTraveled: 1000,
        elapsedTime: 60,
        maxSpeed: 5.0,
      );
      final session = _makeSession(metrics: metrics);
      expect(session.distanceRemaining, closeTo(4000.0, 0.001));
    });

    test('distanceRemaining returns totalDistance when location is null', () {
      final session = _makeSession(currentLocation: null);
      expect(session.distanceRemaining, closeTo(5000.0, 0.001));
    });

    test('progressPercentage: 2500 of 5000 = 50%', () {
      const metrics = NavigationMetrics(
        distanceTraveled: 2500,
        elapsedTime: 0,
        maxSpeed: 0,
      );
      final session = _makeSession(metrics: metrics);
      expect(session.progressPercentage, closeTo(50.0, 0.001));
    });

    test('nextWaypoint returns null when at last waypoint', () {
      final route = _makeRoute();
      final session = _makeSession(route: route, currentWaypointIndex: 0);
      expect(session.nextWaypoint, isNull);
    });

    test('nextWaypoint returns second waypoint when at index 0 and route has 2', () {
      final wp1 = _makeWaypoint(
          type: WaypointType.start, location: const LatLng(26.0, 50.0));
      final wp2 = _makeWaypoint(
          type: WaypointType.end, location: const LatLng(26.5, 50.5));
      final route = NavigationRoute(
        id: 'r',
        origin: const LatLng(26.0, 50.0),
        destination: const LatLng(26.5, 50.5),
        segments: [_landSegment()],
        geometry: [],
        waypoints: [wp1, wp2],
        totalDistance: 5000,
        estimatedDuration: 600,
        validation: _valid(),
        createdAt: DateTime(2026, 4, 22),
        metrics: _zeroMetrics(),
      );
      final session = _makeSession(route: route, currentWaypointIndex: 0);
      expect(session.nextWaypoint, equals(wp2));
    });

    test('isNearingTransition is true when next waypoint is marinaEntry', () {
      final wp1 = _makeWaypoint(
          type: WaypointType.start, location: const LatLng(26.0, 50.0));
      final wp2 = _makeWaypoint(
          type: WaypointType.marinaEntry, location: const LatLng(26.1, 50.1));
      final route = NavigationRoute(
        id: 'r',
        origin: const LatLng(26.0, 50.0),
        destination: const LatLng(26.5, 50.5),
        segments: [_landSegment()],
        geometry: [],
        waypoints: [wp1, wp2],
        totalDistance: 5000,
        estimatedDuration: 600,
        validation: _valid(),
        createdAt: DateTime(2026, 4, 22),
        metrics: _zeroMetrics(),
      );
      final session = _makeSession(route: route, currentWaypointIndex: 0);
      expect(session.isNearingTransition, isTrue);
    });

    test('currentSegment returns null when index out of range', () {
      final session = _makeSession(currentSegmentIndex: 99);
      expect(session.currentSegment, isNull);
    });

    test('currentSegment returns correct segment at index 0', () {
      final session = _makeSession(currentSegmentIndex: 0);
      expect(session.currentSegment?.type, SegmentType.land);
    });

    test('copyWith updates state preserving all other fields', () {
      final original = _makeSession();
      final paused = original.copyWith(state: NavigationState.paused);
      expect(paused.state, NavigationState.paused);
      expect(paused.id, original.id);
      expect(paused.route, original.route);
    });
  });

  // ── NavigationMetrics ────────────────────────────────────────────────────────

  group('NavigationMetrics', () {
    test('defaults: numRecalculations = 0, hadOffRouteEvents = false', () {
      const m = NavigationMetrics(
        distanceTraveled: 0,
        elapsedTime: 0,
        maxSpeed: 0,
      );
      expect(m.numRecalculations, 0);
      expect(m.hadOffRouteEvents, isFalse);
    });

    test('toJson / fromJson roundtrip preserves all fields', () {
      const original = NavigationMetrics(
        distanceTraveled: 1234.5,
        elapsedTime: 300,
        numRecalculations: 2,
        hadOffRouteEvents: true,
        maxSpeed: 8.5,
      );
      final restored = NavigationMetrics.fromJson(original.toJson());
      expect(restored.distanceTraveled, closeTo(1234.5, 0.001));
      expect(restored.elapsedTime, 300);
      expect(restored.numRecalculations, 2);
      expect(restored.hadOffRouteEvents, isTrue);
      expect(restored.maxSpeed, closeTo(8.5, 0.001));
    });

    test('copyWith updates maxSpeed independently', () {
      const m = NavigationMetrics(
        distanceTraveled: 100,
        elapsedTime: 60,
        maxSpeed: 3.0,
      );
      final updated = m.copyWith(maxSpeed: 7.5);
      expect(updated.maxSpeed, closeTo(7.5, 0.001));
      expect(updated.distanceTraveled, closeTo(100, 0.001));
    });
  });

  // ── NavigationState enum ─────────────────────────────────────────────────────

  group('NavigationState enum', () {
    test('all states have non-empty displayName', () {
      for (final s in NavigationState.values) {
        expect(s.displayName, isNotEmpty, reason: '${s.name} has empty displayName');
      }
    });

    test('all states have non-empty description', () {
      for (final s in NavigationState.values) {
        expect(s.description, isNotEmpty, reason: '${s.name} has empty description');
      }
    });

    test('displayNames are distinct', () {
      final names = NavigationState.values.map((s) => s.displayName).toSet();
      expect(names.length, NavigationState.values.length);
    });

    test('active state displayName is "Active"', () {
      expect(NavigationState.active.displayName, 'Active');
    });

    test('error state displayName is "Error"', () {
      expect(NavigationState.error.displayName, 'Error');
    });
  });

  // ── WaypointType enum ────────────────────────────────────────────────────────

  group('WaypointType enum', () {
    test('all types have non-empty displayName', () {
      for (final t in WaypointType.values) {
        expect(t.displayName, isNotEmpty);
      }
    });

    test('marinaEntry displayName is "Marina Entry"', () {
      expect(WaypointType.marinaEntry.displayName, 'Marina Entry');
    });

    test('marinaExit displayName is "Marina Exit"', () {
      expect(WaypointType.marinaExit.displayName, 'Marina Exit');
    });
  });

  // ── Waypoint toJson / fromJson ───────────────────────────────────────────────

  group('Waypoint toJson / fromJson', () {
    test('roundtrip preserves id, type, location', () {
      final original = Waypoint(
        id: 'wp-abc',
        location: const LatLng(26.2, 50.6),
        type: WaypointType.turn,
        distanceFromStart: 500.0,
        instruction: 'Head north',
        segmentType: RouteSegmentType.land,
      );
      final restored = Waypoint.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.location.latitude, closeTo(26.2, 0.0001));
      expect(restored.location.longitude, closeTo(50.6, 0.0001));
      expect(restored.instruction, 'Head north');
    });

    test('toJson omits optional fields when null', () {
      final wp = Waypoint(
        id: 'wp-1',
        location: const LatLng(26.0, 50.0),
        type: WaypointType.start,
        distanceFromStart: 0,
        segmentType: RouteSegmentType.land,
      );
      final json = wp.toJson();
      expect(json.containsKey('bearing'), isFalse);
      expect(json.containsKey('instruction'), isFalse);
      expect(json.containsKey('estimated_time'), isFalse);
    });
  });
}
