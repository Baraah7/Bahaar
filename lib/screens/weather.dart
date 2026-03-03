import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utilities/weather_api_service.dart';
import '../services/world_tides_service.dart';
import '../models/weather/weather_response_model.dart';
import '../models/weather/tide_model.dart';
import '../widgets/weather/weather_list.dart';
import '../l10n/app_localizations.dart';

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<Weather> {
  final weatherService = WeatherApiService();
  final tidesService = WorldTidesService();
  weather_response_model? weatherData;
  List<TideEntry> tides = [];
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        weatherService.getWeather("Manama", true, 7, false),
        tidesService.getTides(),
      ]);

      setState(() {
        weatherData = results[0] as weather_response_model;
        tides = results[1] as List<TideEntry>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadWeatherData() => _loadAll();

  // Get gradient colors based on time of day and weather condition
  List<Color> _getGradientColors() {
    if (weatherData == null) {
      return [const Color(0xFF0D1B2A), const Color(0xFF1B3A4B), const Color(0xFF065A60)];
    }

    final isDay = weatherData!.currentWeather.is_day == 1;
    final condition = weatherData!.currentWeather.condition.text.toLowerCase();

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return isDay
          ? [const Color(0xFF1A365D), const Color(0xFF2D4A6F), const Color(0xFF4A6FA5)]
          : [const Color(0xFF0D1321), const Color(0xFF1D2D44), const Color(0xFF3E5C76)];
    } else if (condition.contains('cloud') || condition.contains('overcast')) {
      return isDay
          ? [const Color(0xFF2C3E50), const Color(0xFF4A6572), const Color(0xFF607D8B)]
          : [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)];
    } else if (condition.contains('snow')) {
      return [const Color(0xFF2E4057), const Color(0xFF4A6FA5), const Color(0xFF7BA3C4)];
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return [const Color(0xFF37474F), const Color(0xFF546E7A), const Color(0xFF78909C)];
    } else {
      // Clear/Sunny - ocean-inspired deep sea gradients
      return isDay
          ? [const Color(0xFF1B4965), const Color(0xFF2E86AB), const Color(0xFF1B4965)]
          : [const Color(0xFF0D1B2A), const Color(0xFF1B3A4B), const Color(0xFF065A60)];
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadWeatherData,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getGradientColors(),
            ),
          ),
          child: SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off,
                                color: Colors.white70, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              l10n.unableToLoadWeather,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadWeatherData,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.tryAgain),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : weatherData != null
                        ? WeatherList(weatherData: weatherData!, tides: tides)
                        : Center(
                            child: Text(
                              l10n.noDataAvailable,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}
