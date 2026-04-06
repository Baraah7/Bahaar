import 'dart:math' as math;

/// Atmospheric refraction (Bennett 1982) and observer dip corrections.
///
/// Every function returns 0.0 — never throws — on invalid input and
/// provides a human-readable [reason] for the failure.
class CelestialCorrections {
  CelestialCorrections._();

  static const double kMinAltitudeDeg = 8.0;

  /// True if [altitudeDeg] is within the safe usable range (≥ 8°).
  static bool isAltitudeUsable(double altitudeDeg) =>
      altitudeDeg >= kMinAltitudeDeg;

  /// Bennett (1982) atmospheric refraction correction.
  ///
  /// Returns arc-minutes to SUBTRACT from apparent altitude to get true
  /// altitude. Returns 0.0 on any invalid input; sets [reason] accordingly.
  ///
  /// Failure modes:
  ///   altitude < 8°          → refraction error > 10 NM, sighting rejected
  ///   pressure outside range → sensor fault
  ///   temperature out of range → sensor fault
  static double correctRefraction(
    double apparentAltitudeDeg,
    double pressureMb,
    double tempCelsius, {
    StringBuffer? reason,
  }) {
    if (apparentAltitudeDeg < kMinAltitudeDeg) {
      reason?.write(
          'Altitude ${apparentAltitudeDeg.toStringAsFixed(1)}° < 8° — rejected. '
          'Refraction error exceeds safe navigation margin.');
      return 0.0;
    }
    if (pressureMb < 800 || pressureMb > 1100) {
      reason?.write('Pressure ${pressureMb.toStringAsFixed(0)} mb outside [800, 1100].');
      return 0.0;
    }
    if (tempCelsius < -40 || tempCelsius > 50) {
      reason?.write('Temperature ${tempCelsius.toStringAsFixed(0)}°C outside [−40, 50].');
      return 0.0;
    }

    // Bennett (1982): R₀ = 1 / tan( h + 7.31 / (h + 4.4) )  [arcmin]
    final h = apparentAltitudeDeg;
    final r0 = 1.0 / math.tan(_deg(h + 7.31 / (h + 4.4)));

    // Pressure/temperature factor (Bowditch Table 17)
    final f = (pressureMb / 1010.0) * (283.0 / (273.0 + tempCelsius));
    final corrArcmin = r0 * f;

    if (corrArcmin < 0 || corrArcmin > 40) {
      reason?.write(
          'Refraction result ${corrArcmin.toStringAsFixed(3)}\' implausible.');
      return 0.0;
    }
    return corrArcmin;
  }

  /// Dip of horizon in arc-minutes.
  /// [heightOfEyeMeters] must be > 0.
  static double dipCorrection(double heightOfEyeMeters, {StringBuffer? reason}) {
    if (heightOfEyeMeters <= 0) {
      reason?.write('Height of eye must be > 0 m.');
      return 0.0;
    }
    // Bowditch: Dip (arcmin) = 1.76 × √h
    return 1.76 * math.sqrt(heightOfEyeMeters);
  }

  /// Total observed-altitude correction = refraction + dip (arc-minutes).
  /// Subtract from sextant / camera altitude to get true altitude.
  static double totalCorrection(
    double apparentAltitudeDeg,
    double heightOfEyeMeters,
    double pressureMb,
    double tempCelsius, {
    StringBuffer? reason,
  }) {
    final refraction = correctRefraction(
      apparentAltitudeDeg,
      pressureMb,
      tempCelsius,
      reason: reason,
    );
    final dip = dipCorrection(heightOfEyeMeters, reason: reason);
    return refraction + dip;
  }

  static double _deg(double d) => d * math.pi / 180.0;
}
