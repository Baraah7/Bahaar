import 'package:flutter/material.dart';

class WeatherStyles {
  static const Color accent = Color(0xFF4FC3F7);
  static const Color orange = Color(0xFFFFB74D);
  static const Color coral = Color(0xFFFF8A65);

  static Color white(double alpha) => Colors.white.withValues(alpha: alpha);

  static BoxDecoration cardDecoration({double radius = 24}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [white(0.15), white(0.05)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: white(0.2)),
      );

  static TextStyle get labelStyle =>
      TextStyle(color: white(0.7), fontSize: 13, fontWeight: FontWeight.w500);

  static const TextStyle valueStyle = TextStyle(
      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400);

  static Widget sectionHeader(String title, Color accentColor) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  static Widget gradientDivider({bool vertical = false}) => Container(
        width: vertical ? 1 : null,
        height: vertical ? 50 : 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, white(0.2), Colors.transparent],
          ),
        ),
      );

  static Widget weatherIcon(String iconUrl, {double size = 32}) =>
      Image.network(
        'https:$iconUrl',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.cloud, color: white(0.7), size: size),
      );

  static Color uvColor(double uv) {
    if (uv <= 2) return const Color(0xFF81C784);
    if (uv <= 5) return orange;
    if (uv <= 7) return coral;
    if (uv <= 10) return const Color(0xFFE57373);
    return const Color(0xFFBA68C8);
  }
}
