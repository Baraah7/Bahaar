import 'dart:math' as math;

/// Pure Dart celestial calculations — no external API required.
/// Implements NOAA solar algorithm and Julian Day lunar phase math.
class CelestialCalculator {
  // Manama, Bahrain fallback coordinates
  static const double _defaultLat = 26.2154;
  static const double _defaultLon = 50.5832;

  // ─── Public API ───────────────────────────────────────────────

  /// Calculate solar events for [date] at [lat]/[lon].
  static SolarDay calculateSolarDay(
    double lat,
    double lon,
    DateTime date,
  ) {
    final jd = _julianDay(date);
    final sunrise = _sunriseOrSet(lat, lon, jd, rising: true);
    final sunset = _sunriseOrSet(lat, lon, jd, rising: false);
    final noon = _solarNoon(lon, jd);

    return SolarDay(
      sunrise: sunrise,
      sunset: sunset,
      solarNoon: noon,
    );
  }

  /// Calculate lunar events for [date] at [lat]/[lon].
  static LunarDay calculateLunarDay(
    double lat,
    double lon,
    DateTime date,
  ) {
    final phase = _moonPhase(date);
    final illumination = _moonIllumination(phase);
    final phaseName = _moonPhaseName(phase);
    final moonrise = _moonRiseOrSet(lat, lon, date, rising: true);
    final moonset = _moonRiseOrSet(lat, lon, date, rising: false);

    return LunarDay(
      moonrise: moonrise,
      moonset: moonset,
      phase: phase,
      phaseName: phaseName,
      illumination: illumination,
    );
  }

  /// Convenience: use default Manama coordinates.
  static SolarDay calculateSolarDayDefault(DateTime date) =>
      calculateSolarDay(_defaultLat, _defaultLon, date);

  static LunarDay calculateLunarDayDefault(DateTime date) =>
      calculateLunarDay(_defaultLat, _defaultLon, date);

  // ─── Moon Phase ───────────────────────────────────────────────

  /// Returns phase 0.0–1.0 (0 = new moon, 0.5 = full moon).
  static double _moonPhase(DateTime date) {
    const knownNewMoonJd = 2451549.5; // Jan 6, 2000 18:14 UTC
    const synodicMonth = 29.53058867;
    final jd = _julianDay(date);
    final phase = ((jd - knownNewMoonJd) % synodicMonth) / synodicMonth;
    return phase < 0 ? phase + 1 : phase;
  }

  static double _moonIllumination(double phase) {
    // Illumination peaks at full moon (phase=0.5)
    return ((1 - math.cos(2 * math.pi * phase)) / 2 * 100).roundToDouble();
  }

  static String _moonPhaseName(double phase) {
    if (phase < 0.0625 || phase >= 0.9375) return 'New Moon';
    if (phase < 0.1875) return 'Waxing Crescent';
    if (phase < 0.3125) return 'First Quarter';
    if (phase < 0.4375) return 'Waxing Gibbous';
    if (phase < 0.5625) return 'Full Moon';
    if (phase < 0.6875) return 'Waning Gibbous';
    if (phase < 0.8125) return 'Last Quarter';
    return 'Waning Crescent';
  }

  /// Emoji for moon phase display.
  static String moonPhaseEmoji(String phaseName) {
    switch (phaseName) {
      case 'New Moon':
        return '🌑';
      case 'Waxing Crescent':
        return '🌒';
      case 'First Quarter':
        return '🌓';
      case 'Waxing Gibbous':
        return '🌔';
      case 'Full Moon':
        return '🌕';
      case 'Waning Gibbous':
        return '🌖';
      case 'Last Quarter':
        return '🌗';
      case 'Waning Crescent':
        return '🌘';
      default:
        return '🌙';
    }
  }

  // ─── Solar Calculations (NOAA algorithm) ─────────────────────

  static double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day +
        date.hour / 24.0 +
        date.minute / 1440.0 +
        date.second / 86400.0;

