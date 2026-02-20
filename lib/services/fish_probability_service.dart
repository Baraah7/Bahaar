import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:Bahaar/models/fishing/fish_probability_model.dart';

/// Service for fetching and managing fish probability heatmap data.
/// Fetches SST and chlorophyll from Copernicus Marine (CMEMS), computes
/// per-species probability cells at initialisation, then caches them.
/// Falls back to a bundled JSON asset when CMEMS is unavailable.
class FishProbabilityService {
  final http.Client _client;

  // Bahrain bounding box — same as FishingActivityService
  static const double _minLat = 25.5;
  static const double _maxLat = 27.0;
  static const double _minLon = 49.5;
  static const double _maxLon = 51.0;

  // Grid resolution: 0.15° ≈ 16 km. Coarser than fishing-activity (0.05°)
  // because SST/chlorophyll gradients vary slowly across the Bahrain shelf.
  // Bahrain bbox yields ~10×10 = 100 cells per species max.
  static const double _resolution = 0.15;

  // CMEMS MOTU subsetting service
  static const String _cmemsBaseUrl =
      'https://nrt.cmems-du.eu/motu-web/Motu';

  String? _cmemsUsername;
  String? _cmemsPassword;

  // Pre-computed cells keyed by species (populated at initialize())
  final Map<FishSpecies, List<FishProbabilityCell>> _cellsBySpecies = {};

  bool _isInitialized = false;
  bool _usingFallback = false;

  bool get isInitialized => _isInitialized;
  bool get usingFallback => _usingFallback;

  FishProbabilityService({http.Client? client})
      : _client = client ?? http.Client();

  /// Initialise: try CMEMS live data, fall back to bundled asset.
  /// Pre-computes all species cells synchronously after fetching.
  Future<void> initialize() async {
    try {
      _cmemsUsername = dotenv.env['CMEMS_USERNAME'];
      _cmemsPassword = dotenv.env['CMEMS_PASSWORD'];

      if (_cmemsUsername != null &&
          _cmemsUsername!.isNotEmpty &&
          _cmemsPassword != null &&
          _cmemsPassword!.isNotEmpty) {
        final envCells = await _fetchEnvironmentalData();
        _computeAndCacheAllSpecies(envCells);
      } else {
        throw Exception('No CMEMS credentials configured');
      }
    } catch (e) {
      log('CMEMS unavailable, loading fallback probability data: $e');
      await _loadFallbackData();
      _usingFallback = true;
    }

    _isInitialized = true;
    final totalCells = _cellsBySpecies.values
        .fold<int>(0, (sum, list) => sum + list.length);
    log('FishProbabilityService initialized: $totalCells total cells '
        '(fallback: $_usingFallback)');
  }

  /// Returns pre-computed probability cells for the given species.
  List<FishProbabilityCell> getCellsForSpecies(FishSpecies species) =>
      _cellsBySpecies[species] ?? [];

  // ---------------------------------------------------------------------------
  // CMEMS data fetching
  // ---------------------------------------------------------------------------

  Future<List<EnvCell>> _fetchEnvironmentalData() async {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';

    final credentials = base64.encode(
        utf8.encode('$_cmemsUsername:$_cmemsPassword'));

    // Fetch SST (Met Office L4 NRT daily, returns Kelvin)
    final sstGrid = await _fetchVariable(
      productId: 'SST_GLO_PHY_L4_NRT_010_043-TDS',
      productName: 'METOFFICE-GLO-SST-L4-NRT-OBS-SST-V2',
      variable: 'analysed_sst',
      dateStr: dateStr,
      credentials: credentials,
    );

    // Fetch chlorophyll-a (Global Ocean Colour BGC NRT daily)
    final chlGrid = await _fetchVariable(
      productId: 'OCEANCOLOUR_GLO_BGC_L4_NRT_009_102-TDS',
      productName:
          'cmems_obs-oc_glo_bgc-plankton_nrt_l4-gapfree-multi-4km_P1D',
      variable: 'CHL',
      dateStr: dateStr,
      credentials: credentials,
    );

    return _mergeToGrid(sstGrid, chlGrid);
  }

  /// Fetch a single CMEMS variable as an ASCII grid subset.
  /// Returns a map of (gridRow, gridCol) → mean value within each 0.15° cell.
  Future<Map<(int, int), double>> _fetchVariable({
    required String productId,
    required String productName,
    required String variable,
    required String dateStr,
    required String credentials,
  }) async {
    final uri = Uri.parse(_cmemsBaseUrl).replace(queryParameters: {
      'action': 'productdownload',
      'service': productId,
      'product': productName,
      'x_lo': '$_minLon',
      'x_hi': '$_maxLon',
      'y_lo': '$_minLat',
      'y_hi': '$_maxLat',
      't_lo': dateStr,
      't_hi': dateStr,
      'variable': variable,
      'out': 'ascii',
    });

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Basic $credentials'},
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('CMEMS $variable returned ${response.statusCode}');
    }

