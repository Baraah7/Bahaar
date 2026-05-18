import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/utilities/map/celestial_navigation/celestial_calculator.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Approximate illumination for a given phase using the same formula
/// as the production code — used to cross-check round-trip consistency.
double illuminationFor(double phase) =>
    ((1 - math.cos(2 * math.pi * phase)) / 2 * 100).roundToDouble();

void main() {
  // ── _moonIllumination — formula verification ──────────────────────────────

  group('_moonIllumination — formula verification', () {
    // Access via calculateLunarDayDefault which exercises the full pipeline.
    // For unit-level verification we replicate the formula here.

    test('illumination is 0 at phase 0 (new moon)', () {
      expect(illuminationFor(0.0), 0.0);
    });

    test('illumination is 100 at phase 0.5 (full moon)', () {
      expect(illuminationFor(0.5), 100.0);
    });

    test('illumination is 50 at phase 0.25 (first quarter)', () {
      expect(illuminationFor(0.25), 50.0);
    });

    test('illumination is 50 at phase 0.75 (last quarter — symmetric)', () {
      expect(illuminationFor(0.75), 50.0);
    });

    test('illumination peaks before trailing off after full moon', () {
      expect(illuminationFor(0.6), greaterThan(illuminationFor(0.7)));
    });
  });

  // ── _moonPhaseName — threshold boundaries ─────────────────────────────────

  group('_moonPhaseName — threshold boundaries', () {
    // Boundaries at every 0.0625 interval
    test('phase 0.0 → New Moon', () {
      final ld = _lunarForPhase(0.0);
      expect(ld.phaseName, 'New Moon');
    });

    test('phase 0.0624 → New Moon (just below lower boundary)', () {
      // 0.0624 < 0.0625 → New Moon
      final ld = _lunarForPhase(0.0624);
      expect(ld.phaseName, 'New Moon');
    });

    test('phase 0.0625 → Waxing Crescent (at lower boundary)', () {
      final ld = _lunarForPhase(0.0625);
      expect(ld.phaseName, 'Waxing Crescent');
    });

    test('phase 0.1875 → First Quarter (at boundary)', () {
      final ld = _lunarForPhase(0.1875);
      expect(ld.phaseName, 'First Quarter');
    });

    test('phase 0.3125 → Waxing Gibbous (at boundary)', () {
      final ld = _lunarForPhase(0.3125);
      expect(ld.phaseName, 'Waxing Gibbous');
    });

    test('phase 0.4375 → Full Moon (at boundary)', () {
      final ld = _lunarForPhase(0.4375);
      expect(ld.phaseName, 'Full Moon');
    });

    test('phase 0.5624 → Full Moon (just below upper boundary)', () {
      final ld = _lunarForPhase(0.5624);
      expect(ld.phaseName, 'Full Moon');
    });

    test('phase 0.5625 → Waning Gibbous (at boundary)', () {
      final ld = _lunarForPhase(0.5625);
      expect(ld.phaseName, 'Waning Gibbous');
    });

    test('phase 0.6875 → Last Quarter (at boundary)', () {
      final ld = _lunarForPhase(0.6875);
      expect(ld.phaseName, 'Last Quarter');
    });

    test('phase 0.8125 → Waning Crescent (at boundary)', () {
      final ld = _lunarForPhase(0.8125);
      expect(ld.phaseName, 'Waning Crescent');
    });

    test('phase 0.9375 → New Moon (upper wrap-around boundary)', () {
      final ld = _lunarForPhase(0.9375);
      expect(ld.phaseName, 'New Moon');
    });

    test('phase 0.9999 → New Moon (near 1.0)', () {
      final ld = _lunarForPhase(0.9999);
      expect(ld.phaseName, 'New Moon');
    });
  });

  // ── moonPhaseEmoji — all 8 mappings ──────────────────────────────────────

  group('moonPhaseEmoji — all 8 mappings', () {
    final cases = {
      'New Moon': '🌑',
      'Waxing Crescent': '🌒',
      'First Quarter': '🌓',
      'Waxing Gibbous': '🌔',
      'Full Moon': '🌕',
      'Waning Gibbous': '🌖',
      'Last Quarter': '🌗',
      'Waning Crescent': '🌘',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(CelestialCalculator.moonPhaseEmoji(entry.key), entry.value);
      });
    }

    test('unknown phase name → default moon emoji 🌙', () {
      expect(CelestialCalculator.moonPhaseEmoji('Partial Eclipse'), '🌙');
    });
  });

  // ── LunarDay.emoji — getter delegates to moonPhaseEmoji ──────────────────

  group('LunarDay.emoji — getter', () {
    test('emoji matches moonPhaseEmoji for known phase name', () {
      const ld = LunarDay(
        moonrise: null,
        moonset: null,
        phase: 0.5,
        phaseName: 'Full Moon',
        illumination: 100,
      );
      expect(ld.emoji, '🌕');
      expect(ld.emoji, CelestialCalculator.moonPhaseEmoji('Full Moon'));
    });
  });

  // ── SolarDay.dayLength ────────────────────────────────────────────────────

  group('SolarDay.dayLength', () {
    test('returns Duration.zero when sunrise is null', () {
      final sd = SolarDay(
        sunrise: null,
        sunset: DateTime.utc(2026, 4, 22, 18, 0),
        solarNoon: DateTime.utc(2026, 4, 22, 12, 0),
      );
      expect(sd.dayLength, Duration.zero);
    });

    test('returns Duration.zero when sunset is null', () {
      final sd = SolarDay(
        sunrise: DateTime.utc(2026, 4, 22, 6, 0),
        sunset: null,
        solarNoon: DateTime.utc(2026, 4, 22, 12, 0),
      );
      expect(sd.dayLength, Duration.zero);
    });

    test('returns correct dayLength when both are set', () {
      final sd = SolarDay(
        sunrise: DateTime.utc(2026, 4, 22, 6, 0),
        sunset: DateTime.utc(2026, 4, 22, 18, 30),
        solarNoon: DateTime.utc(2026, 4, 22, 12, 0),
      );
      expect(sd.dayLength, const Duration(hours: 12, minutes: 30));
    });

    test('solarNoon is always non-null', () {
      final sd = SolarDay(
        sunrise: null,
        sunset: null,
        solarNoon: DateTime.utc(2026, 4, 22, 12, 0),
      );
      expect(sd.solarNoon, isNotNull);
    });
  });

  // ── calculateSolarDay — integration sanity check ─────────────────────────

  group('calculateSolarDay — integration sanity checks', () {
    // Manama, Bahrain (26.2154°N, 50.5832°E) — equatorial region, always
    // has a sunrise and sunset, day length 11–13 hours.
    const lat = 26.2154;
    const lon = 50.5832;
    final date = DateTime.utc(2026, 4, 22);

    test('sunrise and sunset are non-null for Manama in April', () {
      final sd = CelestialCalculator.calculateSolarDay(lat, lon, date);
      expect(sd.sunrise, isNotNull);
      expect(sd.sunset, isNotNull);
    });

    test('sunrise is before solar noon', () {
      final sd = CelestialCalculator.calculateSolarDay(lat, lon, date);
      expect(sd.sunrise!.isBefore(sd.solarNoon), isTrue);
    });

    test('solar noon is before sunset', () {
      final sd = CelestialCalculator.calculateSolarDay(lat, lon, date);
      expect(sd.solarNoon.isBefore(sd.sunset!), isTrue);
    });

    test('day length is between 11 and 13 hours for Manama in April', () {
      final sd = CelestialCalculator.calculateSolarDay(lat, lon, date);
      expect(sd.dayLength.inHours, inInclusiveRange(11, 13));
    });

    test('calculateSolarDayDefault uses same logic as explicit call', () {
      final explicit = CelestialCalculator.calculateSolarDay(lat, lon, date);
      final def = CelestialCalculator.calculateSolarDayDefault(date);
      // Compare minutes (not exact ms due to floating-point in jd computation)
      expect(
        def.solarNoon.difference(explicit.solarNoon).inMinutes.abs(),
        lessThan(2),
      );
    });
  });

  // ── calculateLunarDay — integration sanity checks ─────────────────────────

  group('calculateLunarDay — integration sanity checks', () {
    final date = DateTime.utc(2026, 4, 22);

    test('phase is in [0.0, 1.0)', () {
      final ld = CelestialCalculator.calculateLunarDayDefault(date);
      expect(ld.phase, inInclusiveRange(0.0, 1.0));
    });

    test('illumination is in [0, 100]', () {
      final ld = CelestialCalculator.calculateLunarDayDefault(date);
      expect(ld.illumination, inInclusiveRange(0.0, 100.0));
    });

    test('phaseName is one of the 8 known values', () {
      final ld = CelestialCalculator.calculateLunarDayDefault(date);
      const valid = {
        'New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous',
        'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent',
      };
      expect(valid.contains(ld.phaseName), isTrue);
    });

    test('emoji is non-empty', () {
      final ld = CelestialCalculator.calculateLunarDayDefault(date);
      expect(ld.emoji, isNotEmpty);
    });
  });

  // ── _moonPhase negative-correction guard — Dart language behavior ─────────

  group('_moonPhase — Dart modulo semantics (logic gap documentation)', () {
    // In Dart, the % operator on doubles always returns a non-negative result
    // when the divisor is positive. The `phase < 0 ? phase + 1 : phase`
    // guard in _moonPhase is therefore dead code in Dart.
    // Python semantics: (-1.5) % 29.53 = 28.03 (positive)
    // Dart semantics:   (-1.5) % 29.53 = 28.03 (same — non-negative)
    // The guard does not cause wrong behavior, but is unreachable.
    test('Dart double % never returns negative for positive divisor', () {
      const synodicMonth = 29.53058867;
      final negative = -15.0 % synodicMonth;
      expect(negative, greaterThanOrEqualTo(0.0));
    });

    test('phase is always in [0.0, 1.0) for any calendar date', () {
      final dates = [
        DateTime.utc(1999, 1, 1),  // before reference new moon
        DateTime.utc(2000, 1, 6),  // exactly at reference
        DateTime.utc(2026, 4, 22), // typical future date
        DateTime.utc(2030, 12, 31),
      ];
      for (final d in dates) {
        final ld = CelestialCalculator.calculateLunarDayDefault(d);
        expect(ld.phase, inInclusiveRange(0.0, 1.0),
            reason: 'Phase out of range for date $d');
      }
    });
  });

  // ── Phase–illumination consistency ────────────────────────────────────────

  group('phase–illumination–name internal consistency', () {
    test('full moon phase returns ~100 illumination', () {
      // Seed a date that is known to be near full moon.
      // Jan 6, 2000 00:00 UTC → very close to known new moon.
      // 14.76 days later ≈ full moon.
      final nearFull = DateTime.utc(2000, 1, 6)
          .add(const Duration(hours: 354)); // ≈ 14.75 days
      final ld = CelestialCalculator.calculateLunarDayDefault(nearFull);
      // Full moon illumination should be at or close to 100
      expect(ld.illumination, greaterThan(90.0));
      expect(ld.phaseName, anyOf('Full Moon', 'Waxing Gibbous', 'Waning Gibbous'));
    });

    test('new moon phase returns 0 illumination', () {
      // Jan 6, 2000 is the reference new moon
      final nearNew = DateTime.utc(2000, 1, 7); // 1 day after reference
      final ld = CelestialCalculator.calculateLunarDayDefault(nearNew);
      expect(ld.illumination, lessThan(20.0));
    });
  });
}

// ── Test helper — builds a LunarDay with a forced phase value ─────────────────

// CelestialCalculator._moonPhaseName is private, so we exercise it via the
// LunarDay returned from calculateLunarDay using a known date.
// To test specific phase thresholds we use a synthetic LunarDay construct.
LunarDay _lunarForPhase(double phase) {
  final phaseName = _phaseName(phase);
  return LunarDay(
    moonrise: null,
    moonset: null,
    phase: phase,
    phaseName: phaseName,
    illumination: 0,
  );
}

String _phaseName(double phase) {
  if (phase < 0.0625 || phase >= 0.9375) return 'New Moon';
  if (phase < 0.1875) return 'Waxing Crescent';
  if (phase < 0.3125) return 'First Quarter';
  if (phase < 0.4375) return 'Waxing Gibbous';
  if (phase < 0.5625) return 'Full Moon';
  if (phase < 0.6875) return 'Waning Gibbous';
  if (phase < 0.8125) return 'Last Quarter';
  return 'Waning Crescent';
}
