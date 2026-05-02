import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/navigation/confidence_engine.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _engine = ConfidenceEngine(expectedStarsInRegion: 20);

/// Returns a ConfidenceResult using inputs that produce a 'fix' decision.
ConfidenceResult _goodResult() => _engine.evaluate(
      pitchSamplesWindow: List.filled(10, 0.0), // stdDev = 0
      detectedUsableStars: 20, // 100 % clarity
      primaryAltitudeDeg: 45.0,
      peakGyroDriftDegPerSec: 0.0,
    )!;

/// Inputs that produce a 'lowConfidenceWarning' decision (score 30–69).
/// Verified composite ≈ 46–48 using the exact factor formulas.
ConfidenceResult _warnResult() => _engine.evaluate(
      // stdDev ≈ 1.22, seaScore ≈ 87.75 (below halving threshold of > 2.0)
      pitchSamplesWindow: [1.0, -1.0, 1.5, -1.5, 1.0, -1.0, 1.5, -1.5, 1.0, -1.0],
      detectedUsableStars: 5, // clarityScore = 25
      primaryAltitudeDeg: 15.0, // altScore ≈ 8.54
      peakGyroDriftDegPerSec: 0.2, // imuScore = 60
    )!;

/// Inputs that produce a 'rejected' decision (score < 30).
/// Rough sea (stdDev > 2, halved), 1 star, near-minimum altitude, high drift.
ConfidenceResult _rejectedResult() => _engine.evaluate(
      // pitchSamplesWindow: alternating [0, 4.5], stdDev ≈ 2.25 → halved seaScore
      pitchSamplesWindow: [0.0, 4.5, 0.0, 4.5, 0.0, 4.5, 0.0, 4.5, 0.0, 4.5],
      detectedUsableStars: 1, // clarityScore = 5
      primaryAltitudeDeg: 9.0, // altScore ≈ 1.22 (just above hard reject)
      peakGyroDriftDegPerSec: 0.4, // imuScore = 20
    )!;

