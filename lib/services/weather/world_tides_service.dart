import 'dart:convert';
import 'package:bahaar/models/weather/tide_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches tide predictions from the WorldTides API v3 (worldtides.info).
/// Free plan: 10 requests/day — results are cached for 24 hours to stay
/// within quota.
class WorldTidesService {
  // Bahrain (Manama) coordinates
  static const double _lat = 26.2235;
  static const double _lon = 50.5876;

  static const _cacheKey = 'tides_cache_json';
  static const _cacheTimeKey = 'tides_cache_time';

  final http.Client _client;

  WorldTidesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TideEntry>> getTides({int days = 1}) async {
    // Return cached data if it is less than 24 hours old.
    final cached = await _loadCache();
    if (cached != null) return cached;

    final apiKey = dotenv.env['WORLDTIDES_API'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_WORLDTIDES_KEY_HERE') {
      return [];
    }

    try {
      final url =
          'https://www.worldtides.info/api/v3?extremes&lat=$_lat&lon=$_lon&key=$apiKey&days=$days';
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if ((data['status'] as int?) != 200) return [];

      final extremes = data['extremes'] as List?;
      if (extremes == null || extremes.isEmpty) return [];

      final entries = extremes
          .map((e) => TideEntry.fromWorldTidesJson(e as Map<String, dynamic>))
          .toList();

      await _saveCache(extremes.cast<Map<String, dynamic>>());
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<List<TideEntry>?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getInt(_cacheTimeKey);
      if (savedTime == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - savedTime;
      if (age > const Duration(hours: 24).inMilliseconds) return null;

      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;

      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TideEntry.fromWorldTidesJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(List<Map<String, dynamic>> extremes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(extremes));
      await prefs.setInt(
          _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
