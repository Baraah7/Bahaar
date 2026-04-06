import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'vision_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Catalog types
// ─────────────────────────────────────────────────────────────────────────────

class CatalogStar {
  final int    hip;    // Hipparcos number
  final String name;
  final double ra;    // Right Ascension  (degrees, J2000)
  final double dec;   // Declination      (degrees, J2000)
  final double mag;   // Visual magnitude

  const CatalogStar({
    required this.hip,
    required this.name,
    required this.ra,
    required this.dec,
    required this.mag,
  });

  factory CatalogStar.fromJson(Map<String, dynamic> j) => CatalogStar(
        hip:  (j['hip'] as num).toInt(),
        name: j['name'] as String? ?? '',
        ra:   (j['ra']  as num).toDouble(),
        dec:  (j['dec'] as num).toDouble(),
        mag:  (j['mag'] as num).toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Match result
// ─────────────────────────────────────────────────────────────────────────────

class StarMatch {
  /// The three camera centroids that were matched.
  final List<StarCentroid> cameraTriplet;

  /// The three catalog stars they matched to.
  final List<CatalogStar> catalogTriplet;

  /// Angular residual of the best triangle match (degrees).
  /// Lower = better. Typically < 0.3° for a good match.
  final double residualDeg;

  const StarMatch({
    required this.cameraTriplet,
    required this.catalogTriplet,
    required this.residualDeg,
  });

  /// Weighted mean RA / Dec of the matched triplet (rough boresight estimate).
  double get boresightRa  => catalogTriplet.map((s) => s.ra ).reduce((a,b)=>a+b) / 3.0;
  double get boresightDec => catalogTriplet.map((s) => s.dec).reduce((a,b)=>a+b) / 3.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// StarIdentifier — Lost-in-Space triangle matching
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies stars in a camera frame using triangle-matching against the
/// embedded 2,500-star catalog.
///
/// Algorithm (Lost-in-Space, Mortari 2004 variant):
///   1. Take the 3 brightest detected centroids.
///   2. Compute the 3 inter-star angular distances from pixel coordinates
///      using the calibrated FOV.
///   3. Search the catalog for all triplets whose angular distances match
///      within a tolerance of ±0.3°.
///   4. Return the best match (lowest residual), or null if none found.
///
/// Failure modes:
///   • Returns null  — never throws.
///   • < 3 stars in frame → null.
///   • FOV not calibrated → null (fovHDeg must be > 0).
///   • No catalog triplet within tolerance → null.
class StarIdentifier {
  StarIdentifier._();
  static final instance = StarIdentifier._();

  static const String _assetPath = 'assets/data/stars_2500.json';
  static const double _matchToleranceDeg = 0.3;

  List<CatalogStar> _catalog = [];
  bool _loaded = false;

  // Pre-computed catalog: list of all triplets with their 3 side lengths.
  // Built once after catalog load to make matching O(log N) per frame.
  List<_CatalogTriplet> _triplets = [];

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  /// Load the star catalog from assets.  Call once at app start.
  ///
  /// Returns null on success, or an error string.
  Future<String?> loadCatalog() async {
    if (_loaded) return null;
    try {
      final raw  = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = json['stars'] as List<dynamic>;
      _catalog   = list
          .map((e) => CatalogStar.fromJson(e as Map<String, dynamic>))
          .toList();

      // Sort by magnitude (brightest first) so brightest-3 search is O(1)
      _catalog.sort((a, b) => a.mag.compareTo(b.mag));

      // Pre-build triplet index from the brightest 500 stars
      // (covering all naked-eye stars; beyond that triangles become degenerate)
      _buildTripletIndex(500);

      _loaded = true;
      return null;
    } catch (e) {
      return 'DS-1: Failed to load star catalog: $e';
    }
  }

  // ── Identification ──────────────────────────────────────────────────────────

  /// Attempt to identify stars from a list of camera centroids.
  ///
  /// [centroids]   — detected star positions (pixel coordinates).
  /// [imageWidth]  — frame width  in pixels.
  /// [imageHeight] — frame height in pixels.
  /// [fovHDeg]     — horizontal field of view in degrees (from calibration).
  ///
  /// Returns the best [StarMatch], or null on any failure.
  StarMatch? identify({
    required List<StarCentroid> centroids,
    required int    imageWidth,
    required int    imageHeight,
    required double fovHDeg,
  }) {
    if (!_loaded)         return null; // catalog not loaded
    if (centroids.length < 3) return null; // not enough stars
    if (fovHDeg <= 0)    return null; // uncalibrated

    // Take the 3 brightest (already sorted by brightness from VisionBridge,
    // which sorts by pixel intensity descending)
    final triple = centroids.take(3).toList();

    // Convert pixel offsets from image centre → angular offsets (degrees)
    final double degPerPx = fovHDeg / imageWidth;

    final List<_AngularStar> angStars = triple.map((c) {
      final dx = c.x - imageWidth  / 2.0;
      final dy = c.y - imageHeight / 2.0;
      return _AngularStar(dx * degPerPx, dy * degPerPx);
    }).toList();

    // Compute the 3 inter-star angular distances (sides of the triangle)
    final double d01 = _angularSep(angStars[0], angStars[1]);
    final double d02 = _angularSep(angStars[0], angStars[2]);
    final double d12 = _angularSep(angStars[1], angStars[2]);

    // Sort sides for order-independent matching
    final cameraSides = [d01, d02, d12]..sort();

    // Search pre-built triplet index
    _CatalogTriplet? bestTriplet;
    double bestResidual = double.infinity;

    for (final ct in _triplets) {
      final residual = _triangleResidual(cameraSides, ct.sides);
      if (residual < _matchToleranceDeg && residual < bestResidual) {
        bestResidual = residual;
        bestTriplet  = ct;
      }
    }

    if (bestTriplet == null) return null;

    return StarMatch(
      cameraTriplet:  triple,
      catalogTriplet: bestTriplet.stars,
      residualDeg:    bestResidual,
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _buildTripletIndex(int maxStars) {
    final n = math.min(maxStars, _catalog.length);
    _triplets = [];

    for (int i = 0; i < n - 2; i++) {
      for (int j = i + 1; j < n - 1; j++) {
        for (int k = j + 1; k < n; k++) {
          final si = _catalog[i];
          final sj = _catalog[j];
          final sk = _catalog[k];

          final dij = _catalogAngularSep(si, sj);
          final dik = _catalogAngularSep(si, sk);
          final djk = _catalogAngularSep(sj, sk);

          // Reject degenerate triangles (collinear stars)
          final sides = [dij, dik, djk]..sort();
          if (sides[2] > sides[0] + sides[1] - 0.01) continue;

          _triplets.add(_CatalogTriplet(
            stars: [si, sj, sk],
            sides: sides,
          ));
        }
      }
    }

    // Sort triplets by their shortest side for binary-search pruning
    _triplets.sort((a, b) => a.sides[0].compareTo(b.sides[0]));
  }

  /// Angular separation between two camera angular-offset stars (degrees).
  static double _angularSep(_AngularStar a, _AngularStar b) {
    final dx = a.dxDeg - b.dxDeg;
    final dy = a.dyDeg - b.dyDeg;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Great-circle angular separation between two catalog stars (degrees).
  static double _catalogAngularSep(CatalogStar a, CatalogStar b) {
    final ra1  = a.ra  * math.pi / 180.0;
    final dec1 = a.dec * math.pi / 180.0;
    final ra2  = b.ra  * math.pi / 180.0;
    final dec2 = b.dec * math.pi / 180.0;

    // Haversine formula
    final dRa  = ra2  - ra1;
    final dDec = dec2 - dec1;
    final hav  = _hav(dDec) + math.cos(dec1) * math.cos(dec2) * _hav(dRa);
    final d    = 2.0 * math.asin(math.sqrt(hav.clamp(0.0, 1.0)));
    return d * 180.0 / math.pi;
  }

  static double _hav(double x) {
    final s = math.sin(x / 2.0);
    return s * s;
  }

  /// RMS residual between two sorted triangle side vectors (degrees).
  static double _triangleResidual(List<double> cam, List<double> cat) {
    double sum = 0;
    for (int i = 0; i < 3; i++) {
      final d = cam[i] - cat[i];
      sum += d * d;
    }
    return math.sqrt(sum / 3.0);
  }
}

// ── Private data types ────────────────────────────────────────────────────────

class _AngularStar {
  final double dxDeg;
  final double dyDeg;
  const _AngularStar(this.dxDeg, this.dyDeg);
}

class _CatalogTriplet {
  final List<CatalogStar> stars; // always length 3
  final List<double>      sides; // sorted ascending, length 3
  const _CatalogTriplet({required this.stars, required this.sides});
}
