// lib/services/fishing_ai_service.dart
// ════════════════════════════════════════════════════════════════════════════
// Bahaar Fishing AI — Flutter Integration Service
// Drop into your existing Bahaar app under lib/services/
//
// Usage:
//   final ai = FishingAIService();
//   final result = await ai.predict(lat: 26.45, lng: 50.52, species: 'hamour');
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Constants ─────────────────────────────────────────────────────────────────
// Replace with your Render URL after deploy
const String _kBaseUrl = 'https://bahaar-fishing-ai.onrender.com';
const Duration _kTimeout = Duration(seconds: 10);

// ── Data models ───────────────────────────────────────────────────────────────

class PredictionFactors {
  final double staticFactor;
  final double seasonal;
  final double weather;
  final double human;

  const PredictionFactors({
    required this.staticFactor,
    required this.seasonal,
    required this.weather,
    required this.human,
  });

  factory PredictionFactors.fromJson(Map<String, dynamic> j) =>
      PredictionFactors(
        staticFactor: (j['static'] as num).toDouble(),
        seasonal: (j['seasonal'] as num).toDouble(),
        weather: (j['weather'] as num).toDouble(),
        human: (j['human'] as num).toDouble(),
      );
}

class NearbySpot {
  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final double distanceKm;
  final String zone;
  final List<String> species;
  final bool isMpa;
  final int? baseScore;

  const NearbySpot({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.zone,
    required this.species,
    required this.isMpa,
    this.baseScore,
  });

  factory NearbySpot.fromJson(Map<String, dynamic> j) => NearbySpot(
        id: j['id'] ?? '',
        nameAr: j['name_ar'] ?? '',
        nameEn: j['name_en'] ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        distanceKm: (j['distance_km'] as num).toDouble(),
        zone: j['zone'] ?? '',
        species: List<String>.from(j['species'] ?? []),
        isMpa: j['mpa'] ?? false,
        baseScore: j['base_score'] as int?,
      );
}

class MpaRestriction {
  final String id;
  final String nameAr;
  final String nameEn;
  final String restriction;
  final String restrictionAr;
  final String restrictionEn;
  final double distanceKm;

  const MpaRestriction({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.restriction,
    required this.restrictionAr,
    required this.restrictionEn,
    required this.distanceKm,
  });

  factory MpaRestriction.fromJson(Map<String, dynamic> j) => MpaRestriction(
        id: j['id'] ?? '',
        nameAr: j['name_ar'] ?? '',
        nameEn: j['name_en'] ?? '',
        restriction: j['restriction'] ?? '',
        restrictionAr: j['restriction_ar'] ?? '',
        restrictionEn: j['restriction_en'] ?? '',
        distanceKm: (j['distance_km'] as num).toDouble(),
      );

  bool get isFull => restriction == 'full';
}

class SafetyInfo {
  final String level;       // 'safe' | 'caution' | 'warning' | 'danger'
  final String levelAr;
  final String messageAr;
  final String messageEn;
  final double waveHeightM;
  final double windSpeedKmh;
  final bool shamalWarning;

  const SafetyInfo({
    required this.level,
    required this.levelAr,
    required this.messageAr,
    required this.messageEn,
    required this.waveHeightM,
    required this.windSpeedKmh,
    required this.shamalWarning,
  });

  factory SafetyInfo.fromJson(Map<String, dynamic> j) => SafetyInfo(
        level: j['level'] ?? 'safe',
        levelAr: j['level_ar'] ?? 'آمن',
        messageAr: j['message_ar'] ?? '',
        messageEn: j['message_en'] ?? '',
        waveHeightM: (j['wave_height_m'] as num? ?? 0).toDouble(),
        windSpeedKmh: (j['wind_speed_kmh'] as num? ?? 0).toDouble(),
        shamalWarning: j['shamal_warning'] ?? false,
      );
}

class PredictionResult {
  final double probability;      // 0–100
  final String tier;             // 'excellent' | 'good' | 'fair' | 'low'
  final String tierAr;
  final PredictionFactors factors;
  final String zone;
  final String zoneNameAr;
  final String zoneNameEn;
  final List<NearbySpot> nearbySpots;
  final List<MpaRestriction> restrictions;
  final bool mpaBlocked;
  final String? messageAr;
  final String? messageEn;
  final SafetyInfo? safety;
  final Map<String, dynamic>? weather;

