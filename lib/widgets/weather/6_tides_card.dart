import 'package:bahaar/l10n/weather/weather_localizations.dart';
import 'package:flutter/material.dart';
import '../../models/weather/tide_model.dart';
import 'styles.dart';

class WeatherTidesCard extends StatelessWidget {
  final List<TideEntry> tides;
  final WeatherLocalizations l10n;

  static const _tideBlue = Color(0xFF4FC3F7);

  const WeatherTidesCard(
      {super.key, required this.tides, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeatherStyles.sectionHeader(
               l10n.weatherTodayTides, _tideBlue),
          const SizedBox(height: 4),
          if (tides.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.waves,
                      color: WeatherStyles.white(0.4), size: 28),
                  const SizedBox(width: 12),
                  Text(
                     l10n.weatherTideUnavailable,
                    style: TextStyle(
                        color: WeatherStyles.white(0.5), fontSize: 15),
                  ),
                ],
              ),
            )
          else
            ...tides.map((entry) => _TideRow(
                entry: entry, l10n: l10n)),
        ],
      ),
    );
  }
}

class _TideRow extends StatelessWidget {
  final TideEntry entry;
  final WeatherLocalizations l10n;

  static const _tideBlue = Color(0xFF4FC3F7);
  static const _tideLow = Color(0xFF81D4FA);

  const _TideRow({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isHigh = entry.isHigh;
    final color = isHigh ? _tideBlue : _tideLow;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHigh ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHigh
                    ?  l10n.weatherHighTide
                    :  l10n.weatherLowTide,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                l10n.formatTime(entry.formattedTime),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${l10n.n(entry.heightMt.toStringAsFixed(2))} m',
            style: TextStyle(
                color: WeatherStyles.white(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
