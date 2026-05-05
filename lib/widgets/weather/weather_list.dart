import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/tide_model.dart';
import '../../l10n/weather/weather_localizations.dart';
import '../../utilities/cn/celestial_calculator.dart';
import 'styles.dart';
import '5_compact_card.dart';
import '1_header.dart';
import '2_hourly_forecast.dart';
import '3_daily_forecast.dart';
import '4_wind_card.dart';
import '6_tides_card.dart';
import '7_celestial_almanac_card.dart';
import 'safety_badge.dart';

class WeatherList extends StatelessWidget {
  final WeatherResponseModel weatherData;
  final List<TideEntry> tides;
  final WeatherLocalizations l10n;

  const WeatherList({
    super.key,
    required this.weatherData,
    required this.l10n,
    this.tides = const [],
  });

  @override
  Widget build(BuildContext context) {
    final current = weatherData.currentWeather;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          WeatherHeader(weatherData: weatherData, l10n: l10n),
          WeatherHourlyForecast(weatherData: weatherData, l10n: l10n),
          const SizedBox(height: 20),
          WeatherDailyForecast(weatherData: weatherData, l10n: l10n),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                WeatherWindCard(wind: current, l10n: l10n),
                const SizedBox(height: 16),
                WeatherSafetyBadge(weatherData: weatherData),
                const SizedBox(height: 16),

                // Compact info row 1: UV + Feels like
                Row(children: [
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.wb_sunny_outlined,
                      title: l10n.uvIndex,
                      value: l10n.n(current.uv.round()),
                      subtitle: l10n.uvLevel(current.uv),
                      accentColor: WeatherStyles.uvColor(current.uv),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.thermostat_outlined,
                      title: l10n.feelsLike,
                      value: '${l10n.n(current.feelslikeC.round())}°',
                      subtitle: l10n.feelsLikeDescription(
                          current.feelslikeC, current.tempC),
                      accentColor: const Color(0xFF64B5F6),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Compact info row 2: Humidity + Visibility
                Row(children: [
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.water_drop,
                      title: l10n.humidity,
                      value: '${l10n.n(current.humidity)}%',
                      subtitle:
                          '${l10n.weatherDewPoint} ${l10n.n(current.dewpointC?.round() ?? 0)}°',
                      accentColor: WeatherStyles.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.visibility_outlined,
                      title: l10n.visibility,
                      value:
                          '${l10n.n(current.visKm.round())} ${l10n.km}',
                      subtitle:
                          l10n.visibilityDescription(current.visKm),
                      accentColor: const Color(0xFF81C784),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                WeatherTidesCard(tides: tides, l10n: l10n),
                const SizedBox(height: 16),
                _buildCelestialAlmanac(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCelestialAlmanac() {
    final now = DateTime.now();
    final solar = CelestialCalculator.calculateSolarDay(
        weatherData.location.lat, weatherData.location.lon, now);
    final lunar = CelestialCalculator.calculateLunarDay(
        weatherData.location.lat, weatherData.location.lon, now);
    return CelestialAlmanacCard(solar: solar, lunar: lunar);
  }
}
