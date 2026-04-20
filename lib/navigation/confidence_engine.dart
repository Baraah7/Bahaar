import 'dart:math' as math;
import 'package:flutter/material.dart';

/// DS-1 confidence scoring — determines whether conditions allow a fix.
///
/// Weights (per blueprint):
///   Sea State    30% — pitch standard deviation from rolling IMU window
///   Sky Clarity  25% — detected usable stars vs. expected count
///   Star Altitude 25% — primary star altitude (hard 0 below 8°)
///   IMU Health   20% — peak gyro drift rate
enum FixDecision {
  /// Fix is reliable. Display normally.
  fix,

  /// Fix computed but uncertain. Display with 5 NM dashed warning radius.
  lowConfidenceWarning,

  /// Conditions too poor. Do NOT display a position. Show refusal message.
  rejected,
}

class ConfidenceResult {
  final int score; // 0–100 composite
  final FixDecision decision;

  /// Human-readable reason — log and surface in the UI.
  final String reason;

  const ConfidenceResult({
    required this.score,
    required this.decision,
    required this.reason,
  });

  Color get color {
    if (decision == FixDecision.fix) return const Color(0xFF4CAF50);
    if (decision == FixDecision.lowConfidenceWarning) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  @override
  String toString() => '[DS-1] score=$score $decision — $reason';
}

class ConfidenceEngine {
  static const int _kThresholdFix = 70;
  static const int _kThresholdWarn = 30;
  static const double _kMinAltitude = 8.0;
  static const double _kMaxGyroDrift = 0.5; // °/s
  static const double _kRoughSeaStdDev = 2.0; // degrees

  final int expectedStarsInRegion;
  const ConfidenceEngine({this.expectedStarsInRegion = 20});

  /// Evaluate conditions for a navigation fix.
  ///
  /// [pitchSamplesWindow] — rolling pitch values (degrees) from ≥ 2 IMU readings.
  /// [detectedUsableStars] — count of stars above 8° found by the vision engine.
  /// [primaryAltitudeDeg] — altitude of the primary sighting star (degrees).
  /// [peakGyroDriftDegPerSec] — worst gyro drift seen in the IMU window.
  ///
  /// Returns null only if [pitchSamplesWindow] is empty (structural error).
  ConfidenceResult? evaluate({
    required List<double> pitchSamplesWindow,
    required int detectedUsableStars,
    required double primaryAltitudeDeg,
    required double peakGyroDriftDegPerSec,
  }) {
    if (pitchSamplesWindow.isEmpty) return null;

    // ── Hard rejects ────────────────────────────────────────────────────────
    if (primaryAltitudeDeg < _kMinAltitude) {
      return ConfidenceResult(
        score: 0,
        decision: FixDecision.rejected,
        reason: 'Primary star at ${primaryAltitudeDeg.toStringAsFixed(1)}° '
            '< 8° minimum. Refraction error exceeds 10 NM.',
      );
    }
    if (peakGyroDriftDegPerSec >= _kMaxGyroDrift) {
      return ConfidenceResult(
        score: 0,
        decision: FixDecision.rejected,
        reason: 'Gyro drift ${peakGyroDriftDegPerSec.toStringAsFixed(3)} °/s '
            '≥ 0.5 °/s. IMU recalibration required.',
      );
    }

    // ── Factor 1: Sea State (30%) ────────────────────────────────────────────
    final pitchStdDev = _stdDev(pitchSamplesWindow);
    double seaScore = (100.0 - pitchStdDev * 10.0).clamp(0.0, 100.0);
    if (pitchStdDev > _kRoughSeaStdDev) seaScore /= 2.0; // halve for rough seas

    // ── Factor 2: Sky Clarity (25%) ─────────────────────────────────────────
    final clarityScore =
        (detectedUsableStars / expectedStarsInRegion * 100.0).clamp(0.0, 100.0);

    // ── Factor 3: Star Altitude (25%) ────────────────────────────────────────
    final altScore = ((primaryAltitudeDeg - _kMinAltitude) /
            (90.0 - _kMinAltitude) *
            100.0)
        .clamp(0.0, 100.0);

    // ── Factor 4: IMU Health (20%) ───────────────────────────────────────────
    // Linear from 100 (0 °/s drift) down to 0 (at hard-reject limit of 0.5 °/s)
    final imuScore =
        ((1.0 - peakGyroDriftDegPerSec / _kMaxGyroDrift) * 100.0).clamp(0.0, 100.0);

    // ── Weighted composite ────────────────────────────────────────────────────
    final composite = seaScore * 0.30
        + clarityScore * 0.25
        + altScore * 0.25
        + imuScore * 0.20;

    final score = composite.round().clamp(0, 100);

    // ── Decision ─────────────────────────────────────────────────────────────
    if (score >= _kThresholdFix) {
      return ConfidenceResult(
        score: score,
        decision: FixDecision.fix,
        reason: 'Conditions nominal. '
            'Sea ${seaScore.toInt()} / Sky ${clarityScore.toInt()} / '
            'Alt ${altScore.toInt()} / IMU ${imuScore.toInt()}.',
      );
    }
    if (score >= _kThresholdWarn) {
      final List<String> weak = [];
      if (seaScore < 50) weak.add('sea state');
      if (clarityScore < 50) weak.add('sky clarity');
      if (altScore < 50) weak.add('star altitude');
      if (imuScore < 50) weak.add('IMU health');
      return ConfidenceResult(
        score: score,
        decision: FixDecision.lowConfidenceWarning,
        reason: 'Low confidence (score $score): ${weak.join(', ')}. '
            'Fix shown with 5 NM warning radius.',
      );
    }
    return ConfidenceResult(
      score: score,
      decision: FixDecision.rejected,
      reason: 'Score $score < 30. Conditions unstable. Cannot compute position.',
    );
  }

  static double _stdDev(List<double> v) {
    if (v.length < 2) return 0.0;
    final mean = v.reduce((a, b) => a + b) / v.length;
    final variance =
        v.map((x) => math.pow(x - mean, 2).toDouble()).reduce((a, b) => a + b) /
            v.length;
    return math.sqrt(variance);
  }
}
