import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather/current_weather_model.dart';
import 'styles.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';

class WeatherWindCard extends StatelessWidget {
  final CurrentWeatherModel wind;
  final WeatherLocalizations l10n;

  const WeatherWindCard(
      {super.key, required this.wind, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherStyles.cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compassSize = (constraints.maxWidth * 0.27).clamp(75.0, 100.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: compassSize,
                height: compassSize,
                child: CustomPaint(
                    painter: CompassPainter(wind.windDegree.toDouble())),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.air,
                            color: WeatherStyles.white(0.7), size: 14),
                        const SizedBox(width: 6),
                        Text(l10n.wind,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.n(wind.windKph.round()),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              height: 1),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(l10n.kmh,
                              style: TextStyle(
                                  color: WeatherStyles.white(0.7),
                                  fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: WeatherStyles.accent
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(wind.windDir,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: WeatherStyles.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.waves,
                            color: WeatherStyles.white(0.5), size: 13),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${l10n.weatherGusts} ${l10n.n(wind.gustKph.round())} ${l10n.kmh}',
                            style: TextStyle(
                                color: WeatherStyles.white(0.6),
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double windDegree;
  const CompassPainter(this.windDegree);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = WeatherStyles.white(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Decorative dots
    final dotPaint = Paint()
      ..color = WeatherStyles.white(0.4)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      canvas.drawCircle(
        Offset(center.dx + (radius - 8) * math.cos(angle),
            center.dy + (radius - 8) * math.sin(angle)),
        i % 2 == 0 ? 3.0 : 2.0,
        dotPaint,
      );
    }

    // Direction arrow
    final angle = (windDegree - 90) * math.pi / 180;
    final arrowLength = radius - 16;
    final path = Path()
      ..moveTo(center.dx + arrowLength * math.cos(angle),
          center.dy + arrowLength * math.sin(angle))
      ..lineTo(
          center.dx + 10 * math.cos(angle + math.pi - 0.5),
          center.dy + 10 * math.sin(angle + math.pi - 0.5))
      ..lineTo(
          center.dx + 10 * math.cos(angle + math.pi + 0.5),
          center.dy + 10 * math.sin(angle + math.pi + 0.5))
      ..close();
    canvas.drawPath(path, Paint()..color = WeatherStyles.accent);

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // N indicator
    final textPainter = TextPainter(
      text: const TextSpan(
          text: 'N',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
        canvas, Offset(center.dx - textPainter.width / 2, 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
