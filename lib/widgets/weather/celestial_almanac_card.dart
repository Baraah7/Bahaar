import 'package:flutter/material.dart';
import 'package:Bahaar/utilities/celestial_calculator.dart';

/// Displays sunrise, solar noon, sunset, moonrise and moonset times.
class CelestialAlmanacCard extends StatelessWidget {
  final SolarDay solar;
  final LunarDay lunar;

  const CelestialAlmanacCard({
    super.key,
    required this.solar,
    required this.lunar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Celestial Almanac',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Solar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AlmanacItem(emoji: '🌅', label: 'Sunrise', time: solar.sunrise),
              _AlmanacItem(emoji: '☀️', label: 'Solar Noon', time: solar.solarNoon),
              _AlmanacItem(emoji: '🌇', label: 'Sunset', time: solar.sunset),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 20),
          // Lunar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AlmanacItem(emoji: '🌙', label: 'Moonrise', time: lunar.moonrise),
              _AlmanacItem(
                emoji: lunar.emoji,
                label: lunar.phaseName,
                subtitle: '${lunar.illumination.toStringAsFixed(0)}%',
              ),
              _AlmanacItem(emoji: '🌑', label: 'Moonset', time: lunar.moonset),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlmanacItem extends StatelessWidget {
  final String emoji;
  final String label;
  final DateTime? time;
  final String? subtitle;

  const _AlmanacItem({
    required this.emoji,
    required this.label,
    this.time,
    this.subtitle,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          time != null ? _fmt(time) : (subtitle ?? '--'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
