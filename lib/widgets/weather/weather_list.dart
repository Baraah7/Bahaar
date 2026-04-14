import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/tide_model.dart';
import '../../l10n/app_localizations.dart';
import '../../utilities/cn/celestial_calculator.dart';
import 'styles.dart';
import 'weather_l10n_helper.dart';
import 'compact_card.dart';
import 'header.dart';
import 'hourly_forecast.dart';
import 'daily_forecast.dart';
import 'wind_card.dart';
import 'sun_moon_card.dart';
import 'tides_card.dart';
import 'celestial_almanac_card.dart';

class WeatherList extends StatelessWidget {
  final WeatherResponseModel weatherData;
  final List<TideEntry> tides;
  final AppLocalizations l10n;

  const WeatherList({
    super.key,
    required this.weatherData,
    required this.l10n,
    this.tides = const [],
  });

  @override
  Widget build(BuildContext context) {
    final helper = WeatherL10nHelper(l10n);
    final current = weatherData.currentWeather;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          WeatherHeader(weatherData: weatherData, helper: helper),
          WeatherHourlyForecast(weatherData: weatherData, helper: helper),
          const SizedBox(height: 20),
          WeatherDailyForecast(weatherData: weatherData, helper: helper),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                WeatherWindCard(wind: current, helper: helper),
                const SizedBox(height: 16),

                // Compact info row 1: UV + Feels like
                Row(children: [
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.wb_sunny_outlined,
                      title: l10n.uvIndex,
                      value: helper.n(current.uv.round()),
                      subtitle: helper.uvLevel(current.uv),
                      accentColor: WeatherStyles.uvColor(current.uv),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.thermostat_outlined,
                      title: l10n.feelsLike,
                      value: '${helper.n(current.feelslikeC.round())}°',
                      subtitle: helper.feelsLikeDescription(
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
                      value: '${helper.n(current.humidity)}%',
                      subtitle:
                          '${l10n.weatherDewPoint} ${helper.n(current.dewpointC?.round() ?? 0)}°',
                      accentColor: WeatherStyles.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WeatherCompactCard(
                      icon: Icons.visibility_outlined,
                      title: l10n.visibility,
                      value:
                          '${helper.n(current.visKm.round())} ${helper.km}',
                      subtitle:
                          helper.visibilityDescription(current.visKm),
                      accentColor: const Color(0xFF81C784),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                if (weatherData.forecast != null)
                  WeatherSunMoonCard(
                    astro: weatherData.forecast!.forecastDay.astro,
                    helper: helper,
                  ),
                const SizedBox(height: 16),
                WeatherTidesCard(tides: tides, helper: helper),
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
