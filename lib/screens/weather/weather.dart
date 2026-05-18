import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';
import 'package:bahaar/models/weather/tide_model.dart';
import 'package:bahaar/models/weather/weather_response_model.dart';
import 'package:bahaar/services/weather/world_tides_service.dart';
import 'package:bahaar/utilities/celestial_navigation/celestial_calculator.dart';
import 'package:bahaar/utilities/weather/weather_api_service.dart';
import 'package:bahaar/widgets/weather/6_tides_card.dart';
import 'package:bahaar/widgets/weather/7_celestial_almanac_card.dart';
import 'package:bahaar/widgets/weather/weather_list.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<Weather> {
  final weatherService = WeatherApiService();
  final tidesService = WorldTidesService();
  WeatherResponseModel? weatherData;
  List<TideEntry> tides = [];
  bool isLoading = true;

  // Fallback coordinates when GPS is unavailable (Manama, Bahrain)
  static const double _defaultLat = 26.2235;
  static const double _defaultLon = 50.5876;
  double _lat = _defaultLat;
  double _lon = _defaultLon;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      isLoading = true;
    });

    // Resolve GPS location
    String weatherQuery = "Manama";
    double? userLat;
    double? userLon;
    try {
      final loc = Location();
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null) {
        userLat = data.latitude;
        userLon = data.longitude;
        weatherQuery =
            "${data.latitude!.toStringAsFixed(4)},${data.longitude!.toStringAsFixed(4)}";
      }
    } catch (_) {}

    // Store coordinates for offline celestial calculation
    _lat = userLat ?? _defaultLat;
    _lon = userLon ?? _defaultLon;

    // Fetch weather and tides independently so one failure doesn't block the other.
    WeatherResponseModel? fetchedWeather;
    List<TideEntry> fetchedTides = [];

    try {
      fetchedWeather = await weatherService.getWeather(weatherQuery, true, 7, false);
    } catch (_) {
      fetchedWeather = null;
    }

    try {
      fetchedTides = await tidesService.getTides(lat: userLat, lon: userLon);
    } catch (_) {
      fetchedTides = [];
    }

    if (!mounted) return;
    setState(() {
      weatherData = fetchedWeather;
      tides = fetchedTides;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WeatherLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.accent, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : weatherData != null
                // ── Full view: weather + tides + celestial ──────────────────
                ? RefreshIndicator(
                    onRefresh: _loadAll,
                    child: WeatherList(
                        weatherData: weatherData!, tides: tides, l10n: l10n),
                  )
                // ── Offline view: weather error banner + tides + celestial ──
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: _buildOfflineView(l10n),
                  ),
      ),
    );
  }

  Widget _buildOfflineView(WeatherLocalizations l10n) {
    final now = DateTime.now();
    final solar = CelestialCalculator.calculateSolarDay(_lat, _lon, now);
    final lunar = CelestialCalculator.calculateLunarDay(_lat, _lon, now);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weather unavailable banner with retry
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 36),
                const SizedBox(height: 8),
                Text(
                  l10n.unableToLoadWeather,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tidesAndCelestialAvailableOffline,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(l10n.tryAgain,
                      style: const TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tides — served from 24-hour cache if available
          WeatherTidesCard(tides: tides, l10n: l10n),
          const SizedBox(height: 16),
          // Celestial — always offline
          CelestialAlmanacCard(solar: solar, lunar: lunar),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
