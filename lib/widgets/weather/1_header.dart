import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import 'styles.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';

class WeatherHeader extends StatelessWidget {
  final WeatherResponseModel weatherData;

  const WeatherHeader(
      {super.key, required this.weatherData, required WeatherLocalizations l10n});

  @override
  Widget build(BuildContext context) {
    final l10n = WeatherLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: WeatherStyles.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: WeatherStyles.accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.cityName(weatherData.location.name).toUpperCase(),
                // helper.cityName(weatherData.location.name).toUpperCase(),
                style: TextStyle(
                  color: WeatherStyles.white(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temperature circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: WeatherStyles.white(0.1), width: 2),
                ),
              ),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      WeatherStyles.white(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.n(weatherData.currentWeather.tempC.round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        color: WeatherStyles.white(0.7),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: WeatherStyles.white(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: WeatherStyles.white(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeatherStyles.weatherIcon(
                    weatherData.currentWeather.condition.icon,
                    size: 28),
                const SizedBox(width: 8),
                Text(
                  l10n.conditionText(
                      weatherData.currentWeather.condition.text),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // High / Low
          if (weatherData.forecast != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TempIndicator(
                  temp: weatherData.forecast!.forecastDay.day.maxtempC
                      .round(),
                  icon: Icons.arrow_upward,
                  color: WeatherStyles.orange,
                  l10n: l10n,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                      width: 40,
                      height: 2,
                      child: WeatherStyles.gradientDivider()),
                ),
                _TempIndicator(
                  temp: weatherData.forecast!.forecastDay.day.mintempC
                      .round(),
                  icon: Icons.arrow_downward,
                  color: const Color(0xFF64B5F6),
                  l10n: l10n,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TempIndicator extends StatelessWidget {
  final int temp;
  final IconData icon;
  final Color color;
  final WeatherLocalizations l10n;


  const _TempIndicator(
      {
      required this.temp,
      required this.icon,
      required this.color,
      required this.l10n,
      });

  @override
  Widget build(BuildContext context) {

    final l10n = WeatherLocalizations.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('${l10n.n(temp)}°',
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
