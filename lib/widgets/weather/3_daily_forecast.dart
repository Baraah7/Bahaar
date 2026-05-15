import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/forecast_day_model.dart';
import 'styles.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';

class WeatherDailyForecast extends StatelessWidget {
  final WeatherResponseModel weatherData;
  final WeatherLocalizations l10n;

  const WeatherDailyForecast(
      {super.key, required this.weatherData, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final days = weatherData.forecast!.forecastDays;
    final weekMin = days.map((d) => d.day.mintempC).reduce(math.min);
    final weekMax = days.map((d) => d.day.maxtempC).reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          WeatherStyles.sectionHeader(
              '${l10n.n(days.length)}-${l10n.dailyForecast}',
              WeatherStyles.orange),
          ...days.asMap().entries.map((e) => _DayRow(
                day: e.value,
                isToday: e.key == 0,
                weekMin: weekMin,
                weekMax: weekMax,
                currentTemp: weatherData.currentWeather.tempC,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final ForecastDay day;
  final bool isToday;
  final double weekMin;
  final double weekMax;
  final double currentTemp;
  // final WeatherL10nHelper helper;

  const _DayRow({
    required this.day,
    required this.isToday,
    required this.weekMin,
    required this.weekMax,
    required this.currentTemp,
    // required this.helper,
  });

  @override
  Widget build(BuildContext context) {

    final l10n = WeatherLocalizations.of(context);
    final date = DateTime.parse(day.date);
    final dayName =
        isToday ? l10n.weatherToday : l10n.dayName(date.weekday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: isToday
          ? BoxDecoration(color: WeatherStyles.white(0.08))
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              dayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isToday ? Colors.white : WeatherStyles.white(0.8),
                fontSize: 15,
                fontWeight:
                    isToday ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          WeatherStyles.weatherIcon(day.day.conditionIcon),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: day.day.dailyChanceOfRain > 0
                ? Row(
                    children: [
                      const Icon(Icons.water_drop,
                          color: WeatherStyles.accent, size: 12),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          '${l10n.n(day.day.dailyChanceOfRain)}%',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: WeatherStyles.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          const Spacer(),
          Text(
            '${l10n.n(day.day.mintempC.round())}°',
            style: TextStyle(
                color: WeatherStyles.white(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: _TemperatureBar(
              min: day.day.mintempC,
              max: day.day.maxtempC,
              weekMin: weekMin,
              weekMax: weekMax,
              currentTemp: isToday ? currentTemp : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.n(day.day.maxtempC.round())}°',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TemperatureBar extends StatelessWidget {
  final double min;
  final double max;
  final double weekMin;
  final double weekMax;
  final double? currentTemp;

  const _TemperatureBar({
    required this.min,
    required this.max,
    required this.weekMin,
    required this.weekMax,
    this.currentTemp,
  });

  @override
  Widget build(BuildContext context) {
    final range = weekMax - weekMin;
    final startPercent = (min - weekMin) / range;
    final endPercent = (max - weekMin) / range;
    final currentPercent =
        currentTemp != null ? (currentTemp! - weekMin) / range : null;

    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: 6,
        decoration: BoxDecoration(
          color: WeatherStyles.white(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * startPercent,
              right: constraints.maxWidth * (1 - endPercent),
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF64B5F6),
                    WeatherStyles.orange,
                    WeatherStyles.coral,
                  ]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (currentPercent != null)
              Positioned(
                left: (constraints.maxWidth * currentPercent - 5)
                    .clamp(0, constraints.maxWidth - 10),
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4)
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