  const PredictionResult({
    required this.probability,
    required this.tier,
    required this.tierAr,
    required this.factors,
    required this.zone,
    required this.zoneNameAr,
    required this.zoneNameEn,
    required this.nearbySpots,
    required this.restrictions,
    required this.mpaBlocked,
    this.messageAr,
    this.messageEn,
    this.safety,
    this.weather,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) {
    final safetyJson = j['safety'] as Map<String, dynamic>?;
    return PredictionResult(
      probability: (j['probability'] as num).toDouble(),
      tier: j['tier'] ?? 'fair',
      tierAr: j['tier_ar'] ?? 'متوسط',
      factors: PredictionFactors.fromJson(j['factors'] ?? {}),
      zone: j['zone'] ?? '',
      zoneNameAr: j['zone_name_ar'] ?? '',
      zoneNameEn: j['zone_name_en'] ?? '',
      nearbySpots: (j['nearby_spots'] as List? ?? [])
          .map((e) => NearbySpot.fromJson(e as Map<String, dynamic>))
          .toList(),
      restrictions: (j['restrictions'] as List? ?? [])
          .map((e) => MpaRestriction.fromJson(e as Map<String, dynamic>))
          .toList(),
      mpaBlocked: j['mpa_blocked'] ?? false,
      messageAr: j['message_ar'],
      messageEn: j['message_en'],
      safety: safetyJson != null ? SafetyInfo.fromJson(safetyJson) : null,
      weather: j['weather'] as Map<String, dynamic>?,
    );
  }

  /// Colour for UI display: red / orange / yellow / green
  String get tierColor {
    switch (tier) {
      case 'excellent': return '#2ECC71';
      case 'good':      return '#F1C40F';
      case 'fair':      return '#E67E22';
      default:          return '#E74C3C';
    }
  }
}

class ReportResult {
  final bool learned;
  final String reportId;
  final double error;
  final bool newSpotCandidate;
  final Map<String, dynamic>? candidate;

  const ReportResult({
    required this.learned,
    required this.reportId,
    required this.error,
    required this.newSpotCandidate,
    this.candidate,
  });

  factory ReportResult.fromJson(Map<String, dynamic> j) => ReportResult(
        learned: j['learned'] ?? false,
        reportId: j['report_id'] ?? '',
        error: (j['error'] as num? ?? 0).toDouble(),
        newSpotCandidate: j['new_spot_candidate'] ?? false,
        candidate: j['candidate'] as Map<String, dynamic>?,
      );
}

class SeasonalAdvice {
  final double seasonalFactor;
  final bool isPeakSeason;
  final String adviceAr;
  final String adviceEn;
  final List<String> bestMethods;
  final String typicalDepthM;
  final String preferredTempC;
  final double? priceBdPerKg;
  final List<double> fullCalendar;

  const SeasonalAdvice({
    required this.seasonalFactor,
    required this.isPeakSeason,
    required this.adviceAr,
    required this.adviceEn,
    required this.bestMethods,
    required this.typicalDepthM,
    required this.preferredTempC,
    this.priceBdPerKg,
    required this.fullCalendar,
  });

  factory SeasonalAdvice.fromJson(Map<String, dynamic> j) => SeasonalAdvice(
        seasonalFactor: (j['seasonal_factor'] as num).toDouble(),
        isPeakSeason: j['is_peak_season'] ?? false,
        adviceAr: j['advice_ar'] ?? '',
        adviceEn: j['advice_en'] ?? '',
        bestMethods: List<String>.from(j['best_methods'] ?? []),
        typicalDepthM: j['typical_depth_m'] ?? '',
        preferredTempC: j['preferred_temp_c'] ?? '',
        priceBdPerKg: (j['price_bd_per_kg'] as num?)?.toDouble(),
        fullCalendar: (j['full_calendar'] as List? ?? [])
            .map((v) => (v as num).toDouble())
            .toList(),
      );
}

// ── AI Service ────────────────────────────────────────────────────────────────

class FishingAIService {
  final String baseUrl;
  final http.Client _client;

  FishingAIService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _kBaseUrl,
        _client = client ?? http.Client();

