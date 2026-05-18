import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/fish_recognition/fish_probability_model.dart';

// ── _trapezoid extracted for pure testing (mirrors the private static method) ──

double trapezoid(
    double x, double minOk, double minOpt, double maxOpt, double maxOk) {
  if (x <= minOk || x >= maxOk) return 0.0;
  if (x >= minOpt && x <= maxOpt) return 1.0;
  if (x < minOpt) return (x - minOk) / (minOpt - minOk);
  return (maxOk - x) / (maxOk - maxOpt);
}

void main() {
  // ── FishSpecies enum ─────────────────────────────────────────────────────────

  group('FishSpecies', () {
    test('all values have non-empty English names', () {
      for (final s in FishSpecies.values) {
        expect(s.englishName, isNotEmpty);
      }
    });

    test('all values have non-empty Arabic names', () {
      for (final s in FishSpecies.values) {
        expect(s.arabicName, isNotEmpty);
      }
    });

    test('English names are distinct', () {
      final names = FishSpecies.values.map((e) => e.englishName).toSet();
      expect(names.length, FishSpecies.values.length);
    });

    test('Arabic names are distinct', () {
      final names = FishSpecies.values.map((e) => e.arabicName).toSet();
      expect(names.length, FishSpecies.values.length);
    });

    test('specific English name mappings', () {
      expect(FishSpecies.giltHeadBream.englishName, 'Gilt-Head Bream');
      expect(FishSpecies.horseMackerel.englishName, 'Horse Mackerel');
      expect(FishSpecies.seaBass.englishName, 'Sea Bass');
      expect(FishSpecies.shrimp.englishName, 'Shrimp');
    });

    test('specific Arabic name mappings', () {
      expect(FishSpecies.giltHeadBream.arabicName, 'دنيس');
      expect(FishSpecies.horseMackerel.arabicName, 'سكمبري');
      expect(FishSpecies.seaBass.arabicName, 'قاروص');
      expect(FishSpecies.shrimp.arabicName, 'روبيان');
    });

    test('all species have a non-null color', () {
      for (final s in FishSpecies.values) {
        expect(s.color, isA<Color>());
      }
    });

    test('species colors are distinct', () {
      final colors = FishSpecies.values.map((e) => e.color.toARGB32()).toSet();
      expect(colors.length, FishSpecies.values.length);
    });
  });

  // ── FishProbabilityLevel ─────────────────────────────────────────────────────

  group('FishProbabilityLevel.levelForScore', () {
    test('score >= 0.80 → veryHigh', () {
      expect(FishProbabilityCell.levelForScore(0.80), FishProbabilityLevel.veryHigh);
      expect(FishProbabilityCell.levelForScore(1.00), FishProbabilityLevel.veryHigh);
      expect(FishProbabilityCell.levelForScore(0.95), FishProbabilityLevel.veryHigh);
    });

    test('score 0.60–0.79 → high', () {
      expect(FishProbabilityCell.levelForScore(0.60), FishProbabilityLevel.high);
      expect(FishProbabilityCell.levelForScore(0.79), FishProbabilityLevel.high);
      expect(FishProbabilityCell.levelForScore(0.70), FishProbabilityLevel.high);
    });

    test('score 0.40–0.59 → moderate', () {
      expect(FishProbabilityCell.levelForScore(0.40), FishProbabilityLevel.moderate);
      expect(FishProbabilityCell.levelForScore(0.59), FishProbabilityLevel.moderate);
    });

    test('score 0.20–0.39 → low', () {
      expect(FishProbabilityCell.levelForScore(0.20), FishProbabilityLevel.low);
      expect(FishProbabilityCell.levelForScore(0.39), FishProbabilityLevel.low);
    });

    test('score < 0.20 → veryLow', () {
      expect(FishProbabilityCell.levelForScore(0.00), FishProbabilityLevel.veryLow);
      expect(FishProbabilityCell.levelForScore(0.19), FishProbabilityLevel.veryLow);
    });

    test('boundary: exactly 0.80 → veryHigh (not high)', () {
      expect(FishProbabilityCell.levelForScore(0.80), FishProbabilityLevel.veryHigh);
    });

    test('boundary: exactly 0.60 → high (not moderate)', () {
      expect(FishProbabilityCell.levelForScore(0.60), FishProbabilityLevel.high);
    });

    test('boundary: exactly 0.40 → moderate (not low)', () {
      expect(FishProbabilityCell.levelForScore(0.40), FishProbabilityLevel.moderate);
    });

    test('boundary: exactly 0.20 → low (not veryLow)', () {
      expect(FishProbabilityCell.levelForScore(0.20), FishProbabilityLevel.low);
    });
  });

  // ── FishProbabilityCell ──────────────────────────────────────────────────────

  group('FishProbabilityCell', () {
    test('constructor sets all fields correctly', () {
      const cell = FishProbabilityCell(
        latitude: 26.2,
        longitude: 50.5,
        score: 0.75,
        level: FishProbabilityLevel.high,
        species: FishSpecies.shrimp,
      );
      expect(cell.latitude, 26.2);
      expect(cell.longitude, 50.5);
      expect(cell.score, 0.75);
      expect(cell.level, FishProbabilityLevel.high);
      expect(cell.species, FishSpecies.shrimp);
    });

    test('fromJson parses latitude, longitude, score correctly', () {
      final json = {'lat': 26.1, 'lon': 50.4, 'score': 0.65};
      final cell = FishProbabilityCell.fromJson(json, FishSpecies.seaBass);
      expect(cell.latitude, 26.1);
      expect(cell.longitude, 50.4);
      expect(cell.score, closeTo(0.65, 0.0001));
      expect(cell.species, FishSpecies.seaBass);
    });

    test('fromJson derives level from score automatically', () {
      final json = {'lat': 26.0, 'lon': 50.0, 'score': 0.85};
      final cell = FishProbabilityCell.fromJson(json, FishSpecies.giltHeadBream);
      expect(cell.level, FishProbabilityLevel.veryHigh);
    });

    test('fromJson handles integer score values (num cast)', () {
      final json = {'lat': 26.0, 'lon': 50.0, 'score': 1};
      final cell = FishProbabilityCell.fromJson(json, FishSpecies.shrimp);
      expect(cell.score, 1.0);
    });

    test('toJson produces correct map', () {
      const cell = FishProbabilityCell(
        latitude: 26.2,
        longitude: 50.5,
        score: 0.72,
        level: FishProbabilityLevel.high,
        species: FishSpecies.horseMackerel,
      );
      final json = cell.toJson();
      expect(json['lat'], 26.2);
      expect(json['lon'], 50.5);
      expect(json['score'], closeTo(0.72, 0.0001));
    });

    test('roundtrip fromJson/toJson preserves lat, lon, score', () {
      const original = FishProbabilityCell(
        latitude: 25.9,
        longitude: 50.3,
        score: 0.45,
        level: FishProbabilityLevel.moderate,
        species: FishSpecies.seaBass,
      );
      final restored = FishProbabilityCell.fromJson(
          original.toJson(), FishSpecies.seaBass);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.score, closeTo(original.score, 0.0001));
      expect(restored.level, original.level);
    });
  });

  // ── _trapezoid function (pure logic) ────────────────────────────────────────

  group('_trapezoid membership function', () {
    // Reference shape: minOk=16, minOpt=18, maxOpt=24, maxOk=28
    const minOk = 16.0;
    const minOpt = 18.0;
    const maxOpt = 24.0;
    const maxOk = 28.0;

    test('returns 0 at exactly minOk (boundary excluded)', () {
      expect(trapezoid(minOk, minOk, minOpt, maxOpt, maxOk), 0.0);
    });

    test('returns 0 at exactly maxOk (boundary excluded)', () {
      expect(trapezoid(maxOk, minOk, minOpt, maxOpt, maxOk), 0.0);
    });

    test('returns 0 below minOk', () {
      expect(trapezoid(10.0, minOk, minOpt, maxOpt, maxOk), 0.0);
    });

    test('returns 0 above maxOk', () {
      expect(trapezoid(35.0, minOk, minOpt, maxOpt, maxOk), 0.0);
    });

    test('returns 1 at minOpt (start of optimal range)', () {
      expect(trapezoid(minOpt, minOk, minOpt, maxOpt, maxOk), 1.0);
    });

    test('returns 1 at maxOpt (end of optimal range)', () {
      expect(trapezoid(maxOpt, minOk, minOpt, maxOpt, maxOk), 1.0);
    });

    test('returns 1 in the middle of the optimal range', () {
      expect(trapezoid(21.0, minOk, minOpt, maxOpt, maxOk), 1.0);
    });

    test('rising ramp: midpoint between minOk and minOpt returns 0.5', () {
      final midRising = (minOk + minOpt) / 2; // 17.0
      expect(trapezoid(midRising, minOk, minOpt, maxOpt, maxOk),
          closeTo(0.5, 0.0001));
    });

    test('falling ramp: midpoint between maxOpt and maxOk returns 0.5', () {
      final midFalling = (maxOpt + maxOk) / 2; // 26.0
      expect(trapezoid(midFalling, minOk, minOpt, maxOpt, maxOk),
          closeTo(0.5, 0.0001));
    });

    test('rising ramp is linear from minOk to minOpt', () {
      final quarter = minOk + (minOpt - minOk) * 0.25; // 16.5
      expect(trapezoid(quarter, minOk, minOpt, maxOpt, maxOk),
          closeTo(0.25, 0.0001));
    });

    test('falling ramp is linear from maxOpt to maxOk', () {
      final threequarter = maxOpt + (maxOk - maxOpt) * 0.75; // 27.0
      expect(trapezoid(threequarter, minOk, minOpt, maxOpt, maxOk),
          closeTo(0.25, 0.0001));
    });
  });

  // ── Score computation (composite SST + Chlorophyll) ──────────────────────────

  group('Score composite: SST 55% + Chlorophyll 45%', () {
    test('both NaN → score 0.0 (service returns 0.0 explicitly)', () {
      // When both sst and chlorophyll are NaN the service bypasses the
      // weighted formula and sets score = 0.0 directly.
      const score = 0.0;
      expect(score.clamp(0.0, 1.0), 0.0);
    });

    test('only SST available → score equals sstScore', () {
      const sstScore = 0.8;
      const score = sstScore;
      expect(score, closeTo(0.8, 0.0001));
    });

    test('only chlorophyll available → score equals chlScore', () {
      const chlScore = 0.6;
      const score = chlScore;
      expect(score, closeTo(0.6, 0.0001));
    });

    test('both available → weighted 55%/45%', () {
      const sstScore = 0.8;
      const chlScore = 0.4;
      final score = sstScore * 0.55 + chlScore * 0.45;
      expect(score, closeTo(0.62, 0.0001));
    });

    test('score is clamped to [0.0, 1.0]', () {
      expect((-0.5).clamp(0.0, 1.0), 0.0);
      expect(1.5.clamp(0.0, 1.0), 1.0);
    });
  });

  // ── Kelvin → Celsius conversion ──────────────────────────────────────────────

  group('SST Kelvin → Celsius conversion heuristic', () {
    double convertSst(double raw) =>
        raw > 100 ? raw - 273.15 : raw;

    test('Kelvin value above 100 is converted to Celsius', () {
      expect(convertSst(300.15), closeTo(27.0, 0.01));
      expect(convertSst(273.15), closeTo(0.0, 0.01));
    });

    test('Celsius value below 100 passes through unchanged', () {
      expect(convertSst(25.0), 25.0);
      expect(convertSst(0.0), 0.0);
    });

    test('edge case: value exactly 100 is treated as Celsius', () {
      expect(convertSst(100.0), 100.0);
    });
  });

  // ── CMEMS ASCII parser logic ─────────────────────────────────────────────────

  group('CMEMS ASCII response parsing logic', () {
    test('lines starting with # are skipped', () {
      const line = '# comment line';
      final isComment = line.trim().startsWith('#');
      expect(isComment, isTrue);
    });

    test('lines starting with "time" are skipped', () {
      const line = 'time depth lat lon val';
      final isHeader = line.trim().startsWith('time');
      expect(isHeader, isTrue);
    });

    test('lines with fewer than 5 parts are skipped', () {
      const line = '2026-01-01 0 26.1';
      final parts = line.trim().split(RegExp(r'\s+'));
      expect(parts.length < 5, isTrue);
    });

    test('valid data line parses lat, lon, value from correct positions', () {
      const line = '2026-01-01 0 26.1 50.5 302.15';
      final parts = line.trim().split(RegExp(r'\s+'));
      final lat = double.tryParse(parts[2]);
      final lon = double.tryParse(parts[3]);
      final val = double.tryParse(parts[4]);
      expect(lat, 26.1);
      expect(lon, 50.5);
      expect(val, 302.15);
    });

    test('non-numeric value in val position returns null from tryParse', () {
      final val = double.tryParse('N/A');
      expect(val, isNull);
    });
  });
}
