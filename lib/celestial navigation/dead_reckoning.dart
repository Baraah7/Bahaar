import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// NM/hour uncertainty growth from compass error + leeway (5% of speed * time).
const double _kCompassErrorFactor = 0.05;

/// Base drift uncertainty added per hour regardless of speed (current, tide).
const double _kDriftNmPerHour = 0.3;

/// Yellow warning threshold — uncertainty approaching danger zone.
const double kDrWarningNm = 1.5;

/// Red reject threshold — fix is unreliable; recommend heaving to.
const double kDrMaxReliableNm = 2.0;

/// Earth mean radius in nautical miles.
const double _kEarthRadiusNm = 3440.065;

// ─────────────────────────────────────────────────────────────────────────────
// Result type
// ─────────────────────────────────────────────────────────────────────────────

enum DrReliability {
  good,      // uncertainty < 1.5 NM — navigate normally
  warning,   // 1.5 ≤ uncertainty < 2.0 NM — use caution, seek fix
  exceeded;  // uncertainty ≥ 2.0 NM — heave to, refuse as primary fix

  bool get isUsable => this != exceeded;

  String get label {
    switch (this) {
      case DrReliability.good:     return 'Good';
      case DrReliability.warning:  return 'Caution';
      case DrReliability.exceeded: return 'Unreliable';
    }
  }
}

class DeadReckoningFix {
  /// Computed position (may be unreliable — always check [reliability]).
  final LatLng position;

  /// 95th-percentile position error in nautical miles.
  final double uncertaintyNm;

  /// How long since the last trusted fix.
  final Duration elapsed;

  /// Distance traveled since the last trusted fix (NM).
  final double distanceTraveledNm;

  /// Reliability category — drives UI color and warnings.
  final DrReliability reliability;

  /// Human-readable advisory message (empty when reliability == good).
  final String advisory;

  const DeadReckoningFix({
    required this.position,
    required this.uncertaintyNm,
    required this.elapsed,
    required this.distanceTraveledNm,
    required this.reliability,
    required this.advisory,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DeadReckoning engine
// ─────────────────────────────────────────────────────────────────────────────

class DeadReckoning {
  const DeadReckoning._();

  /// Compute a dead-reckoning fix from the last trusted position.
  ///
  /// [lastPosition]       — last GPS or celestial fix.
  /// [lastFixTime]        — UTC timestamp of that fix.
  /// [lastFixAccuracyNm]  — position error of the last fix in NM.
  /// [headingDeg]         — current compass heading (true north, 0–360).
  /// [speedKn]            — estimated speed over ground in knots.
  /// [now]                — current UTC time (defaults to [DateTime.now]).
  static DeadReckoningFix compute({
    required LatLng lastPosition,
    required DateTime lastFixTime,
    required double  lastFixAccuracyNm,
    required double  headingDeg,
    required double  speedKn,
    DateTime?        now,
  }) {
    final t = (now ?? DateTime.now()).toUtc();
    final elapsed = t.difference(lastFixTime);
    final elapsedHours = elapsed.inSeconds / 3600.0;

    // Clamp negative elapsed (clock skew guard)
    final safeElapsedHours = elapsedHours.clamp(0.0, double.infinity);

    // Distance traveled
    final distNm = speedKn * safeElapsedHours;

    // DR position via great-circle projection
    final pos = _projectPosition(lastPosition, headingDeg, distNm);

    // Uncertainty model:
    //   1. Inherit last fix accuracy
    //   2. Compass/leeway error: 5% of distance traveled
    //   3. Current/tidal drift: 0.3 NM/hour base rate
    final compassError = distNm * _kCompassErrorFactor;
    final driftError   = safeElapsedHours * _kDriftNmPerHour;
    final uncertainty  = lastFixAccuracyNm + compassError + driftError;

    final reliability = _classify(uncertainty);
    final advisory    = _advisory(reliability, uncertainty, elapsed);

    return DeadReckoningFix(
      position:            pos,
      uncertaintyNm:       uncertainty,
      elapsed:             elapsed,
      distanceTraveledNm:  distNm,
      reliability:         reliability,
      advisory:            advisory,
    );
  }

  /// Update an existing DR fix with a new celestial observation, resetting
  /// the uncertainty to the celestial fix accuracy (typically 3–5 NM).
  static DeadReckoningFix applycelestialUpdate({
    required LatLng celestialPosition,
    required double celestialAccuracyNm,
    required double headingDeg,
    required double speedKn,
    DateTime?       now,
  }) {
    return compute(
      lastPosition:       celestialPosition,
      lastFixTime:        (now ?? DateTime.now()).toUtc(),
      lastFixAccuracyNm:  celestialAccuracyNm,
      headingDeg:         headingDeg,
      speedKn:            speedKn,
      now:                now,
    );
  }

  // ── Haversine great-circle projection ────────────────────────────────────

  static LatLng _projectPosition(LatLng from, double bearingDeg, double distNm) {
    if (distNm <= 0) return from;

    final d    = distNm / _kEarthRadiusNm; // angular distance in radians
    final bear = bearingDeg * math.pi / 180.0;
    final lat1 = from.latitude  * math.pi / 180.0;
    final lng1 = from.longitude * math.pi / 180.0;

    final sinLat2 = math.sin(lat1) * math.cos(d)
        + math.cos(lat1) * math.sin(d) * math.cos(bear);
    final lat2 = math.asin(sinLat2.clamp(-1.0, 1.0));

    final lng2 = lng1 + math.atan2(
      math.sin(bear) * math.sin(d) * math.cos(lat1),
      math.cos(d) - math.sin(lat1) * math.sin(lat2),
    );

    return LatLng(
      lat2 * 180.0 / math.pi,
      ((lng2 * 180.0 / math.pi) + 540.0) % 360.0 - 180.0,
    );
  }

  static DrReliability _classify(double nm) {
    if (nm < kDrWarningNm)    return DrReliability.good;
    if (nm < kDrMaxReliableNm) return DrReliability.warning;
    return DrReliability.exceeded;
  }

  static String _advisory(DrReliability r, double nm, Duration elapsed) {
    switch (r) {
      case DrReliability.good:
        return '';
      case DrReliability.warning:
        return 'DR uncertainty ${nm.toStringAsFixed(1)} NM after '
               '${_fmtElapsed(elapsed)}. Seek GPS or celestial fix.';
      case DrReliability.exceeded:
        return 'DR uncertainty ${nm.toStringAsFixed(1)} NM EXCEEDS 2 NM '
               'after ${_fmtElapsed(elapsed)}. '
               'RECOMMEND: heave to and attempt celestial observation '
               'before continuing.';
    }
  }

  static String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// Haversine distance between two positions in nautical miles.
  static double distanceNm(LatLng a, LatLng b) {
    final lat1 = a.latitude  * math.pi / 180.0;
    final lat2 = b.latitude  * math.pi / 180.0;
    final dLat = (b.latitude  - a.latitude)  * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;

    final h = math.sin(dLat / 2) * math.sin(dLat / 2)
        + math.cos(lat1) * math.cos(lat2)
        * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * _kEarthRadiusNm * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  /// Initial bearing from [from] to [to] in degrees (true north, 0–360).
  static double bearingDeg(LatLng from, LatLng to) {
    final lat1 = from.latitude  * math.pi / 180.0;
    final lat2 = to.latitude    * math.pi / 180.0;
    final dLng = (to.longitude - from.longitude) * math.pi / 180.0;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2)
            - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }
}
