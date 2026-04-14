import 'package:flutter/material.dart';
import '../../models/weather/tide_model.dart';
import 'styles.dart';
import 'weather_l10n_helper.dart';

class WeatherTidesCard extends StatelessWidget {
  final List<TideEntry> tides;
  final WeatherL10nHelper helper;

  static const _tideBlue = Color(0xFF4FC3F7);

  const WeatherTidesCard(
      {super.key, required this.tides, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeatherStyles.sectionHeader(
              helper.l10n.weatherTodayTides, _tideBlue),
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
                    helper.l10n.weatherTideUnavailable,
                    style: TextStyle(
                        color: WeatherStyles.white(0.5), fontSize: 15),
                  ),
                ],
              ),
            )
          else
            ...tides.map((entry) => _TideRow(
                entry: entry, helper: helper)),
        ],
      ),
    );
  }
}

class _TideRow extends StatelessWidget {
  final TideEntry entry;
  final WeatherL10nHelper helper;

  static const _tideBlue = Color(0xFF4FC3F7);
  static const _tideLow = Color(0xFF81D4FA);

  const _TideRow({required this.entry, required this.helper});

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
                    ? helper.l10n.weatherHighTide
                    : helper.l10n.weatherLowTide,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                helper.formatTime(entry.formattedTime),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${helper.n(entry.heightMt.toStringAsFixed(2))} m',
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
