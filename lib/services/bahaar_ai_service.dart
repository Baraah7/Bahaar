// lib/services/bahaar_ai_service.dart
// BahaarAIService — thin wrapper around FishingAIService that:
//   1. Points to the correct Render deployment URL.
//   2. Injects the Firebase Auth ID token into every request.
//   3. Throws BahaarOfflineException (with Arabic message) on network failure.

import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// Import and re-export models from the existing service so callers only need
// one import.
import 'package:Bahaar/services/map/fishing_ai_service.dart';
export 'package:Bahaar/services/map/fishing_ai_service.dart'
    show
        PredictionResult,
        ReportResult,
        NearbySpot,
        SeasonalAdvice,
        AIServiceException,
        PredictionFactors,
        MpaRestriction,
        SafetyInfo;

const String _kBahaarBaseUrl = 'https://bahaar-whjo.onrender.com';
const Duration _kTimeout = Duration(seconds: 10);

/// Thrown when the server is unreachable or the request times out.
class BahaarOfflineException implements Exception {
  final String messageAr;
  final String messageEn;
  final String messageTechnical;

  const BahaarOfflineException(
    this.messageAr, {
    required this.messageEn,
    required this.messageTechnical,
  });

  @override
  String toString() => 'BahaarOfflineException: $messageTechnical';
}

class BahaarAIService {
  final String baseUrl;
  final http.Client _client;

  BahaarAIService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _kBahaarBaseUrl,
        _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Predict fish probability at [lat]/[lng] for [speciesId].
  Future<PredictionResult> predict({
    required double lat,
    required double lng,
    required String speciesId,
    double? temp,
    double? wind,
    int? month,
  }) async {
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'species_id': speciesId,
      if (temp != null) 'temp': temp,
      if (wind != null) 'wind': wind,
      if (month != null) 'month': month,
    };
    final json = await _post('/predict', body);
    return PredictionResult.fromJson(json);
  }

  /// Submit a catch report to trigger AI learning.
  Future<ReportResult> submitReport({
    required String userId,
    required double lat,
    required double lng,
    required String speciesId,
    required int successRating,
    double? quantity,
    String? method,
    double? predictedProbability,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'species_id': speciesId,
      'success_rating': successRating,
      'timestamp': DateTime.now().toIso8601String(),
      if (quantity != null) 'quantity': quantity,
      if (method != null) 'method': method,
      if (predictedProbability != null)
        'predicted_probability': predictedProbability,
      if (notes != null) 'notes': notes,
    };
    final json = await _post('/report', body);
    return ReportResult.fromJson(json);
  }

  /// Get nearby fishing spots for a given location.
  Future<List<NearbySpot>> getNearbySpots({
    required double lat,
    required double lng,
    double radiusKm = 20,
    String? species,
  }) async {
    final params = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
      'radius': '$radiusKm',
      if (species != null) 'species': species,
    };
    final json = await _get('/spots/nearby', params);
    return (json['spots'] as List? ?? [])
        .map((e) => NearbySpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get zone information for a coordinate.
  Future<Map<String, dynamic>> getZoneInfo({
    required double lat,
    required double lng,
  }) async {
    return _get('/zone/info', {'lat': '$lat', 'lng': '$lng'});
  }

  /// Get seasonal advice for a species and optional month.
  Future<SeasonalAdvice> getSeasonalAdvice({
    required String speciesId,
    int? month,
  }) async {
    final now = DateTime.now();
    final json = await _get('/seasonal/advice', {
      'species_id': speciesId,
      'month': '${month ?? now.month}',
    });
    return SeasonalAdvice.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _getAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    log('[BahaarAI] POST $path  body=${jsonEncode(body)}');
    try {
      final resp = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_kTimeout);
      log('[BahaarAI] POST $path  status=${resp.statusCode}');
      return _handle(resp, path);
    } catch (e) {
      if (e is BahaarOfflineException) rethrow;
      throw BahaarOfflineException(
        'لا يوجد اتصال بالإنترنت، يرجى المحاولة لاحقاً',
        messageEn: 'No internet connection, please try again later',
        messageTechnical: 'Network error on POST $path: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final token = await _getAuthToken();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    log('[BahaarAI] GET $path  params=$params');
    try {
      final resp =
          await _client.get(uri, headers: headers).timeout(_kTimeout);
      log('[BahaarAI] GET $path  status=${resp.statusCode}');
      return _handle(resp, path);
    } catch (e) {
      if (e is BahaarOfflineException) rethrow;
      throw BahaarOfflineException(
        'لا يوجد اتصال بالإنترنت، يرجى المحاولة لاحقاً',
        messageEn: 'No internet connection, please try again later',
        messageTechnical: 'Network error on GET $path: $e',
      );
    }
  }

  Map<String, dynamic> _handle(http.Response resp, String path) {
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return decoded;
    final errMsg = decoded['error'] ?? decoded['message'] ?? resp.body;
    throw BahaarOfflineException(
      'خطأ في الخادم، يرجى المحاولة لاحقاً',
      messageEn: 'Server error, please try again later',
      messageTechnical: 'API ${resp.statusCode} on $path: $errMsg',
    );
  }

  Future<String?> _getAuthToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
