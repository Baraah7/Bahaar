import 'package:flutter/material.dart';
import 'package:Bahaar/utilities/celestial_calculator.dart';

/// Displays current moon phase with name, illumination, moonrise and moonset.
class MoonPhaseCard extends StatelessWidget {
  final LunarDay lunar;

  const MoonPhaseCard({super.key, required this.lunar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Moon Phase',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Phase emoji — large
              Text(lunar.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lunar.phaseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lunar.illumination.toStringAsFixed(0)}% illuminated',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TimeItem(
                icon: Icons.arrow_upward,
                label: 'Moonrise',
                time: lunar.moonrise,
              ),
              const SizedBox(width: 24),
              _TimeItem(
                icon: Icons.arrow_downward,
                label: 'Moonset',
                time: lunar.moonset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? time;

  const _TimeItem({
    required this.icon,
    required this.label,
    required this.time,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            Text(
              _fmt(time),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
