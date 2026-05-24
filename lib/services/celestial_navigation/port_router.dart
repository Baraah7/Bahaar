import 'package:latlong2/latlong.dart';
import 'dead_reckoning.dart';
import 'trip_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route result
// ─────────────────────────────────────────────────────────────────────────────

class RouteToPort {
  final Port   port;
  final double bearingDeg;    // true north bearing to port
  final double distanceNm;    // great-circle distance
  final String? warning;      // non-null if uncertainty makes routing unsafe

  const RouteToPort({
    required this.port,
    required this.bearingDeg,
    required this.distanceNm,
    this.warning,
  });

  /// One-line navigation instruction suitable for display.
  String get instruction {
    final bear = bearingDeg.round();
    final dist = distanceNm < 10
        ? distanceNm.toStringAsFixed(1)
        : distanceNm.toStringAsFixed(0);
    return 'Steer $bear° true — $dist NM to ${port.name}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PortRouter — pure static routing calculations, no I/O
// ─────────────────────────────────────────────────────────────────────────────

class PortRouter {
  const PortRouter._();

  /// Route from [fromPosition] to a specific [destination] port.
  ///
  /// Returns `null` only if [fromPosition] and the port are the same point.
  static RouteToPort? routeTo({
    required LatLng fromPosition,
    required Port   destination,
    double          positionUncertaintyNm = 0.0,
  }) {
    final dest = LatLng(destination.lat, destination.lng);
    final dist = DeadReckoning.distanceNm(fromPosition, dest);

    if (dist < 0.01) return null; // already at port

    final bear = DeadReckoning.bearingDeg(fromPosition, dest);

    String? warning;
    if (positionUncertaintyNm >= kDrMaxReliableNm) {
      warning = 'Position uncertainty ±${positionUncertaintyNm.toStringAsFixed(1)} NM '
                'exceeds safe limit. Bearing is approximate only.';
    } else if (positionUncertaintyNm >= kDrWarningNm) {
      warning = 'Position uncertainty ±${positionUncertaintyNm.toStringAsFixed(1)} NM — '
                'use caution.';
    }

    return RouteToPort(
      port:       destination,
      bearingDeg: bear,
      distanceNm: dist,
      warning:    warning,
    );
  }

  /// Returns routes to ALL known ports sorted by distance, nearest first.
  ///
  /// [maxResults] — cap the list (default 5).
  static List<RouteToPort> nearestPorts({
    required LatLng     fromPosition,
    required List<Port> allPorts,
    int                 maxResults            = 5,
    double              positionUncertaintyNm = 0.0,
  }) {
    final routes = <RouteToPort>[];

    for (final port in allPorts) {
      final r = routeTo(
        fromPosition:          fromPosition,
        destination:           port,
        positionUncertaintyNm: positionUncertaintyNm,
      );
      if (r != null) routes.add(r);
    }

    routes.sort((a, b) => a.distanceNm.compareTo(b.distanceNm));
    return routes.take(maxResults).toList();
  }

  /// Returns the single closest port, or `null` if [allPorts] is empty.
  static RouteToPort? nearest({
    required LatLng     fromPosition,
    required List<Port> allPorts,
    double              positionUncertaintyNm = 0.0,
  }) {
    final routes = nearestPorts(
      fromPosition:          fromPosition,
      allPorts:              allPorts,
      maxResults:            1,
      positionUncertaintyNm: positionUncertaintyNm,
    );
    return routes.isEmpty ? null : routes.first;
  }
}
