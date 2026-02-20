import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather/tide_model.dart';

/// Fetches tide predictions from the WorldTides API v3 (worldtides.info).
/// Free plan: 10 requests/day.
/// Sign up at https://www.worldtides.info to get an API key,
/// then set WORLDTIDES_API in secrets.env.
class WorldTidesService {
  // Bahrain (Manama) coordinates
  static const double _lat = 26.2235;
  static const double _lon = 50.5876;

  final http.Client _client;

  WorldTidesService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<TideEntry>> getTides({int days = 1}) async {
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

      return extremes
          .map((e) => TideEntry.fromWorldTidesJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
