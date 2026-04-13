import 'current_weather_model.dart';
import 'location_model.dart';
import 'forecast_model.dart';

class WeatherResponseModel {
  final LocationModel location;
  final CurrentWeatherModel currentWeather;
  final ForecastModel? forecast;

  // Getter to access currentWeather as 'current'
  CurrentWeatherModel get current => currentWeather;

  WeatherResponseModel({
    required this.location,
    required this.currentWeather,
    this.forecast,
  });

  factory WeatherResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('=== Parsing WeatherResponseModel ===');
      // print('JSON keys: ${json.keys.toList()}');

      // Parse location
      if (json['location'] == null) {
        throw Exception('Missing "location" field in API response');
      }
      // print('Parsing location...');
      final location = LocationModel.fromJson(json['location']);
      // print('Location parsed successfully: ${location.name}');

      // Parse current weather
      if (json['current'] == null) {
        throw Exception('Missing "current" field in API response');
      }
      // print('Parsing current weather...');
      final currentWeather = CurrentWeatherModel.fromJson(json['current']);
      // print('Current weather parsed successfully');

      // Parse forecast (optional)
      ForecastModel? forecast;
      if (json['forecast'] != null) {
        // print('Parsing forecast...');
        forecast = ForecastModel.fromJson(json['forecast']);
        // print('Forecast parsed successfully');
      } else {
        // print('No forecast data in response');
      }

      // print('=== WeatherResponseModel parsed successfully ===');
      return WeatherResponseModel(
        location: location,
        currentWeather: currentWeather,
        forecast: forecast,
      );
    } catch (e, stackTrace) {
      // print('ERROR in WeatherResponseModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