void main() {
  // ── Hard reject: empty pitch window ──────────────────────────────────────

  group('ConfidenceEngine.evaluate — empty pitch window', () {
    test('returns null when pitchSamplesWindow is empty', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 30.0,
        peakGyroDriftDegPerSec: 0.1,
      );
      expect(result, isNull);
    });
  });

  // ── Hard reject: altitude below 8° ───────────────────────────────────────

  group('ConfidenceEngine.evaluate — altitude hard reject', () {
    test('altitude < 8° returns rejected with score 0', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [0.0],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 7.9,
        peakGyroDriftDegPerSec: 0.1,
      );
      expect(result, isNotNull);
      expect(result!.decision, FixDecision.rejected);
      expect(result.score, 0);
    });

    test('altitude exactly 8° is NOT hard-rejected', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [0.0],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 8.0,
        peakGyroDriftDegPerSec: 0.1,
      );
      expect(result, isNotNull);
      expect(result!.decision, isNot(FixDecision.rejected));
    });

    test('hard-reject reason mentions altitude', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [0.0],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 5.0,
        peakGyroDriftDegPerSec: 0.1,
      );
      expect(result!.reason, contains('8°'));
    });
  });

  // ── Hard reject: gyro drift at or above 0.5 °/s ──────────────────────────

  group('ConfidenceEngine.evaluate — gyro drift hard reject', () {
    test('drift = 0.5 °/s returns rejected with score 0', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [0.0],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 30.0,
        peakGyroDriftDegPerSec: 0.5,
      );
      expect(result!.decision, FixDecision.rejected);
      expect(result.score, 0);
    });

    test('drift = 0.49 °/s passes the hard-reject gate', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: List.filled(10, 0.0),
        detectedUsableStars: 20,
        primaryAltitudeDeg: 45.0,
        peakGyroDriftDegPerSec: 0.49,
      );
      expect(result!.score, greaterThan(0));
    });

    test('drift > 0.5 °/s still returns rejected (>= threshold)', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [0.0],
        detectedUsableStars: 15,
        primaryAltitudeDeg: 30.0,
        peakGyroDriftDegPerSec: 1.0,
      );
      expect(result!.decision, FixDecision.rejected);
    });
  });

  // ── Decision thresholds ───────────────────────────────────────────────────

  group('ConfidenceEngine.evaluate — decision thresholds', () {
    test('ideal conditions produce a fix decision', () {
      final result = _goodResult();
      expect(result.decision, FixDecision.fix);
      expect(result.score, greaterThanOrEqualTo(70));
    });

    test('degraded conditions produce a lowConfidenceWarning decision', () {
      final result = _warnResult();
      expect(result.decision, FixDecision.lowConfidenceWarning);
      expect(result.score, inInclusiveRange(30, 69));
    });

    test('poor conditions produce a rejected decision (composite < 30)', () {
      final result = _rejectedResult();
      expect(result.decision, FixDecision.rejected);
      expect(result.score, lessThan(30));
    });
  });

  // ── Score is clamped to [0, 100] ─────────────────────────────────────────

  group('ConfidenceEngine.evaluate — score range', () {
    test('score never exceeds 100', () {
      expect(_goodResult().score, lessThanOrEqualTo(100));
    });

    test('score never goes below 0 for computed (non-hard-reject) results', () {
      expect(_rejectedResult().score, greaterThanOrEqualTo(0));
    });
  });

  // ── Weak factor list in lowConfidenceWarning ──────────────────────────────

  group('ConfidenceEngine.evaluate — weak factor labelling', () {
    test('reason mentions weak factors for lowConfidenceWarning', () {
      final result = _warnResult();
      // sky clarity (5/20=25%) and star altitude (15°) are both below 50
      expect(result.reason, contains('sky clarity'));
      expect(result.reason, contains('star altitude'));
    });

    test('lowConfidenceWarning reason mentions warning radius', () {
      final result = _warnResult();
      expect(result.reason, contains('5 NM'));
    });
  });

  // ── Factor weighting — sea state halving ─────────────────────────────────

  group('ConfidenceEngine.evaluate — rough-sea halving', () {
    test('stdDev > 2.0 halves the sea score, lowering overall composite', () {
      // Calm sea: all-zero pitch → seaScore = 100
      final calm = _engine.evaluate(
        pitchSamplesWindow: List.filled(10, 0.0),
        detectedUsableStars: 10,
        primaryAltitudeDeg: 20.0,
        peakGyroDriftDegPerSec: 0.1,
      )!;

      // Rough sea: alternating 0 / 5 → stdDev = 2.5 > 2.0 → seaScore halved
      final rough = _engine.evaluate(
        pitchSamplesWindow: [0.0, 5.0, 0.0, 5.0, 0.0, 5.0, 0.0, 5.0, 0.0, 5.0],
        detectedUsableStars: 10,
        primaryAltitudeDeg: 20.0,
        peakGyroDriftDegPerSec: 0.1,
      )!;

      expect(rough.score, lessThan(calm.score));
    });
  });

  // ── ConfidenceResult.color ────────────────────────────────────────────────

  group('ConfidenceResult.color', () {
    test('fix → green (0xFF4CAF50)', () {
      expect(_goodResult().color, const Color(0xFF4CAF50));
    });

    test('lowConfidenceWarning → amber (0xFFFFC107)', () {
      expect(_warnResult().color, const Color(0xFFFFC107));
    });

    test('rejected → red (0xFFF44336)', () {
      expect(_rejectedResult().color, const Color(0xFFF44336));
    });
  });

  // ── ConfidenceResult.toString ─────────────────────────────────────────────

  group('ConfidenceResult.toString', () {
    test('contains score and decision', () {
      final r = _goodResult();
      final s = r.toString();
      expect(s, contains('[DS-1]'));
      expect(s, contains('score='));
      expect(s, contains('fix'));
    });
  });

  // ── Single-sample pitch window ────────────────────────────────────────────

  group('ConfidenceEngine — single pitch sample', () {
    test('single sample does not return null (only empty does)', () {
      final result = _engine.evaluate(
        pitchSamplesWindow: [1.0],
        detectedUsableStars: 10,
        primaryAltitudeDeg: 30.0,
        peakGyroDriftDegPerSec: 0.1,
      );
      // _stdDev returns 0 for length < 2; not null, just treated as calm sea
      expect(result, isNotNull);
    });
  });

  // ── expectedStarsInRegion affects clarity score ───────────────────────────

  group('ConfidenceEngine — expectedStarsInRegion parameter', () {
    test('higher expected star count reduces clarity score for same detection', () {
      final highExp = const ConfidenceEngine(expectedStarsInRegion: 40).evaluate(
        pitchSamplesWindow: List.filled(5, 0.0),
        detectedUsableStars: 10,
        primaryAltitudeDeg: 45.0,
        peakGyroDriftDegPerSec: 0.0,
      )!;

      final lowExp = const ConfidenceEngine(expectedStarsInRegion: 10).evaluate(
        pitchSamplesWindow: List.filled(5, 0.0),
        detectedUsableStars: 10,
        primaryAltitudeDeg: 45.0,
        peakGyroDriftDegPerSec: 0.0,
      )!;

      // With same detectedStars=10: highExp clarity=25%, lowExp clarity=100%
      expect(lowExp.score, greaterThan(highExp.score));
    });
  });
}
