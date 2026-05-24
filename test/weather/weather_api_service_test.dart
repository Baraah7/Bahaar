import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bahaar/services/weather/weather_api_service.dart';
import 'package:bahaar/models/weather/weather_response_model.dart';

Map<String, dynamic> _successBody() => {
      'location': {
        'name': 'Manama',
        'region': 'Capital',
        'country': 'Bahrain',
        'lat': 26.22,
        'lon': 50.59,
        'tz_id': 'Asia/Bahrain',
        'localtime_epoch': 1700000000,
        'localtime': '2026-01-15 12:00',
      },
      'current': {
        'last_updated_epoch': 1700000000,
        'last_updated': '2026-01-15 12:00',
        'temp_c': 28.5,
        'temp_f': 83.3,
        'is_day': 1,
        'condition': {'text': 'Sunny', 'icon': '//cdn/sunny.png', 'code': 1000},
        'wind_mph': 10.0,
        'wind_kph': 16.1,
        'wind_degree': 90,
        'wind_dir': 'E',
        'pressure_mb': 1013.0,
        'pressure_in': 29.91,
        'humidity': 60,
        'cloud': 10,
        'feelslike_c': 30.0,
        'feelslike_f': 86.0,
        'vis_km': 10.0,
        'vis_miles': 6.2,
        'uv': 6.0,
        'gust_mph': 14.0,
        'gust_kph': 22.5,
      },
      'forecast': {
        'forecastday': [
          {
            'date': '2026-01-15',
            'date_epoch': 1700000000,
            'day': {
              'maxtemp_c': 32.0,
              'maxtemp_f': 89.6,
              'mintemp_c': 24.0,
              'mintemp_f': 75.2,
              'avgtemp_c': 28.0,
              'avgtemp_f': 82.4,
              'maxwind_mph': 15.0,
              'maxwind_kph': 24.1,
              'totalprecip_mm': 0.0,
              'totalprecip_in': 0.0,
              'avghumidity': 62.0,
              'daily_will_it_rain': 0,
              'daily_chance_of_rain': 0,
              'daily_will_it_snow': 0,
              'daily_chance_of_snow': 0,
              'condition': {
                'text': 'Sunny',
                'icon': '//cdn/sunny.png',
                'code': 1000
              },
              'uv': 6.0,
            },
            'astro': {
              'sunrise': '06:10 AM',
              'sunset': '05:50 PM',
              'moonrise': '08:00 PM',
              'moonset': '07:30 AM',
              'moon_phase': 'Full Moon',
              'moon_illumination': '100',
            },
            'hour': [],
          }
        ],
      },
    };

WeatherApiService _makeService(MockClient client) =>
    WeatherApiService(client: client);

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'weatherAPI=test_key_123');
  });

  group('WeatherApiService.getWeather', () {
    test('returns WeatherResponseModel on HTTP 200', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode(_successBody()), 200));
      final result =
          await _makeService(client).getWeather('Manama', true, 7, false);
      expect(result, isA<WeatherResponseModel>());
      expect(result.location.name, 'Manama');
      expect(result.currentWeather.tempC, 28.5);
    });

    test('uses coordinate string when passed instead of city name', () async {
      String? capturedQuery;
      final client = MockClient((request) async {
        capturedQuery = request.url.queryParameters['q'];
        return http.Response(jsonEncode(_successBody()), 200);
      });
      await _makeService(client).getWeather('26.2235,50.5876', true, 7, false);
      expect(capturedQuery, '26.2235,50.5876');
    });

    test('sends aqi=yes when airQuality is true', () async {
      String? aqi;
      final client = MockClient((request) async {
        aqi = request.url.queryParameters['aqi'];
        return http.Response(jsonEncode(_successBody()), 200);
      });
      await _makeService(client).getWeather('Manama', true, 7, false);
      expect(aqi, 'yes');
    });

    test('sends aqi=no when airQuality is false', () async {
      String? aqi;
      final client = MockClient((request) async {
        aqi = request.url.queryParameters['aqi'];
        return http.Response(jsonEncode(_successBody()), 200);
      });
      await _makeService(client).getWeather('Manama', false, 7, false);
      expect(aqi, 'no');
    });

    test('sends days parameter in query', () async {
      String? days;
      final client = MockClient((request) async {
        days = request.url.queryParameters['days'];
        return http.Response(jsonEncode(_successBody()), 200);
      });
      await _makeService(client).getWeather('Manama', true, 7, false);
      expect(days, '7');
    });

    test('throws on HTTP 400 with API error message', () async {
      final client = MockClient((_) async => http.Response(
          jsonEncode({
            'error': {'code': 1006, 'message': 'No matching location found'}
          }),
          400));
      expect(
        () => _makeService(client).getWeather('??invalid??', true, 7, false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No matching location'))),
      );
    });

    test('throws on HTTP 401 with authentication message', () async {
      final client = MockClient(
          (_) async => http.Response('{"error":{"code":2006}}', 401));
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Invalid API key'))),
      );
    });

    test('throws on HTTP 403 with authentication message', () async {
      final client = MockClient(
          (_) async => http.Response('{"error":{"code":2007}}', 403));
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Invalid API key'))),
      );
    });

    test('throws on HTTP 500 with server error message', () async {
      final client =
          MockClient((_) async => http.Response('Internal Server Error', 500));
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Server error: 500'))),
      );
    });

    test('throws on network exception (ClientException)', () async {
      final client = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when API key is missing from env', () async {
      dotenv.clean();
      final client =
          MockClient((_) async => http.Response('{}', 200));
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('api key'))),
      );
      // Restore key for subsequent tests
      dotenv.loadFromString(envString: 'weatherAPI=test_key_123');
    });

    test('attaches API key to request header', () async {
      String? keyInQuery;
      final client = MockClient((request) async {
        keyInQuery = request.url.queryParameters['key'];
        return http.Response(jsonEncode(_successBody()), 200);
      });
      await _makeService(client).getWeather('Manama', true, 7, false);
      expect(keyInQuery, 'test_key_123');
    });

    test('throws on malformed JSON response body', () async {
      final client =
          MockClient((_) async => http.Response('not valid json', 200));
      expect(
        () => _makeService(client).getWeather('Manama', true, 7, false),
        throwsA(isA<Exception>()),
      );
    });
  });
}