    return _parseAsciiResponse(response.body);
  }

  /// Parse the CMEMS MOTU ASCII response.
  /// Each data row is whitespace-delimited: time depth lat lon value
  Map<(int, int), double> _parseAsciiResponse(String body) {
    final Map<(int, int), List<double>> accumulator = {};
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('time') ||
          trimmed.startsWith('date')) {
        continue;
      }
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 5) continue;
      final lat = double.tryParse(parts[2]);
      final lon = double.tryParse(parts[3]);
      final val = double.tryParse(parts[4]);
      if (lat == null || lon == null || val == null) continue;

      final row = (lat / _resolution).floor();
      final col = (lon / _resolution).floor();
      accumulator.putIfAbsent((row, col), () => []).add(val);
    }

    return accumulator.map((key, vals) {
      final mean = vals.reduce((a, b) => a + b) / vals.length;
      return MapEntry(key, mean);
    });
  }

  /// Merge SST and chlorophyll grids into EnvCell list.
  /// SST is converted from Kelvin to Celsius (CMEMS L4 SST is in Kelvin).
  List<EnvCell> _mergeToGrid(
    Map<(int, int), double> sstGrid,
    Map<(int, int), double> chlGrid,
  ) {
    final allKeys = {...sstGrid.keys, ...chlGrid.keys};
    return allKeys.map((key) {
      final (row, col) = key;
      final lat = (row + 0.5) * _resolution;
      final lon = (col + 0.5) * _resolution;

      final rawSst = sstGrid[key];
      // Convert Kelvin → Celsius; if SST > 100 it must be in Kelvin
      final sstC = rawSst == null
          ? double.nan
          : (rawSst > 100 ? rawSst - 273.15 : rawSst);

      final chl = chlGrid[key] ?? double.nan;
      return EnvCell(lat, lon, sstC, chl);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Probability computation (pure, synchronous)
  // ---------------------------------------------------------------------------

  void _computeAndCacheAllSpecies(List<EnvCell> envCells) {
    for (final species in FishSpecies.values) {
      _cellsBySpecies[species] = envCells
          .where(_isInBahrain)
          .map((c) => _scoreCell(c, species))
          .where((cell) => cell.score > 0.05)
          .toList();
    }
  }

  bool _isInBahrain(EnvCell c) =>
      c.lat >= _minLat &&
      c.lat <= _maxLat &&
      c.lon >= _minLon &&
      c.lon <= _maxLon;

  FishProbabilityCell _scoreCell(EnvCell env, FishSpecies species) {
    final sstScore = _normaliseSst(env.sst, species);
    final chlScore = _normaliseChlorophyll(env.chlorophyll, species);

    double score;
    if (env.sst.isNaN && env.chlorophyll.isNaN) {
      score = 0.0;
    } else if (env.sst.isNaN) {
      score = chlScore;
    } else if (env.chlorophyll.isNaN) {
      score = sstScore;
    } else {
      // SST 55%, Chlorophyll 45%
      score = sstScore * 0.55 + chlScore * 0.45;
    }

    score = score.clamp(0.0, 1.0);
    return FishProbabilityCell(
      latitude: env.lat,
      longitude: env.lon,
      score: score,
      level: FishProbabilityCell.levelForScore(score),
      species: species,
    );
  }

  /// Trapezoidal SST membership per species (°C).
  /// Ranges: (minOk, minOpt, maxOpt, maxOk)
  double _normaliseSst(double sst, FishSpecies species) {
    if (sst.isNaN) return 0.5; // missing → neutral
    final (minOk, minOpt, maxOpt, maxOk) = switch (species) {
      FishSpecies.giltHeadBream => (18.0, 20.0, 26.0, 30.0),
      FishSpecies.horseMackerel => (16.0, 18.0, 24.0, 28.0),
      FishSpecies.seaBass => (14.0, 16.0, 22.0, 26.0),
      FishSpecies.shrimp => (20.0, 22.0, 28.0, 32.0),
    };
    return _trapezoid(sst, minOk, minOpt, maxOpt, maxOk);
  }

  /// Trapezoidal chlorophyll membership per species (mg/m³).
  double _normaliseChlorophyll(double chl, FishSpecies species) {
    if (chl.isNaN) return 0.5;
    final (minOk, minOpt, maxOpt, maxOk) = switch (species) {
      FishSpecies.giltHeadBream => (0.1, 0.3, 1.5, 3.0),
      FishSpecies.horseMackerel => (0.3, 0.8, 5.0, 8.0),
      FishSpecies.seaBass => (0.1, 0.3, 1.5, 3.0),
      FishSpecies.shrimp => (0.5, 1.0, 6.0, 10.0),
    };
    return _trapezoid(chl, minOk, minOpt, maxOpt, maxOk);
  }

  /// Trapezoidal membership function.
  /// Returns 0 outside [minOk, maxOk], 1 in [minOpt, maxOpt],
  /// linear ramps in between.
  static double _trapezoid(
      double x, double minOk, double minOpt, double maxOpt, double maxOk) {
    if (x <= minOk || x >= maxOk) return 0.0;
    if (x >= minOpt && x <= maxOpt) return 1.0;
    if (x < minOpt) return (x - minOk) / (minOpt - minOk);
    return (maxOk - x) / (maxOk - maxOpt);
  }

  // ---------------------------------------------------------------------------
  // Fallback data
  // ---------------------------------------------------------------------------

  Future<void> _loadFallbackData() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/data/fish_probability_fallback.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      for (final species in FishSpecies.values) {
        final key = species.name; // camelCase enum name
        final cellsJson = data[key] as List<dynamic>? ?? [];
        _cellsBySpecies[species] = cellsJson
            .map((c) =>
                FishProbabilityCell.fromJson(c as Map<String, dynamic>, species))
            .toList();
      }
    } catch (e) {
      log('Error loading fish probability fallback: $e');
      // Leave _cellsBySpecies empty; layer renders nothing gracefully.
    }
  }

  void dispose() {
    _client.close();
  }
}

