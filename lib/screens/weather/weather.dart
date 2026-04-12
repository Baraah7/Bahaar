import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:Bahaar/utilities/weather/weather_api_service.dart';
import 'package:Bahaar/services/weather/world_tides_service.dart';
import 'package:Bahaar/models/weather/weather_response_model.dart';
import 'package:Bahaar/models/weather/tide_model.dart';
import 'package:Bahaar/widgets/weather/weather_list.dart';
import 'package:Bahaar/l10n/app_localizations.dart';
import 'package:Bahaar/core/constants/app_colors.dart';
import 'package:Bahaar/widgets/common/app_empty_state.dart';

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<Weather> {
  final weatherService = WeatherApiService();
  final tidesService = WorldTidesService();
  weather_response_model? weatherData;
  List<TideEntry> tides = [];
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String weatherQuery = "Manama";
      try {
        final loc = Location();
        final data = await loc.getLocation();
        if (data.latitude != null && data.longitude != null) {
          weatherQuery =
              "${data.latitude!.toStringAsFixed(4)},${data.longitude!.toStringAsFixed(4)}";
        }
      } catch (_) {}

      final results = await Future.wait([
        weatherService.getWeather(weatherQuery, true, 7, false),
        tidesService.getTides(),
      ]);

      setState(() {
        weatherData = results[0] as weather_response_model;
        tides = results[1] as List<TideEntry>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.accent, AppColors.primary],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : errorMessage != null
                ? AppEmptyState(
                    icon: Icons.cloud_off,
                    title: l10n.unableToLoadWeather,
                    message: errorMessage,
                    buttonText: l10n.tryAgain,
                    onButtonPressed: _loadAll,
                    iconColor: Colors.white70,
                  )
                : weatherData != null
                    ? RefreshIndicator(
                        onRefresh: _loadAll,
                        child: WeatherList(
                            weatherData: weatherData!, tides: tides, l10n: l10n),
                      )
                    : Center(
                        child: Text(
                          l10n.noDataAvailable,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
      ),
    );
  }
}
