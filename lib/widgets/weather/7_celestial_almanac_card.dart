import 'package:flutter/material.dart';
import 'package:bahaar/utilities/cn/celestial_calculator.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';

/// Displays sunrise, solar noon, sunset, moonrise and moonset times.
class CelestialAlmanacCard extends StatelessWidget {
  final SolarDay solar;
  final LunarDay lunar;

  const CelestialAlmanacCard({
    super.key,
    required this.solar,
    required this.lunar,
  });

  String _n(String value, bool isAr) {
    if (!isAr) return value;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  String _fmt(DateTime? dt, bool isAr) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12
        ? (isAr ? 'ص' : 'AM')
        : (isAr ? 'م' : 'PM');
    final timeStr = '$h:$m $period';
    return _n(timeStr, isAr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = WeatherLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final illuminationStr =
        '${_n(lunar.illumination.toStringAsFixed(0), isAr)}%';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.wb_sunny_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                l10n.celestialAlmanac,
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
              _AlmanacItem(
                  emoji: '🌅',
                  label: l10n.sunrise,
                  timeStr: _fmt(solar.sunrise, isAr)),
              _AlmanacItem(
                  emoji: '☀️',
                  label: l10n.solarNoon,
                  timeStr: _fmt(solar.solarNoon, isAr)),
              _AlmanacItem(
                  emoji: '🌇',
                  label: l10n.sunset,
                  timeStr: _fmt(solar.sunset, isAr)),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 20),
          // Lunar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AlmanacItem(
                  emoji: '🌙',
                  label: l10n.moonrise,
                  timeStr: _fmt(lunar.moonrise, isAr)),
              _AlmanacItem(
                emoji: lunar.emoji,
                label: isAr
                    ? _moonPhaseAr(lunar.phaseName)
                    : lunar.phaseName,
                timeStr: illuminationStr,
              ),
              _AlmanacItem(
                  emoji: '🌑',
                  label: l10n.moonset,
                  timeStr: _fmt(lunar.moonset, isAr)),
            ],
          ),
        ],
      ),
    );
  }

  static String _moonPhaseAr(String phase) {
    const map = {
      'New Moon': 'محاق',
      'Waxing Crescent': 'هلال متصاعد',
      'First Quarter': 'تربيع أول',
      'Waxing Gibbous': 'أحدب متصاعد',
      'Full Moon': 'بدر',
      'Waning Gibbous': 'أحدب متناقص',
      'Last Quarter': 'تربيع أخير',
      'Waning Crescent': 'هلال متناقص',
    };
    return map[phase] ?? phase;
  }
}

class _AlmanacItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String timeStr;

  const _AlmanacItem({
    required this.emoji,
    required this.label,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          timeStr,
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
