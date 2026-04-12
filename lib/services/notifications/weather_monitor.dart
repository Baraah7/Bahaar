import 'dart:async';
import 'dart:developer';
import 'package:Bahaar/services/notifications/notification_service.dart';
import 'package:Bahaar/services/marine_weather_service.dart';
import 'package:Bahaar/services/weather/world_tides_service.dart';

/// Periodically checks weather and tide conditions, fires local notifications
/// when thresholds are exceeded.
class WeatherMonitor {
  WeatherMonitor._();
  static final WeatherMonitor instance = WeatherMonitor._();

  static const Duration _pollInterval = Duration(minutes: 30);

  // Thresholds
  static const double _windKnotsThreshold = 25.0;
  static const double _waveHeightThreshold = 2.5; // metres

  Timer? _timer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _check(); // immediate first check
    _timer = Timer.periodic(_pollInterval, (_) => _check());
    log('WeatherMonitor: started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    log('WeatherMonitor: stopped');
  }

  Future<void> _check() async {
    try {
      await _checkWeather();
      await _checkTides();
    } catch (e) {
      log('WeatherMonitor: check failed — $e');
    }
  }

  Future<void> _checkWeather() async {
    final service = MarineWeatherService();
    await service.refreshWeather();

    // Check worst conditions across all sampled grid points
    for (final assessment in service.getActiveWarnings()) {
      final data = assessment.data;
      // windSpeed from Open-Meteo is km/h — convert to knots
      final windKnots = data.windSpeed / 1.852;
      final waveM = data.waveHeight;

      if (windKnots > _windKnotsThreshold) {
        await NotificationService.instance.showWeatherAlert(
          title: 'Strong Wind Warning',
          body:
              'Wind speed ${windKnots.toStringAsFixed(0)} kn — conditions may be unsafe for fishing.',
          id: 2001,
        );
      }

      if (waveM > _waveHeightThreshold) {
        await NotificationService.instance.showWeatherAlert(
          title: 'High Seas Alert',
          body:
              'Wave height ${waveM.toStringAsFixed(1)} m — exercise caution at sea.',
          id: 2002,
        );
      }
      break; // alert once per check cycle
    }
  }

  Future<void> _checkTides() async {
    try {
      final tides = await WorldTidesService().getTides();
      if (tides.isEmpty) return;

      final now = DateTime.now();
      for (final tide in tides) {
        final tideTime = tide.dateTime; // TideEntry.dateTime getter
        final diff = tideTime.difference(now);
        if (diff.isNegative || diff > const Duration(hours: 1)) continue;

        final type = tide.isHigh ? 'high' : 'low';
        final mins = diff.inMinutes;
        await NotificationService.instance.showTideAlert(
          body:
              'Tide turning $type in $mins minute${mins == 1 ? '' : 's'} (${tide.heightMt.toStringAsFixed(1)} m).',
        );
        break; // one tide alert per check cycle
      }
    } catch (e) {
      log('WeatherMonitor: tide check failed — $e');
    }
  }
}

