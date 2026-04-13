import 'day_model.dart';
import 'astro_model.dart';
import 'hour_model.dart';

class ForecastDay {
  final String date;
  final DayModel day;
  final AstroModel astro;
  final List<HourModel> hour;

  ForecastDay({
    required this.date,
    required this.day,
    required this.astro,
    required this.hour,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing ForecastDay with keys: ${json.keys.toList()}');

      if (json['date'] == null) throw Exception('Missing "date" field');
      if (json['day'] == null) throw Exception('Missing "day" field');
      if (json['astro'] == null) throw Exception('Missing "astro" field');
      if (json['hour'] == null) throw Exception('Missing "hour" field');

      final dayData = DayModel.fromJson(json['day']);
      final astroData = AstroModel.fromJson(json['astro']);

      var hourList = json['hour'] as List;
      List<HourModel> hourModels = [];
      for (int i = 0; i < hourList.length; i++) {
        try {
          hourModels.add(HourModel.fromJson(hourList[i]));
        } catch (e) {
          rethrow;
        }
      }

      return ForecastDay(
        date: json['date'] is String ? json['date'] as String : json['date'].toString(),
        day: dayData,
        astro: astroData,
        hour: hourModels,
      );
    } catch (e) {
      // print('ERROR in ForecastDay.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
