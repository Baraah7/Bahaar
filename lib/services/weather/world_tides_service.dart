import 'dart:convert';
import 'package:bahaar/models/weather/tide_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches tide predictions from the WorldTides API v3 (worldtides.info).
/// Free plan: 10 requests/day — results are cached per location for 24 hours.
class WorldTidesService {
  // Fallback coordinates (Bahrain / Manama) when GPS is unavailable.
  static const double _defaultLat = 26.2235;
  static const double _defaultLon = 50.5876;

  final http.Client _client;

  WorldTidesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TideEntry>> getTides({
    int days = 1,
    double? lat,
    double? lon,
  }) async {
    final usedLat = lat ?? _defaultLat;
    final usedLon = lon ?? _defaultLon;

    // Round to 1 decimal (~11 km grid) so nearby GPS fixes share a cache entry.
    final cacheKey = _cacheKey(usedLat, usedLon);
    final cacheTimeKey = _cacheTimeKey(usedLat, usedLon);

    final cached = await _loadCache(cacheKey, cacheTimeKey);
    if (cached != null) return cached;

    final apiKey = dotenv.env['WORLDTIDES_API'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_WORLDTIDES_KEY_HERE') {
      return [];
    }

    try {
      final url =
          'https://www.worldtides.info/api/v3?extremes&lat=$usedLat&lon=$usedLon&key=$apiKey&days=$days';
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((data['status'] as int?) != 200) return [];

      final extremes = data['extremes'] as List?;
      if (extremes == null || extremes.isEmpty) return [];

      final entries = extremes
          .map((e) => TideEntry.fromWorldTidesJson(e as Map<String, dynamic>))
          .toList();

      await _saveCache(cacheKey, cacheTimeKey, extremes.cast<Map<String, dynamic>>());
      return entries;
    } catch (_) {
      return [];
    }
  }

  String _cacheKey(double lat, double lon) =>
      'tides_cache_json_${lat.toStringAsFixed(1)}_${lon.toStringAsFixed(1)}';

  String _cacheTimeKey(double lat, double lon) =>
      'tides_cache_time_${lat.toStringAsFixed(1)}_${lon.toStringAsFixed(1)}';

  Future<List<TideEntry>?> _loadCache(String cacheKey, String cacheTimeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getInt(cacheTimeKey);
      if (savedTime == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - savedTime;
      if (age > const Duration(hours: 24).inMilliseconds) return null;

      final raw = prefs.getString(cacheKey);
      if (raw == null) return null;

      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TideEntry.fromWorldTidesJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(
    String cacheKey,
    String cacheTimeKey,
    List<Map<String, dynamic>> extremes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(extremes));
      await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
