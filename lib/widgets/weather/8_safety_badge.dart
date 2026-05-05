import 'package:bahaar/models/weather/marine_weather_model.dart';
import 'package:bahaar/models/weather/weather_response_model.dart';
import 'package:bahaar/utilities/map/navigation_constants.dart';
import 'package:flutter/material.dart';
import '../../l10n/weather/weather_localizations.dart';
import 'styles.dart';

/// Derives a [SafetyLevel] from a [WeatherResponseModel] using the same
/// thresholds as [MarineSafetyThresholds], then renders a prominent badge.
class WeatherSafetyBadge extends StatelessWidget {
  final WeatherResponseModel weatherData;
  final WeatherLocalizations l10n;

  const WeatherSafetyBadge({super.key, required this.weatherData, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final assessment = _assess(weatherData);
    final level = assessment.level;

    final color = _colorFor(level);
    final icon = _iconFor(level);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeatherStyles.sectionHeader(l10n.marineSafety, color),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _levelDisplayName(level),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _levelDescription(level),
                    style: TextStyle(
                      color: WeatherStyles.white(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (assessment.warnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...assessment.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: color.withValues(alpha: 0.8), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: TextStyle(
                          color: WeatherStyles.white(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _levelDisplayName(SafetyLevel level) => switch (level) {
        SafetyLevel.safe => l10n.safetyLevelSafe,
        SafetyLevel.caution => l10n.safetyLevelCaution,
        SafetyLevel.dangerous => l10n.safetyLevelDangerous,
        SafetyLevel.blocked => l10n.safetyLevelBlocked,
      };

  String _levelDescription(SafetyLevel level) => switch (level) {
        SafetyLevel.safe => l10n.safetyDescSafe,
        SafetyLevel.caution => l10n.safetyDescCaution,
        SafetyLevel.dangerous => l10n.safetyDescDangerous,
        SafetyLevel.blocked => l10n.safetyDescBlocked,
      };

  WeatherSafetyAssessment _assess(WeatherResponseModel data) {
    final current = data.currentWeather;
    final windKph = current.windKph;
    final visMeters = current.visKm * 1000;

    SafetyLevel worst = SafetyLevel.safe;
    final warnings = <String>[];

    final windKnots = windKph / 1.852;
    if (windKph >= NavigationConstants.windSpeedBlockedKph) {
      worst = SafetyLevel.blocked;
      warnings.add(l10n.windExceedsLimit(windKnots.toStringAsFixed(0)));
    } else if (windKph >= NavigationConstants.windSpeedDangerousKph) {
      worst = _worst(worst, SafetyLevel.dangerous);
      warnings.add(l10n.strongWind(windKnots.toStringAsFixed(0)));
    } else if (windKph >= NavigationConstants.windSpeedCautionKph) {
      worst = _worst(worst, SafetyLevel.caution);
      warnings.add(l10n.moderateWind(windKnots.toStringAsFixed(0)));
    }

    if (visMeters <= NavigationConstants.visibilityBlockedMeters) {
      worst = SafetyLevel.blocked;
      warnings.add(l10n.visibilityBelowLimit(current.visKm.toStringAsFixed(1)));
    } else if (visMeters <= NavigationConstants.visibilityDangerousMeters) {
      worst = _worst(worst, SafetyLevel.dangerous);
      warnings.add(l10n.lowVisibilityKm(current.visKm.toStringAsFixed(1)));
    } else if (visMeters <= NavigationConstants.visibilityCautionMeters) {
      worst = _worst(worst, SafetyLevel.caution);
      warnings.add(l10n.reducedVisibility(current.visKm.toStringAsFixed(1)));
    }

    return WeatherSafetyAssessment(
      level: worst,
      costMultiplier: 1.0,
      warnings: warnings,
      data: _dummyData(data),
    );
  }

  SafetyLevel _worst(SafetyLevel a, SafetyLevel b) =>
      a.index >= b.index ? a : b;

  Color _colorFor(SafetyLevel level) => switch (level) {
        SafetyLevel.safe => const Color(0xFF66BB6A),
        SafetyLevel.caution => const Color(0xFFFFCA28),
        SafetyLevel.dangerous => const Color(0xFFFF7043),
        SafetyLevel.blocked => const Color(0xFFEF5350),
      };

  IconData _iconFor(SafetyLevel level) => switch (level) {
        SafetyLevel.safe => Icons.check_circle_outline,
        SafetyLevel.caution => Icons.warning_amber_rounded,
        SafetyLevel.dangerous => Icons.dangerous_outlined,
        SafetyLevel.blocked => Icons.block,
      };

  MarineWeatherData _dummyData(WeatherResponseModel data) {
    final c = data.currentWeather;
    return MarineWeatherData(
      latitude: data.location.lat,
      longitude: data.location.lon,
      timestamp: DateTime.now(),
      waveHeight: 0,
      wavePeriod: 0,
      windWaveHeight: 0,
      swellWaveHeight: 0,
      windSpeed: c.windKph,
      windGusts: c.gustKph,
      visibility: c.visKm * 1000,
    );
  }
}
