import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/weather/weather_response_model.dart';
import 'package:bahaar/models/weather/current_weather_model.dart';

Map<String, dynamic> _validCurrentJson() => {
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
    };

Map<String, dynamic> _validResponseJson({bool includeForecast = false}) {
  final json = <String, dynamic>{
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
    'current': _validCurrentJson(),
  };
  if (includeForecast) {
    json['forecast'] = {
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
    };
  }
  return json;
}

void main() {
  // ── WeatherResponseModel ─────────────────────────────────────────────────────

  group('WeatherResponseModel.fromJson', () {
    test('parses a valid full response without forecast', () {
      final model = WeatherResponseModel.fromJson(_validResponseJson());
      expect(model.location.name, 'Manama');
      expect(model.currentWeather.tempC, 28.5);
      expect(model.forecast, isNull);
    });

    test('parses a valid full response with forecast', () {
      final model =
          WeatherResponseModel.fromJson(_validResponseJson(includeForecast: true));
      expect(model.forecast, isNotNull);
      expect(model.forecast!.forecastDays, hasLength(1));
    });

    test('current getter delegates to currentWeather', () {
      final model = WeatherResponseModel.fromJson(_validResponseJson());
      expect(model.current, same(model.currentWeather));
    });

    test('throws when "location" field is missing', () {
      final json = _validResponseJson()..remove('location');
      expect(() => WeatherResponseModel.fromJson(json), throwsException);
    });

    test('throws when "current" field is missing', () {
      final json = _validResponseJson()..remove('current');
      expect(() => WeatherResponseModel.fromJson(json), throwsException);
    });

    test('null "forecast" field is handled gracefully', () {
      final json = _validResponseJson();
      json['forecast'] = null;
      final model = WeatherResponseModel.fromJson(json);
      expect(model.forecast, isNull);
    });
  });

  // ── CurrentWeatherModel ──────────────────────────────────────────────────────

  group('CurrentWeatherModel.fromJson', () {
    test('parses all required fields correctly', () {
      final model = CurrentWeatherModel.fromJson(_validCurrentJson());
      expect(model.tempC, 28.5);
      expect(model.tempF, 83.3);
      expect(model.isDay, 1);
      expect(model.windKph, 16.1);
      expect(model.humidity, 60);
      expect(model.visKm, 10.0);
      expect(model.uv, 6.0);
    });

    test('parses optional nullable fields as null when absent', () {
      final model = CurrentWeatherModel.fromJson(_validCurrentJson());
      expect(model.windchillC, isNull);
      expect(model.windchillF, isNull);
      expect(model.heatindexC, isNull);
      expect(model.dewpointC, isNull);
      expect(model.shortRad, isNull);
      expect(model.diffRad, isNull);
      expect(model.dni, isNull);
      expect(model.gti, isNull);
    });

    test('parses optional nullable fields when present', () {
      final json = _validCurrentJson()
        ..addAll({
          'windchill_c': 26.0,
          'heatindex_c': 31.5,
          'dewpoint_c': 18.0,
          'short_rad': 500.0,
        });
      final model = CurrentWeatherModel.fromJson(json);
      expect(model.windchillC, 26.0);
      expect(model.heatindexC, 31.5);
      expect(model.dewpointC, 18.0);
      expect(model.shortRad, 500.0);
    });

    test('throws when "temp_c" is missing', () {
      final json = _validCurrentJson()..remove('temp_c');
      expect(() => CurrentWeatherModel.fromJson(json), throwsException);
    });

    test('throws when "condition" is missing', () {
      final json = _validCurrentJson()..remove('condition');
      expect(() => CurrentWeatherModel.fromJson(json), throwsException);
    });

    test('throws when "is_day" is missing', () {
      final json = _validCurrentJson()..remove('is_day');
      expect(() => CurrentWeatherModel.fromJson(json), throwsException);
    });

    test('handles integer temp values from API (num cast)', () {
      final json = _validCurrentJson();
      json['temp_c'] = 28; // int not double
      json['temp_f'] = 83;
      final model = CurrentWeatherModel.fromJson(json);
      expect(model.tempC, 28.0);
      expect(model.tempF, 83.0);
    });

    test('handles integer uv value from API (num cast)', () {
      final json = _validCurrentJson();
      json['uv'] = 6; // int from API
      final model = CurrentWeatherModel.fromJson(json);
      expect(model.uv, 6.0);
    });
  });

  // ── ConditionModel ───────────────────────────────────────────────────────────

  group('ConditionModel.fromJson', () {
    test('parses valid condition object', () {
      final model = CurrentWeatherModel.fromJson(_validCurrentJson());
      expect(model.condition.text, 'Sunny');
      expect(model.condition.icon, '//cdn/sunny.png');
      expect(model.condition.code, 1000);
    });

    test('throws when condition "text" is missing', () {
      final json = _validCurrentJson();
      json['condition'] = {'icon': '//cdn/x.png', 'code': 1000};
      expect(() => CurrentWeatherModel.fromJson(json), throwsException);
    });

    test('throws when condition "code" is missing', () {
      final json = _validCurrentJson();
      json['condition'] = {'text': 'Sunny', 'icon': '//cdn/x.png'};
      expect(() => CurrentWeatherModel.fromJson(json), throwsException);
    });
  });
}
