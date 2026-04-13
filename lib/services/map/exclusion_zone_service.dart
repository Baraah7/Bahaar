import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Represents a single offshore oil/gas installation with its 500m safety buffer.
class ExclusionZone {
  final String name;
  final String operator;
  final String type; // 'oil_platform' or 'gas_installation'
  final LatLng center;
  final double bufferMeters;

  const ExclusionZone({
    required this.name,
    required this.operator,
    required this.type,
    required this.center,
    required this.bufferMeters,
  });

  bool get isGasInstallation => type == 'gas_installation';
}

/// Result when checking if a position is inside an exclusion zone.
class ExclusionZoneViolation {
  final ExclusionZone zone;
  final double distanceMeters;

  const ExclusionZoneViolation({
    required this.zone,
    required this.distanceMeters,
  });
}

/// Service that loads Bahrain offshore oil/gas platform exclusion zones and
/// provides fast proximity checks against them.
///
/// Each zone has a mandatory 500 m safety buffer per UNCLOS Article 60.
class ExclusionZoneService {
  static const String _assetPath = 'assets/data/bahrain_exclusion_zones.geojson';

  final List<ExclusionZone> _zones = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<ExclusionZone> get zones => List.unmodifiable(_zones);

  /// Load exclusion zones from bundled GeoJSON asset.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = json.decode(raw) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;

      for (final f in features) {
        try {
          final props = f['properties'] as Map<String, dynamic>;
          final geom = f['geometry'] as Map<String, dynamic>;
          final coords = geom['coordinates'] as List<dynamic>;

          _zones.add(ExclusionZone(
            name: props['name'] as String,
            operator: props['operator'] as String? ?? 'Unknown',
            type: props['type'] as String? ?? 'oil_platform',
            center: LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            ),
            bufferMeters: (props['buffer_m'] as num?)?.toDouble() ?? 500.0,
          ));
        } catch (e) {
          log('ExclusionZoneService: error parsing feature: $e');
        }
      }

      _initialized = true;
      log('ExclusionZoneService: loaded ${_zones.length} exclusion zones');
    } catch (e) {
      log('ExclusionZoneService: failed to initialize: $e');
    }
  }

  /// Check if [position] is inside any exclusion zone's safety buffer.
  /// Returns the first violation found, or null if clear.
  ExclusionZoneViolation? checkViolation(LatLng position) {
    for (final zone in _zones) {
      final dist = _haversineMeters(position, zone.center);
      if (dist <= zone.bufferMeters) {
        return ExclusionZoneViolation(zone: zone, distanceMeters: dist);
      }
    }
    return null;
  }

  /// Returns all zones whose buffer overlaps [position].
  List<ExclusionZoneViolation> checkAllViolations(LatLng position) {
    final violations = <ExclusionZoneViolation>[];
    for (final zone in _zones) {
      final dist = _haversineMeters(position, zone.center);
      if (dist <= zone.bufferMeters) {
        violations.add(ExclusionZoneViolation(zone: zone, distanceMeters: dist));
      }
    }
    return violations;
  }

  /// Returns true if [position] is within [warningMeters] of any zone center
  /// (but not yet inside the 500m hard buffer) — useful for approach warnings.
  ExclusionZone? checkApproach(LatLng position, {double warningMeters = 1000}) {
    for (final zone in _zones) {
      final dist = _haversineMeters(position, zone.center);
      if (dist <= warningMeters && dist > zone.bufferMeters) {
        return zone;
      }
    }
    return null;
  }

  /// Remove zones that have no navigable water within [searchRadiusCells]
  /// grid cells of their centre.
  ///
  /// Uses [hasNearbyWater] — pass `_navigationMask.findNearestWaterPoint`
  /// (or similar) so that a zone is kept as long as water exists nearby,
  /// even if the exact centre coordinate falls on a land cell due to grid
  /// rounding.
  ///
  /// ```dart
  /// _exclusionZoneService.filterByWater(
  ///   (p) => _navigationMask.findNearestWaterPoint(p, maxSearchRadius: 5) != null,
  /// );
  /// ```
  void filterByWater(bool Function(LatLng) hasNearbyWater) {
    _zones.removeWhere((zone) => !hasNearbyWater(zone.center));
    log('ExclusionZoneService: ${_zones.length} zones after land filter');
  }

  /// Build approximate circular polygons for each zone so the marine
  /// pathfinder can treat them as hard-blocked areas.
  ///
  /// [pointCount] controls polygon resolution (default 16 is plenty for
  /// the ~111 m grid cells used by the A* planner).
  List<Polygon> buildExclusionPolygons({int pointCount = 16}) {
    return _zones.map((zone) {
      const metersPerDegLat = 111319.9;
      final metersPerDegLon =
          metersPerDegLat * math.cos(zone.center.latitude * math.pi / 180);

      final points = List.generate(pointCount, (i) {
        final angle = 2 * math.pi * i / pointCount;
        final dLat = (zone.bufferMeters * math.cos(angle)) / metersPerDegLat;
        final dLon = (zone.bufferMeters * math.sin(angle)) / metersPerDegLon;
        return LatLng(
          zone.center.latitude + dLat,
          zone.center.longitude + dLon,
        );
      });

      return Polygon(points: points);
    }).toList();
  }

  /// Public distance in metres between [position] and a zone's centre.
  double distanceTo(LatLng position, ExclusionZone zone) =>
      _haversineMeters(position, zone.center);

  /// Haversine distance between two LatLng points in meters.
  double _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in meters
    final lat1 = a.latitudeInRad;
    final lat2 = b.latitudeInRad;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final h = sinDLat * sinDLat +
        math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    return 2 * r * math.asin(math.sqrt(h));
  }
}