    int a = ((14 - m) / 12).floor();
    int Y = y + 4800 - a;
    int M = m + 12 * a - 3;

    double jdn = d +
        ((153 * M + 2) / 5).floor() +
        365 * Y +
        (Y / 4).floor() -
        (Y / 100).floor() +
        (Y / 400).floor() -
        32045.0;
    return jdn;
  }

  static double _degToRad(double d) => d * math.pi / 180;
  static double _radToDeg(double r) => r * 180 / math.pi;

  /// Julian centuries from J2000.0
  static double _jCent(double jd) => (jd - 2451545.0) / 36525.0;

  static double _meanLongSun(double t) =>
      (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;

  static double _meanAnomalySun(double t) =>
      357.52911 + t * (35999.05029 - 0.0001537 * t);

  static double _equationOfCenter(double t) {
    final m = _degToRad(_meanAnomalySun(t));
    return math.sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * m) * (0.019993 - 0.000101 * t) +
        math.sin(3 * m) * 0.000289;
  }

  static double _sunTrueLon(double t) =>
      _meanLongSun(t) + _equationOfCenter(t);

  static double _sunApparentLon(double t) {
    final o = _sunTrueLon(t);
    final omega = 125.04 - 1934.136 * t;
    return o - 0.00569 - 0.00478 * math.sin(_degToRad(omega));
  }

  static double _meanObliquity(double t) {
    return 23.0 +
        (26.0 +
                (21.448 -
                        t * (46.8150 + t * (0.00059 - t * 0.001813))) /
                    60) /
            60;
  }

  static double _obliquityCorrection(double t) {
    final e0 = _meanObliquity(t);
    final omega = 125.04 - 1934.136 * t;
    return e0 + 0.00256 * math.cos(_degToRad(omega));
  }

  static double _sunDeclination(double t) {
    final e = _degToRad(_obliquityCorrection(t));
    final lambda = _degToRad(_sunApparentLon(t));
    return _radToDeg(math.asin(math.sin(e) * math.sin(lambda)));
  }

  static double _equationOfTime(double t) {
    final epsilon = _degToRad(_obliquityCorrection(t));
    final l0 = _degToRad(_meanLongSun(t));
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final m = _degToRad(_meanAnomalySun(t));
    final y = math.tan(epsilon / 2);
    final yy = y * y;

    final sinl0 = math.sin(2 * l0);
    final cos2l0 = math.cos(2 * l0);
    final sin4l0 = math.sin(4 * l0);
    final sinm = math.sin(m);
    final sin2m = math.sin(2 * m);

    final eqtime = yy * sinl0 -
        2 * e * sinm +
        4 * e * yy * sinm * cos2l0 -
        0.5 * yy * yy * sin4l0 -
        1.25 * e * e * sin2m;
    return _radToDeg(eqtime) * 4; // minutes
  }

  static double _hourAngleSunrise(double lat, double solarDec) {
    final latR = _degToRad(lat);
    final decR = _degToRad(solarDec);
    final ha = math.acos(
      math.cos(_degToRad(90.833)) /
              (math.cos(latR) * math.cos(decR)) -
          math.tan(latR) * math.tan(decR),
    );
    return _radToDeg(ha);
  }

  static DateTime? _sunriseOrSet(double lat, double lon, double jd,
      {required bool rising}) {
    final t = _jCent(jd);
    try {
      final eqTime = _equationOfTime(t);
      final solarDec = _sunDeclination(t);
      final ha = _hourAngleSunrise(lat, solarDec);
      final offset = rising ? -ha : ha;
      // Solar noon in minutes from midnight UTC
      final solarNoonMinutes = 720 - 4 * lon - eqTime;
      final eventMinutes = solarNoonMinutes + 4 * offset;
      final base = DateTime.utc(
          DateTime.fromMillisecondsSinceEpoch(
                  ((jd - 2440587.5) * 86400000).round())
              .year,
          DateTime.fromMillisecondsSinceEpoch(
                  ((jd - 2440587.5) * 86400000).round())
              .month,
          DateTime.fromMillisecondsSinceEpoch(
                  ((jd - 2440587.5) * 86400000).round())
              .day);
      return base.add(Duration(minutes: eventMinutes.round()));
    } catch (_) {
      return null; // polar night / midnight sun
    }
  }

  static DateTime _solarNoon(double lon, double jd) {
    final t = _jCent(jd);
    final eqTime = _equationOfTime(t);
    final noonMinutes = 720 - 4 * lon - eqTime;
    final ms = ((jd - 2440587.5) * 86400000).round();
    final base = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final dayStart = DateTime.utc(base.year, base.month, base.day);
    return dayStart.add(Duration(minutes: noonMinutes.round()));
  }

  // ─── Moonrise / Moonset (iterative algorithm) ─────────────────

  static DateTime? _moonRiseOrSet(
      double lat, double lon, DateTime date, {required bool rising}) {
    // Uses iterative search over the day
    final base = DateTime.utc(date.year, date.month, date.day);
    double? lastAlt;
    DateTime? result;

    for (int minute = 0; minute <= 1440; minute += 2) {
      final t = base.add(Duration(minutes: minute));
      final alt = _moonAltitude(lat, lon, t);
      if (lastAlt != null) {
        if (rising && lastAlt < 0 && alt >= 0) {
          result = t;
          break;
        }
        if (!rising && lastAlt >= 0 && alt < 0) {
          result = t;
          break;
        }
      }
      lastAlt = alt;
    }
    return result;
  }

  static double _moonAltitude(double lat, double lon, DateTime dt) {
    final jd = _julianDay(dt);
    final t = _jCent(jd);

    // Moon's ecliptic longitude (simplified)
    final L = (218.316 + 13.176396 * (jd - 2451545.0)) % 360;
    final M = _degToRad((134.963 + 13.064993 * (jd - 2451545.0)) % 360);
    final F = _degToRad((93.272 + 13.229350 * (jd - 2451545.0)) % 360);

    final lambda = L + 6.289 * math.sin(M);
    final beta = 5.128 * math.sin(F);

    // Convert to equatorial
    final eps = _degToRad(_obliquityCorrection(t));
    final lambdaR = _degToRad(lambda);
    final betaR = _degToRad(beta);

    final ra = _radToDeg(
        math.atan2(math.sin(lambdaR) * math.cos(eps) -
            math.tan(betaR) * math.sin(eps),
            math.cos(lambdaR)));
    final dec = _radToDeg(math.asin(
        math.sin(betaR) * math.cos(eps) +
            math.cos(betaR) * math.sin(eps) * math.sin(lambdaR)));

    // Greenwich Sidereal Time → Local Hour Angle
    final gst = (280.46061837 +
            360.98564736629 * (jd - 2451545.0) +
            0.000387933 * t * t) %
        360;
    final lha = (gst + lon - ra) % 360;
    final lhaR = _degToRad(lha);
    final latR = _degToRad(lat);
    final decR = _degToRad(dec);

    // Altitude
    final sinAlt = math.sin(latR) * math.sin(decR) +
        math.cos(latR) * math.cos(decR) * math.cos(lhaR);
    return _radToDeg(math.asin(sinAlt));
  }
}

// ─── Data Classes ──────────────────────────────────────────────

class SolarDay {
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime solarNoon;

  const SolarDay({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
  });

  Duration get dayLength {
    if (sunrise == null || sunset == null) return Duration.zero;
    return sunset!.difference(sunrise!);
  }
}

class LunarDay {
  final DateTime? moonrise;
  final DateTime? moonset;
  final double phase;       // 0.0–1.0
  final String phaseName;
  final double illumination; // 0–100

  const LunarDay({
    required this.moonrise,
    required this.moonset,
    required this.phase,
    required this.phaseName,
    required this.illumination,
  });

  String get emoji => CelestialCalculator.moonPhaseEmoji(phaseName);
}
