import 'forecast_day_model.dart';

class ForecastModel {
  final List<ForecastDay> forecastDays;

  ForecastModel({
    required this.forecastDays,
  });

  // Getter to access first day easily
  ForecastDay get forecastDay => forecastDays.first;

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing ForecastModel with keys: ${json.keys.toList()}');

      if (json['forecastday'] == null) {
        throw Exception('Missing "forecastday" field in forecast');
      }

      var forecastList = json['forecastday'] as List;
      // print('Forecast list length: ${forecastList.length}');

      List<ForecastDay> forecastDays = [];
      for (int i = 0; i < forecastList.length; i++) {
        // print('Parsing forecast day $i...');
        forecastDays.add(ForecastDay.fromJson(forecastList[i] as Map<String, dynamic>));
      }

      // print('All forecast days parsed successfully');
      return ForecastModel(
        forecastDays: forecastDays,
      );
    } catch (e) {
      // print('ERROR in ForecastModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
