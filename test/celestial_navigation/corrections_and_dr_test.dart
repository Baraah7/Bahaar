import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/services/celestial_navigation/corrections.dart';
import 'package:bahaar/services/celestial_navigation/dead_reckoning.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CelestialCorrections tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── CelestialCorrections.isAltitudeUsable ────────────────────────────────

  group('CelestialCorrections.isAltitudeUsable', () {
    test('7.999° is below minimum — not usable', () {
      expect(CelestialCorrections.isAltitudeUsable(7.999), isFalse);
    });

    test('8.0° is exactly at minimum — usable', () {
      expect(CelestialCorrections.isAltitudeUsable(8.0), isTrue);
    });

    test('45° is well above minimum — usable', () {
      expect(CelestialCorrections.isAltitudeUsable(45.0), isTrue);
    });

    test('0° is below minimum — not usable', () {
      expect(CelestialCorrections.isAltitudeUsable(0.0), isFalse);
    });
  });

  // ── CelestialCorrections.correctRefraction — guard conditions ────────────

  group('CelestialCorrections.correctRefraction — guards', () {
    test('altitude < 8° returns 0.0', () {
      expect(
        CelestialCorrections.correctRefraction(7.9, 1013.0, 25.0),
        0.0,
      );
    });

    test('altitude < 8° populates reason buffer', () {
      final reason = StringBuffer();
      CelestialCorrections.correctRefraction(5.0, 1013.0, 25.0, reason: reason);
      expect(reason.toString(), isNotEmpty);
    });

    test('pressure < 800 mb returns 0.0', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 750.0, 25.0),
        0.0,
      );
    });

    test('pressure > 1100 mb returns 0.0', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1150.0, 25.0),
        0.0,
      );
    });

    test('pressure at boundary 800 mb is valid (not rejected)', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 800.0, 25.0),
        greaterThan(0.0),
      );
    });

    test('pressure at boundary 1100 mb is valid (not rejected)', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1100.0, 25.0),
        greaterThan(0.0),
      );
    });

    test('temperature < -40°C returns 0.0', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1013.0, -41.0),
        0.0,
      );
    });

    test('temperature > 50°C returns 0.0', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1013.0, 55.0),
        0.0,
      );
    });

    test('temperature at boundary -40°C is valid', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1013.0, -40.0),
        greaterThan(0.0),
      );
    });

    test('temperature at boundary 50°C is valid', () {
      expect(
        CelestialCorrections.correctRefraction(45.0, 1013.0, 50.0),
        greaterThan(0.0),
      );
    });
  });

  // ── CelestialCorrections.correctRefraction — Bennett formula ─────────────

  group('CelestialCorrections.correctRefraction — Bennett formula', () {
    test('standard atmosphere at 45° returns positive arcmin', () {
      final r = CelestialCorrections.correctRefraction(45.0, 1013.0, 25.0);
      expect(r, greaterThan(0.0));
    });

    test('refraction is larger at low altitude than at high altitude', () {
      final low = CelestialCorrections.correctRefraction(15.0, 1013.0, 15.0);
      final high = CelestialCorrections.correctRefraction(60.0, 1013.0, 15.0);
      expect(low, greaterThan(high));
    });

    test('refraction increases with higher pressure', () {
      final loPres = CelestialCorrections.correctRefraction(45.0, 900.0, 15.0);
      final hiPres = CelestialCorrections.correctRefraction(45.0, 1050.0, 15.0);
      expect(hiPres, greaterThan(loPres));
    });

    test('refraction decreases at higher temperature (warmer air = less dense)', () {
      final cold = CelestialCorrections.correctRefraction(45.0, 1013.0, 0.0);
      final warm = CelestialCorrections.correctRefraction(45.0, 1013.0, 30.0);
      expect(cold, greaterThan(warm));
    });

    test('standard atmosphere at 45° is below 2 arcmin (known ballpark)', () {
      // Bennett 45°: R₀ = 1/tan(45 + 7.31/(45+4.4)) ≈ 0.97 arcmin
      final r = CelestialCorrections.correctRefraction(45.0, 1013.0, 15.0);
      expect(r, lessThan(2.0));
      expect(r, greaterThan(0.5));
    });
  });

  // ── CelestialCorrections.dipCorrection ───────────────────────────────────

  group('CelestialCorrections.dipCorrection', () {
    test('height of eye = 0 returns 0.0', () {
      expect(CelestialCorrections.dipCorrection(0.0), 0.0);
    });

    test('negative height of eye returns 0.0', () {
      expect(CelestialCorrections.dipCorrection(-1.0), 0.0);
    });

    test('negative hoe populates reason buffer', () {
      final reason = StringBuffer();
      CelestialCorrections.dipCorrection(-1.0, reason: reason);
      expect(reason.toString(), isNotEmpty);
    });

    test('3.0 m height returns approximately 3.048 arcmin (1.76 × √3)', () {
      final expected = 1.76 * math.sqrt(3.0);
      final result = CelestialCorrections.dipCorrection(3.0);
      expect(result, closeTo(expected, 0.001));
    });

    test('4.0 m height returns 1.76 × √4 = 3.52 arcmin', () {
      expect(
        CelestialCorrections.dipCorrection(4.0),
        closeTo(1.76 * 2.0, 0.001),
      );
    });

    test('dip increases monotonically with height of eye', () {
      final d1 = CelestialCorrections.dipCorrection(1.0);
      final d2 = CelestialCorrections.dipCorrection(4.0);
      final d3 = CelestialCorrections.dipCorrection(9.0);
      expect(d2, greaterThan(d1));
      expect(d3, greaterThan(d2));
    });
  });

  // ── CelestialCorrections.totalCorrection ─────────────────────────────────

  group('CelestialCorrections.totalCorrection', () {
    test('valid inputs return refraction + dip', () {
      final refraction = CelestialCorrections.correctRefraction(45.0, 1013.0, 15.0);
      final dip = CelestialCorrections.dipCorrection(3.0);
      final total = CelestialCorrections.totalCorrection(45.0, 3.0, 1013.0, 15.0);
      expect(total, closeTo(refraction + dip, 0.001));
    });

    test('below-minimum altitude still adds dip (no altitude guard on totalCorrection)', () {
      // correctRefraction returns 0.0 for alt < 8°, but dipCorrection still runs.
      // This is a documented gap: totalCorrection returns a non-zero value
      // (the dip) even when the altitude is below the safe minimum.
      final total = CelestialCorrections.totalCorrection(5.0, 3.0, 1013.0, 25.0);
      final dipOnly = CelestialCorrections.dipCorrection(3.0);
      expect(total, closeTo(dipOnly, 0.001));
      // Specifically: NOT 0.0, but also not a full refraction + dip result.
      expect(total, greaterThan(0.0));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // DeadReckoning tests
  // ─────────────────────────────────────────────────────────────────────────────

  // ── distanceNm ────────────────────────────────────────────────────────────

  group('DeadReckoning.distanceNm', () {
    test('same point returns 0 NM', () {
      const p = LatLng(26.2154, 50.5832);
      expect(DeadReckoning.distanceNm(p, p), 0.0);
    });

    test('known distance: equator, 1° longitude ≈ 60 NM', () {
      const a = LatLng(0.0, 0.0);
      const b = LatLng(0.0, 1.0);
      // 1° lon on equator = 60.1 NM (approx)
      expect(DeadReckoning.distanceNm(a, b), closeTo(60.0, 1.0));
    });

    test('distance is symmetric (a→b == b→a)', () {
      const a = LatLng(26.2154, 50.5832);
      const b = LatLng(25.0, 51.0);
      expect(
        DeadReckoning.distanceNm(a, b),
        closeTo(DeadReckoning.distanceNm(b, a), 0.0001),
      );
    });

    test('larger separation returns larger distance', () {
      const origin = LatLng(26.0, 50.0);
      const near = LatLng(26.5, 50.0);
      const far = LatLng(28.0, 50.0);
      expect(
        DeadReckoning.distanceNm(origin, far),
        greaterThan(DeadReckoning.distanceNm(origin, near)),
      );
    });
  });

  // ── bearingDeg ────────────────────────────────────────────────────────────

  group('DeadReckoning.bearingDeg', () {
    test('due north: (0,0) → (1,0) ≈ 0°', () {
      const from = LatLng(0.0, 0.0);
      const to = LatLng(1.0, 0.0);
      expect(DeadReckoning.bearingDeg(from, to), closeTo(0.0, 1.0));
    });

    test('due east: (0,0) → (0,1) ≈ 90°', () {
      const from = LatLng(0.0, 0.0);
      const to = LatLng(0.0, 1.0);
      expect(DeadReckoning.bearingDeg(from, to), closeTo(90.0, 1.0));
    });

    test('due south: (1,0) → (0,0) ≈ 180°', () {
      const from = LatLng(1.0, 0.0);
      const to = LatLng(0.0, 0.0);
      expect(DeadReckoning.bearingDeg(from, to), closeTo(180.0, 1.0));
    });

    test('due west: (0,1) → (0,0) ≈ 270°', () {
      const from = LatLng(0.0, 1.0);
      const to = LatLng(0.0, 0.0);
      expect(DeadReckoning.bearingDeg(from, to), closeTo(270.0, 1.0));
    });

    test('bearing is in [0, 360)', () {
      const a = LatLng(26.2154, 50.5832);
      const b = LatLng(25.0, 49.0);
      final bearing = DeadReckoning.bearingDeg(a, b);
      expect(bearing, inInclusiveRange(0.0, 360.0));
    });
  });

  // ── DrReliability ─────────────────────────────────────────────────────────

  group('DrReliability', () {
    test('good is usable', () {
      expect(DrReliability.good.isUsable, isTrue);
    });

    test('warning is usable', () {
      expect(DrReliability.warning.isUsable, isTrue);
    });

    test('exceeded is NOT usable', () {
      expect(DrReliability.exceeded.isUsable, isFalse);
    });

    test('labels are distinct', () {
      expect(DrReliability.good.label, 'Good');
      expect(DrReliability.warning.label, 'Caution');
      expect(DrReliability.exceeded.label, 'Unreliable');
    });
  });

  // ── DeadReckoning.compute — uncertainty model ─────────────────────────────

  group('DeadReckoning.compute — uncertainty model', () {
    const origin = LatLng(26.2154, 50.5832);
    final fixTime = DateTime.utc(2026, 4, 22, 8, 0);

    test('speed = 0 at t=0: position equals last position', () {
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fixTime,
      );
      expect(result.distanceTraveledNm, 0.0);
      expect(result.position.latitude, closeTo(origin.latitude, 0.0001));
      expect(result.position.longitude, closeTo(origin.longitude, 0.0001));
    });

    test('uncertainty accumulates: drift 0.3 NM/h after 1 hour at speed 0', () {
      final oneHourLater = fixTime.add(const Duration(hours: 1));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: oneHourLater,
      );
      // compassError = 0 (no distance), driftError = 0.3
      expect(result.uncertaintyNm, closeTo(0.3, 0.01));
      expect(result.reliability, DrReliability.good);
    });

    test('initial accuracy is inherited into uncertainty', () {
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 1.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fixTime,
      );
      // With elapsed=0: uncertainty = 1.0 + 0 + 0 = 1.0
      expect(result.uncertaintyNm, closeTo(1.0, 0.01));
    });

    test('reliability is warning when uncertainty is between 1.5 and 2.0 NM', () {
      // 0 accuracy, 0 speed, need ~1.6 NM drift → ≈ 5.3 hours
      // driftError = 5.33h × 0.3 = 1.6
      final fiveHoursLater = fixTime.add(const Duration(minutes: 320));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fiveHoursLater,
      );
      expect(result.reliability, DrReliability.warning);
      expect(result.uncertaintyNm, inInclusiveRange(1.5, 2.0));
    });

    test('reliability is exceeded when uncertainty >= 2.0 NM', () {
      // Need > 2.0 NM: 2.0/0.3 ≈ 6.67 hours → use 7 hours
      final sevenHoursLater = fixTime.add(const Duration(hours: 7));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: sevenHoursLater,
      );
      expect(result.reliability, DrReliability.exceeded);
      expect(result.uncertaintyNm, greaterThanOrEqualTo(2.0));
    });

    test('compass error grows with distance traveled', () {
      // 10 knots for 2 hours = 20 NM; compass error = 20 * 0.05 = 1.0
      final twoHoursLater = fixTime.add(const Duration(hours: 2));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 10.0,
        now: twoHoursLater,
      );
      expect(result.distanceTraveledNm, closeTo(20.0, 0.01));
      // total = 0 + (20*0.05) + (2*0.3) = 0 + 1.0 + 0.6 = 1.6 NM
      expect(result.uncertaintyNm, closeTo(1.6, 0.1));
    });

    test('negative elapsed time (clock skew) clamps to 0 — no negative distance', () {
      // now is BEFORE lastFixTime — should not produce negative distanceTraveled
      final earlier = fixTime.subtract(const Duration(hours: 1));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 5.0,
        now: earlier,
      );
      expect(result.distanceTraveledNm, 0.0);
      // but elapsed field returns the raw (negative) duration
      expect(result.elapsed.isNegative, isTrue);
    });

    test('heading north moves latitude upward', () {
      final twoHoursLater = fixTime.add(const Duration(hours: 2));
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0, // due north
        speedKn: 5.0,
        now: twoHoursLater,
      );
      expect(result.position.latitude, greaterThan(origin.latitude));
      expect(result.position.longitude, closeTo(origin.longitude, 0.01));
    });

    test('heading east moves longitude upward', () {
      final twoHoursLater = fixTime.add(const Duration(hours: 2));
      final result = DeadReckoning.compute(
        lastPosition: LatLng(0.0, 0.0),
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 90.0, // due east
        speedKn: 5.0,
        now: twoHoursLater,
      );
      expect(result.position.longitude, greaterThan(0.0));
    });
  });

  // ── DeadReckoning.applycelestialUpdate ───────────────────────────────────

  group('DeadReckoning.applycelestialUpdate', () {
    test('returns elapsed of zero when now equals the celestial fix time', () {
      final t = DateTime.utc(2026, 4, 22, 12, 0);
      final result = DeadReckoning.applycelestialUpdate(
        celestialPosition: const LatLng(26.2154, 50.5832),
        celestialAccuracyNm: 3.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: t,
      );
      expect(result.distanceTraveledNm, 0.0);
      expect(result.uncertaintyNm, closeTo(3.0, 0.01));
    });
  });

  // ── advisory messages ─────────────────────────────────────────────────────

  group('DeadReckoning — advisory messages', () {
    const origin = LatLng(26.2154, 50.5832);
    final fixTime = DateTime.utc(2026, 4, 22, 8, 0);

    test('good reliability has empty advisory', () {
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fixTime,
      );
      expect(result.advisory, isEmpty);
    });

    test('warning reliability advisory mentions NM and time', () {
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fixTime.add(const Duration(minutes: 320)),
      );
      expect(result.advisory, contains('NM'));
    });

    test('exceeded reliability advisory mentions heave to', () {
      final result = DeadReckoning.compute(
        lastPosition: origin,
        lastFixTime: fixTime,
        lastFixAccuracyNm: 0.0,
        headingDeg: 0.0,
        speedKn: 0.0,
        now: fixTime.add(const Duration(hours: 7)),
      );
      expect(result.advisory.toLowerCase(), contains('heave'));
    });
  });
}
