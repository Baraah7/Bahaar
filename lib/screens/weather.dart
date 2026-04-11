import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import '../utilities/weather_api_service.dart';
import '../services/world_tides_service.dart';
import '../models/weather/weather_response_model.dart';
import '../models/weather/tide_model.dart';
import '../widgets/weather/weather_list.dart';
import '../l10n/app_localizations.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

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
      String weatherQuery = "Manama";
      try {
        final loc = Location();
        final data = await loc.getLocation();
        if (data.latitude != null && data.longitude != null) {
          weatherQuery =
              "${data.latitude!.toStringAsFixed(4)},${data.longitude!.toStringAsFixed(4)}";
        }
      } catch (_) {}

      final results = await Future.wait([
        weatherService.getWeather(weatherQuery, true, 7, false),
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
              onPressed: _loadAll,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
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
                              onPressed: _loadAll,
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
                        ? WeatherList(weatherData: weatherData!, tides: tides, l10n: l10n)
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