  // ── Predict ─────────────────────────────────────────────────────────────────
  /// Predict fish presence probability at [lat]/[lng] for [species].
  /// [month] defaults to current month (1-12).
  /// Set [fetchWeather] = false to skip live weather lookup.
  Future<PredictionResult> predict({
    required double lat,
    required double lng,
    required String species,
    int? month,
    double? tempOverride,
    double? windOverride,
    bool fetchWeather = true,
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'species_id': species,
      if (month != null) 'month': month,
      if (tempOverride != null) 'temp': tempOverride,
      if (windOverride != null) 'wind': windOverride,
      'fetch_weather': fetchWeather,
    };

    final response = await _post('/predict', body);
    return PredictionResult.fromJson(response);
  }

  // ── Submit Report ────────────────────────────────────────────────────────────
  /// Submit a fishing report after the user returns from a trip.
  Future<ReportResult> submitReport({
    required String userId,
    required double lat,
    required double lng,
    required String species,
    required int successRating,   // 1-5
    double? quantityKg,
    String? method,
    double? predictedProbability,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'species_id': species,
      'success_rating': successRating,
      if (quantityKg != null) 'quantity': quantityKg,
      if (method != null) 'method': method,
      if (predictedProbability != null)
        'predicted_probability': predictedProbability,
      if (notes != null) 'notes': notes,
    };

    final response = await _post('/report', body);
    return ReportResult.fromJson(response);
  }

  // ── Nearby Spots ─────────────────────────────────────────────────────────────
  Future<List<NearbySpot>> getNearbySpots({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
    String? species,
  }) async {
    final params = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
      'radius': '$radiusKm',
      if (species != null) 'species': species,
    };
    final data = await _get('/spots/nearby', params);
    return (data['spots'] as List? ?? [])
        .map((e) => NearbySpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Seasonal Advice ──────────────────────────────────────────────────────────
  Future<SeasonalAdvice> getSeasonalAdvice({
    required String species,
    int? month,
  }) async {
    final now = DateTime.now();
    final params = {
      'species_id': species,
      'month': '${month ?? now.month}',
    };
    final data = await _get('/seasonal/advice', params);
    return SeasonalAdvice.fromJson(data);
  }

  // ── Weather ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getWeather(double lat, double lng) async {
    return _get('/weather', {'lat': '$lat', 'lng': '$lng'});
  }

  // ── Zone Info ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getZoneInfo(double lat, double lng) async {
    return _get('/zone/info', {'lat': '$lat', 'lng': '$lng'});
  }

  // ── Species List ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSpecies() async {
    final data = await _get('/species', {});
    return List<Map<String, dynamic>>.from(data['species'] ?? []);
  }

  // ── HTTP helpers ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final resp = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_kTimeout);
      return _handleResponse(resp, path);
    } on Exception catch (e) {
      throw AIServiceException('Network error on POST $path: $e');
    }
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    try {
      final resp = await _client.get(uri).timeout(_kTimeout);
      return _handleResponse(resp, path);
    } on Exception catch (e) {
      throw AIServiceException('Network error on GET $path: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response resp, String path) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;
    throw AIServiceException(
      'API error ${resp.statusCode} on $path: ${body['error']}',
      statusCode: resp.statusCode,
    );
  }

  void dispose() => _client.close();
}

// ── Exception ─────────────────────────────────────────────────────────────────
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;
  const AIServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'AIServiceException: $message';
}

// ════════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLE (in your map screen Riverpod provider)
// ════════════════════════════════════════════════════════════════════════════
//
// final fishingAIProvider = Provider<FishingAIService>((ref) {
//   final service = FishingAIService();
//   ref.onDispose(service.dispose);
//   return service;
// });
//
// // In map screen, when user taps a location:
// final prediction = await ref.read(fishingAIProvider).predict(
//   lat: tappedLatLng.latitude,
//   lng: tappedLatLng.longitude,
//   species: 'hamour',
// );
//
// // Show probability circle on map
// showProbabilityOverlay(
//   probability: prediction.probability,
//   color: prediction.tierColor,
//   label: '${prediction.probability.toStringAsFixed(0)}%',
// );
//
// // After trip, submit report
// await ref.read(fishingAIProvider).submitReport(
//   userId: currentUser.uid,
//   lat: tripLatLng.latitude,
//   lng: tripLatLng.longitude,
//   species: 'hamour',
//   successRating: 4,
//   quantityKg: 3.5,
//   method: 'gargoor',
//   predictedProbability: prediction.probability,
// );
