import 'package:flutter/material.dart';
import 'styles.dart';

/// Reusable compact info card used for UV index, feels-like, humidity, visibility.
class WeatherCompactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  const WeatherCompactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 130,
      decoration: WeatherStyles.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(title, style: WeatherStyles.labelStyle),
            ],
          ),
          const Spacer(),
          Text(value, style: WeatherStyles.valueStyle),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: WeatherStyles.white(0.6), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
