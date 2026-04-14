import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/hour_model.dart';
import 'styles.dart';
import 'weather_l10n_helper.dart';

class WeatherHourlyForecast extends StatelessWidget {
  final WeatherResponseModel weatherData;
  final WeatherL10nHelper helper;

  const WeatherHourlyForecast(
      {super.key, required this.weatherData, required this.helper});

  @override
  Widget build(BuildContext context) {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final hours = weatherData.forecast!.forecastDays
        .expand((day) => day.hour)
        .where((h) => DateTime.parse(h.time)
            .isAfter(now.subtract(const Duration(hours: 1))))
        .take(24)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          WeatherStyles.sectionHeader(
              helper.l10n.hourlyForecast, WeatherStyles.accent),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hours.length,
              itemBuilder: (context, index) =>
                  _HourItem(hour: hours[index], isNow: index == 0, helper: helper),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HourItem extends StatelessWidget {
  final HourModel hour;
  final bool isNow;
  final WeatherL10nHelper helper;

  const _HourItem(
      {required this.hour, required this.isNow, required this.helper});

  @override
  Widget build(BuildContext context) {
    final hourTime = DateTime.parse(hour.time);
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isNow
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WeatherStyles.accent.withValues(alpha: 0.3),
                  WeatherStyles.accent.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: WeatherStyles.accent.withValues(alpha: 0.5)),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow
                ? helper.l10n.weatherNow
                : helper.n('${hourTime.hour}:00'),
            style: TextStyle(
              color: isNow
                  ? WeatherStyles.accent
                  : WeatherStyles.white(0.8),
              fontSize: 14,
              fontWeight:
                  isNow ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          WeatherStyles.weatherIcon(hour.conditionIcon, size: 36),
          Text(
            '${helper.n(hour.tempC.round())}°',
            style: TextStyle(
              color: isNow ? Colors.white : WeatherStyles.white(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
