import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bahaar/services/map/osrm_routing_service.dart';
import 'package:bahaar/models/map/navigation/route_model.dart';
import 'package:latlong2/latlong.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

const _origin = LatLng(26.0, 50.0);
const _destination = LatLng(26.5, 50.5);

String _osrmSuccess({double distance = 5000, int duration = 600}) {
  return jsonEncode({
    'code': 'Ok',
    'routes': [
      {
        'distance': distance,
        'duration': duration,
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [50.0, 26.0],
            [50.25, 26.25],
            [50.5, 26.5],
          ],
        },
        'legs': [],
      }
    ],
  });
}

String _osrmNoRoute() => jsonEncode({'code': 'Ok', 'routes': []});

MockClient _client(String body, {int status = 200}) {
  return MockClient((_) async => http.Response(body, status));
}

OsrmRoutingService _service(MockClient client) {
  return OsrmRoutingService(
    client: client,
    baseUrl: 'https://osrm.test',
  );
}

void main() {
  // ── getRoute — success path ──────────────────────────────────────────────────

  group('OsrmRoutingService.getRoute — success', () {
    test('returns RouteSegment on HTTP 200 with valid OSRM body', () async {
      final svc = _service(_client(_osrmSuccess()));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg, isNotNull);
      expect(seg!.type, SegmentType.land);
    });

    test('distance is parsed correctly from OSRM response', () async {
      final svc = _service(_client(_osrmSuccess(distance: 7500)));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg!.distance, closeTo(7500, 0.001));
    });

    test('duration is parsed correctly from OSRM response', () async {
      final svc = _service(_client(_osrmSuccess(duration: 900)));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg!.duration, 900);
    });

    test('geometry converts GeoJSON [lon, lat] pairs to LatLng correctly', () async {
      final svc = _service(_client(_osrmSuccess()));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      // First coordinate in GeoJSON is [50.0, 26.0] → LatLng(26.0, 50.0)
      expect(seg!.geometry.first.latitude, closeTo(26.0, 0.0001));
      expect(seg.geometry.first.longitude, closeTo(50.0, 0.0001));
    });

    test('geometry correctly swaps lon/lat — last point is LatLng(26.5, 50.5)', () async {
      final svc = _service(_client(_osrmSuccess()));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg!.geometry.last.latitude, closeTo(26.5, 0.0001));
      expect(seg.geometry.last.longitude, closeTo(50.5, 0.0001));
    });

    test('transportMode is set to "car" for driving profile', () async {
      final svc = _service(_client(_osrmSuccess()));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg!.transportMode, 'car');
    });
  });

  // ── getRoute — no-route cases ────────────────────────────────────────────────

  group('OsrmRoutingService.getRoute — no route', () {
    test('returns null when routes list is empty', () async {
      final svc = _service(_client(_osrmNoRoute()));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg, isNull);
    });

    test('returns null on HTTP 400 (no route possible)', () async {
      final svc = _service(_client('Bad Request', status: 400));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg, isNull);
    });
  });

  // ── getRoute — error handling ────────────────────────────────────────────────

  group('OsrmRoutingService.getRoute — error handling', () {
    test('returns null on malformed JSON (FormatException, no retry)', () async {
      final svc = _service(_client('NOT JSON'));
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg, isNull);
    });

    test('returns null after all retries on ClientException', () async {
      int calls = 0;
      final mockClient = MockClient((_) async {
        calls++;
        throw http.ClientException('Network error');
      });
      final svc = _service(mockClient);
      final seg = await svc.getRoute(origin: _origin, destination: _destination);
      expect(seg, isNull);
      // Should have attempted osrmMaxRetries = 3 times
      expect(calls, 3);
    });
  });

  // ── OsrmProfile ──────────────────────────────────────────────────────────────

  group('OsrmProfile', () {
    test('driving profile value is "driving"', () {
      expect(OsrmProfile.driving.value, 'driving');
    });

    test('walking profile value is "foot"', () {
      expect(OsrmProfile.walking.value, 'foot');
    });

    test('cycling profile value is "bike"', () {
      expect(OsrmProfile.cycling.value, 'bike');
    });

    test('driving transportMode is "car"', () {
      expect(OsrmProfile.driving.transportMode, 'car');
    });

    test('all profiles have non-empty displayName', () {
      for (final p in OsrmProfile.values) {
        expect(p.displayName, isNotEmpty);
      }
    });

    test('displayNames are distinct', () {
      final names = OsrmProfile.values.map((p) => p.displayName).toSet();
      expect(names.length, OsrmProfile.values.length);
    });
  });

  // ── getRouteEstimate ─────────────────────────────────────────────────────────

  group('OsrmRoutingService.getRouteEstimate', () {
    test('returns distance and duration record on success', () async {
      final body = jsonEncode({
        'code': 'Ok',
        'routes': [
          {'distance': 3000.0, 'duration': 400},
        ],
      });
      final svc = _service(_client(body));
      final result = await svc.getRouteEstimate(
        origin: _origin,
        destination: _destination,
      );
      expect(result, isNotNull);
      expect(result!.distance, closeTo(3000.0, 0.001));
      expect(result.duration, 400);
    });

    test('returns null on network error', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('offline');
      });
      final svc = _service(mockClient);
      final result = await svc.getRouteEstimate(
        origin: _origin,
        destination: _destination,
      );
      expect(result, isNull);
    });
  });

  // ── isServiceAvailable ───────────────────────────────────────────────────────

  group('OsrmRoutingService.isServiceAvailable', () {
    test('returns true on HTTP 200', () async {
      final svc = _service(_client('{}', status: 200));
      expect(await svc.isServiceAvailable(), isTrue);
    });

    test('returns true on HTTP 400 (service reachable, just no route)', () async {
      final svc = _service(_client('bad request', status: 400));
      expect(await svc.isServiceAvailable(), isTrue);
    });

    test('returns false on ClientException', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('unreachable');
      });
      final svc = _service(mockClient);
      expect(await svc.isServiceAvailable(), isFalse);
    });
  });

  // ── getAlternativeRoutes ──────────────────────────────────────────────────────

  group('OsrmRoutingService.getAlternativeRoutes', () {
    test('returns list of segments when alternatives exist', () async {
      final body = jsonEncode({
        'code': 'Ok',
        'routes': [
          {
            'distance': 5000.0,
            'duration': 600,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [50.0, 26.0],
                [50.5, 26.5],
              ],
            },
          },
          {
            'distance': 6000.0,
            'duration': 720,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [50.0, 26.0],
                [50.3, 26.4],
                [50.5, 26.5],
              ],
            },
          },
        ],
      });
      final svc = _service(_client(body));
      final alts = await svc.getAlternativeRoutes(
        origin: _origin,
        destination: _destination,
      );
      expect(alts.length, 2);
      expect(alts.first.distance, closeTo(5000.0, 0.001));
      expect(alts.last.distance, closeTo(6000.0, 0.001));
    });

    test('returns empty list on network error', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('offline');
      });
      final svc = _service(mockClient);
      final alts = await svc.getAlternativeRoutes(
        origin: _origin,
        destination: _destination,
      );
      expect(alts, isEmpty);
    });
  });
}
