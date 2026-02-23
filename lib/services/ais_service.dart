import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:Bahaar/models/ais_model.dart';
import 'package:Bahaar/services/cpa_calculator.dart';

/// Polls AISHub for vessel positions within the Bahrain bounding box and
/// evaluates CPA (Closest Point of Approach) for collision risk.
///
/// AISHub free tier: up to 60 requests/minute (one per second).
/// We poll every 60 seconds to stay well within limits.
///
/// Sign up for a free API key at: https://www.aishub.net/api
///
/// Set your AISHub username in the environment / secrets file as:
///   AISHUB_USERNAME=`your_username`
class AisService extends ChangeNotifier {
  /// Bahrain bounding box (matches navigation mask)
  static const double _minLat = 25.5;
  static const double _maxLat = 26.5;
  static const double _minLon = 50.2;
  static const double _maxLon = 51.0;

  /// Poll interval
  static const Duration _pollInterval = Duration(seconds: 60);

  /// 5-minute projected path for visualization
  static const double _pathProjectionMinutes = 5.0;

  final String _aishubUsername;
  final http.Client _client;

  Timer? _pollTimer;
  List<AisVessel> _vessels = [];
  List<CpaResult> _cpaAlerts = [];
  bool _initialized = false;
  DateTime? _lastFetch;

  AisService({
    required String aishubUsername,
    http.Client? client,
  })  : _aishubUsername = aishubUsername,
        _client = client ?? http.Client();

  bool get isInitialized => _initialized;
  List<AisVessel> get vessels => List.unmodifiable(_vessels);
  List<CpaResult> get cpaAlerts => List.unmodifiable(_cpaAlerts);
  DateTime? get lastFetch => _lastFetch;

  /// Start polling. Call once when the map is ready.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _fetchVessels();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchVessels());
    log('AisService: initialized, polling every ${_pollInterval.inSeconds}s');
  }

  /// Evaluate CPA for all current vessels against own position/course.
  void updateOwnPosition({
    required double lat,
    required double lon,
    required double sogKnots,
    required double cogDeg,
  }) {
    final alerts = <CpaResult>[];
    for (final vessel in _vessels) {
      final result = CpaCalculator.compute(
        ownLat: lat,
        ownLon: lon,
        ownSogKnots: sogKnots,
        ownCogDeg: cogDeg,
        target: vessel,
      );
      if (result.risk != CollisionRisk.none) {
        alerts.add(result);
      }
    }
    // Sort by risk level then by DCPA (closest first)
    alerts.sort((a, b) {
      final riskCmp = b.risk.index.compareTo(a.risk.index);
      return riskCmp != 0 ? riskCmp : a.dcpaNm.compareTo(b.dcpaNm);
    });
    _cpaAlerts = alerts;
    notifyListeners();
  }

  /// Build a 5-minute projected path for a vessel (list of lat/lon pairs).
  List<(double lat, double lon)> getProjectedPath(AisVessel vessel) {
    const steps = 10;
    final totalSeconds = _pathProjectionMinutes * 60;
    final stepSeconds = totalSeconds / steps;
    return List.generate(
      steps + 1,
      (i) => vessel.projectPosition(stepSeconds * i),
    );
  }

  Future<void> _fetchVessels() async {
    if (_aishubUsername.isEmpty) {
      log('AisService: no AISHub username configured — skipping fetch');
      return;
    }

    try {
      // AISHub JSON API v2
      final uri = Uri.parse(
        'https://data.aishub.net/ws.php'
        '?username=$_aishubUsername'
        '&format=1'       // JSON
        '&output=extended' // full fields
        '&compress=0'
        '&latmin=$_minLat&latmax=$_maxLat'
        '&lonmin=$_minLon&lonmax=$_maxLon',
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        log('AisService: HTTP ${response.statusCode}');
        return;
      }

      final body = json.decode(response.body);

      // AISHub returns [metaObject, [vessel, ...]] or {"error": "..."}
      if (body is List && body.length >= 2) {
        final vesselList = body[1] as List<dynamic>;
        _vessels = vesselList
            .whereType<Map<String, dynamic>>()
            .map(AisVessel.fromAisHubJson)
            .where((v) => v.mmsi > 0 && v.sogKnots >= 0)
            .toList();
        _lastFetch = DateTime.now();
        log('AisService: fetched ${_vessels.length} vessels');
        notifyListeners();
      } else if (body is Map && body.containsKey('error')) {
        log('AisService: API error: ${body['error']}');
      }
    } catch (e) {
      log('AisService: fetch error: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _client.close();
    super.dispose();
  }
}
