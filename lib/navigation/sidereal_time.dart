/// Greenwich Mean Sidereal Time (GMST) — IAU 2006 formulation.
///
/// References:
///   Capitaine et al. (2003), A&A 412, 567–586  (iauGmst06 / iauEra00)
///   Meeus, "Astronomical Algorithms", 2nd ed., Ch. 12
class SiderealTime {
  SiderealTime._();

  /// Compute GMST for a UTC [DateTime] with a DUT1 offset.
  ///
  /// [dut1Sec] — UT1 − UTC from the embedded IERS table.
  ///             Valid: |DUT1| ≤ 0.9 s. Pass 0.0 if table unavailable.
  ///
  /// Returns GMST in decimal degrees [0, 360).
  /// Returns null if [utc] is not UTC or DUT1 is out of range.
  static double? gmst(DateTime utc, {double dut1Sec = 0.0}) {
    if (!utc.isUtc) return null;
    if (dut1Sec.abs() > 0.9) return null; // stale or corrupt table

    // UT1 = UTC + DUT1
    final ut1 = utc.add(Duration(microseconds: (dut1Sec * 1e6).round()));
    final jd = _julianDate(ut1);

    // Julian centuries from J2000.0
    final t = (jd - 2451545.0) / 36525.0;

    // Earth Rotation Angle — IAU 2000 (Capitaine 2000)
    // ERA (degrees) = 360 × (0.7790572732640 + 1.00273781191135448 × Du)
    final du = jd - 2451545.0;
    final era =
        _norm360(360.0 * (0.7790572732640 + 1.00273781191135448 * du));

    // IAU 2006 GMST polynomial correction (arcseconds, Capitaine 2003 Eq.12)
    final gmstArcsec = 0.014506
        + 4612.156534 * t
        + 1.3915817 * t * t
        - 0.00000044 * t * t * t
        - 0.000029956 * t * t * t * t
        - 0.0000000368 * t * t * t * t * t;

    return _norm360(era + gmstArcsec / 3600.0);
  }

  /// Local Sidereal Time = GMST + East longitude (degrees).
  static double localSiderealTime(double gmstDeg, double longitudeEastDeg) =>
      _norm360(gmstDeg + longitudeEastDeg);

  /// Convert GMST degrees to hours (for display).
  static double degreesToHours(double deg) => deg / 15.0;

  // ── Internal helpers ────────────────────────────────────────────────────────

  static double _julianDate(DateTime dt) {
    int y = dt.year;
    int m = dt.month;
    final double d = dt.day
        + dt.hour / 24.0
        + dt.minute / 1440.0
        + dt.second / 86400.0
        + dt.microsecond / 86400000000.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = y ~/ 100;
    final int b = 2 - a + (a ~/ 4); // Gregorian correction

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _norm360(double deg) {
    final r = deg % 360.0;
    return r < 0 ? r + 360.0 : r;
  }
}
