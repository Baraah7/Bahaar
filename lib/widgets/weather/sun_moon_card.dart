import 'package:flutter/material.dart';
import '../../models/weather/astro_model.dart';
import 'styles.dart';
import 'weather_l10n_helper.dart';

class WeatherSunMoonCard extends StatelessWidget {
  final AstroModel astro;
  final WeatherL10nHelper helper;

  const WeatherSunMoonCard(
      {super.key, required this.astro, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _CelestialInfo(
                icon: Icons.wb_sunny,
                color: WeatherStyles.orange,
                title: helper.l10n.sunrise,
                time: helper.formatTime(astro.sunrise),
              )),
              WeatherStyles.gradientDivider(vertical: true),
              Expanded(
                  child: _CelestialInfo(
                icon: Icons.wb_twilight,
                color: WeatherStyles.coral,
                title: helper.l10n.sunset,
                time: helper.formatTime(astro.sunset),
              )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: WeatherStyles.gradientDivider(),
          ),
          Row(
            children: [
              Icon(helper.moonIcon(astro.moonPhase),
                  color: WeatherStyles.white(0.9), size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helper.moonPhase(astro.moonPhase),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${helper.n(astro.moonIllumination)}${helper.l10n.illuminated}',
                      style: TextStyle(
                          color: WeatherStyles.white(0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MoonTime(
                      icon: Icons.arrow_upward,
                      time: helper.formatTime(astro.moonrise),
                      helper: helper),
                  const SizedBox(height: 4),
                  _MoonTime(
                      icon: Icons.arrow_downward,
                      time: helper.formatTime(astro.moonset),
                      helper: helper),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CelestialInfo extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _CelestialInfo(
      {required this.icon,
      required this.color,
      required this.title,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                color: WeatherStyles.white(0.6), fontSize: 13)),
        const SizedBox(height: 4),
        Text(time,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _MoonTime extends StatelessWidget {
  final IconData icon;
  final String time;
  final WeatherL10nHelper helper;

  const _MoonTime(
      {required this.icon, required this.time, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: WeatherStyles.white(0.5), size: 12),
        const SizedBox(width: 4),
        Text(time,
            style: TextStyle(
                color: WeatherStyles.white(0.7), fontSize: 13)),
      ],
    );
  }
}
