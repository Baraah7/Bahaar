import 'dart:math' as math;
import 'package:bahaar/models/ais_model.dart';

/// Computes Closest Point of Approach (CPA) between own vessel and a target.
///
/// Uses flat-earth vector projection (accurate for short ranges < 50 nm).
/// Based on standard maritime collision avoidance formula (COLREGS context).
class CpaCalculator {
  /// Alert threshold: CPA distance below this → danger
  static const double dangerDcpaNm = 0.5; // 0.5 nautical miles

  /// Warning threshold: CPA distance below this → caution
  static const double cautionDcpaNm = 1.0; // 1.0 nautical miles

  /// Ignore vessels with TCPA beyond this (already passed)
  static const double maxTcpaMinutes = 30.0;

  /// Meters per degree latitude (constant)
  static const double _mPerDegLat = 111319.9;

  /// Compute CPA for a target vessel relative to own position and velocity.
  ///
  /// [ownLat], [ownLon] — own vessel GPS position
  /// [ownSogKnots], [ownCogDeg] — own speed and course
  static CpaResult compute({
    required double ownLat,
    required double ownLon,
    required double ownSogKnots,
    required double ownCogDeg,
    required AisVessel target,
  }) {
    final mPerDegLon = _mPerDegLat * math.cos(ownLat * math.pi / 180);

    // Relative position of target (meters from own vessel, east-north frame)
    final dxM = (target.longitude - ownLon) * mPerDegLon; // east
    final dyM = (target.latitude - ownLat) * _mPerDegLat; // north

    // Own velocity vector (m/s, east-north)
    final ownSogMs = ownSogKnots * 0.514444;
    final ownCogRad = ownCogDeg * math.pi / 180;
    final ownVe = ownSogMs * math.sin(ownCogRad);
    final ownVn = ownSogMs * math.cos(ownCogRad);

    // Target velocity vector (m/s, east-north)
    final (tgtVe, tgtVn) = target.velocityVector;

    // Relative velocity (target relative to own)
    final dVe = tgtVe - ownVe;
    final dVn = tgtVn - ownVn;

    final relSpeedSq = dVe * dVe + dVn * dVn;

    double tcpaSeconds;
    if (relSpeedSq < 1e-6) {
      // Vessels moving in parallel — CPA is current range
      tcpaSeconds = 0;
    } else {
      // TCPA = -(r · dV) / |dV|²
      tcpaSeconds = -(dxM * dVe + dyM * dVn) / relSpeedSq;
    }

    final tcpaMinutes = tcpaSeconds / 60.0;

    double dcpaNm;
    if (tcpaSeconds <= 0) {
      // Already past CPA — use current range
      dcpaNm = _rangeNm(dxM, dyM);
    } else {
      // Project both vessels to TCPA
      final dxCpa = dxM + dVe * tcpaSeconds;
      final dyCpa = dyM + dVn * tcpaSeconds;
      dcpaNm = _rangeNm(dxCpa, dyCpa);
    }

    CollisionRisk risk;
    if (tcpaMinutes > maxTcpaMinutes || tcpaMinutes < 0) {
      risk = CollisionRisk.none;
    } else if (dcpaNm <= dangerDcpaNm) {
      risk = CollisionRisk.danger;
    } else if (dcpaNm <= cautionDcpaNm) {
      risk = CollisionRisk.caution;
    } else {
      risk = CollisionRisk.none;
    }

    return CpaResult(
      vessel: target,
      dcpaNm: dcpaNm,
      tcpaMinutes: tcpaMinutes.clamp(0, double.infinity),
      risk: risk,
    );
  }

  static double _rangeNm(double eastM, double northM) {
    const metersPerNm = 1852.0;
    return math.sqrt(eastM * eastM + northM * northM) / metersPerNm;
  }
}
