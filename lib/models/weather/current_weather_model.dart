class CurrentWeatherModel {
  final int lastUpdatedEpoch;
  final String lastUpdated;
  final double tempC;
  final double tempF;
  final int isDay;
  final ConditionModel condition;
  final double windMph;
  final double windKph;
  final int windDegree;
  final String windDir;
  final double pressureMb;
  final double pressureIn;
  final int humidity;
  final int cloud;
  final double feelslikeC;
  final double feelslikeF;
  final double? windchillC;
  final double? windchillF;
  final double? heatindexC;
  final double? heatindexF;
  final double? dewpointC;
  final double? dewpointF;
  final double visKm;
  final double visMiles;
  final double uv;
  final double gustMph;
  final double gustKph;
  // Solar radiation fields - optional (may not be in all API responses)
  final double? shortRad;
  final double? diffRad;
  final double? dni;
  final double? gti;

  CurrentWeatherModel({
    required this.lastUpdatedEpoch,
    required this.lastUpdated,
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.condition,
    required this.windMph,
    required this.windKph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.humidity,
    required this.cloud,
    required this.feelslikeC,
    required this.feelslikeF,
    this.windchillC,
    this.windchillF,
    this.heatindexC,
    this.heatindexF,
    this.dewpointC,
    this.dewpointF,
    required this.visKm,
    required this.visMiles,
    required this.uv,
    required this.gustMph,
    required this.gustKph,
    this.shortRad,
    this.diffRad,
    this.dni,
    this.gti,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing CurrentWeatherModel with keys: ${json.keys.toList()}');

      // Check critical fields
      final missingFields = <String>[];
      if (json['last_updated_epoch'] == null) missingFields.add('last_updated_epoch');
      if (json['last_updated'] == null) missingFields.add('last_updated');
      if (json['temp_c'] == null) missingFields.add('temp_c');
      if (json['temp_f'] == null) missingFields.add('temp_f');
      if (json['is_day'] == null) missingFields.add('is_day');
      if (json['condition'] == null) missingFields.add('condition');

      if (missingFields.isNotEmpty) {
        throw Exception('Missing required fields in current weather: ${missingFields.join(", ")}');
      }

      // print('Parsing condition...');
      final condition = ConditionModel.fromJson(json['condition']);
      // print('Condition parsed: ${condition.text}');

      return CurrentWeatherModel(
        lastUpdatedEpoch: json['last_updated_epoch'] as int,
        lastUpdated: json['last_updated'] as String,
        tempC: (json['temp_c'] as num).toDouble(),
        tempF: (json['temp_f'] as num).toDouble(),
        isDay: json['is_day'] as int,
        condition: condition,
        windMph: (json['wind_mph'] as num).toDouble(),
        windKph: (json['wind_kph'] as num).toDouble(),
        windDegree: json['wind_degree'] as int,
        windDir: json['wind_dir'] as String,
        pressureMb: (json['pressure_mb'] as num).toDouble(),
        pressureIn: (json['pressure_in'] as num).toDouble(),
        humidity: (json['humidity'] as num).toInt(),
        cloud: (json['cloud'] as num).toInt(),
        feelslikeC: (json['feelslike_c'] as num).toDouble(),
        feelslikeF: (json['feelslike_f'] as num).toDouble(),
        windchillC: json['windchill_c'] != null ? (json['windchill_c'] as num).toDouble() : null,
        windchillF: json['windchill_f'] != null ? (json['windchill_f'] as num).toDouble() : null,
        heatindexC: json['heatindex_c'] != null ? (json['heatindex_c'] as num).toDouble() : null,
        heatindexF: json['heatindex_f'] != null ? (json['heatindex_f'] as num).toDouble() : null,
        dewpointC: json['dewpoint_c'] != null ? (json['dewpoint_c'] as num).toDouble() : null,
        dewpointF: json['dewpoint_f'] != null ? (json['dewpoint_f'] as num).toDouble() : null,
        visKm: (json['vis_km'] as num).toDouble(),
        visMiles: (json['vis_miles'] as num).toDouble(),
        uv: (json['uv'] as num).toDouble(),
        gustMph: (json['gust_mph'] as num).toDouble(),
        gustKph: (json['gust_kph'] as num).toDouble(),
        // Solar radiation fields - optional, may be null in some API responses
        shortRad: json['short_rad'] != null ? (json['short_rad'] as num).toDouble() : null,
        diffRad: json['diff_rad'] != null ? (json['diff_rad'] as num).toDouble() : null,
        dni: json['dni'] != null ? (json['dni'] as num).toDouble() : null,
        gti: json['gti'] != null ? (json['gti'] as num).toDouble() : null,
      );
    } catch (e) {
      // print('ERROR in CurrentWeatherModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}

class ConditionModel {
  final String text;
  final String icon;
  final int code;

  ConditionModel({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing ConditionModel with keys: ${json.keys.toList()}');

      if (json['text'] == null) throw Exception('Missing "text" field in condition');
      if (json['icon'] == null) throw Exception('Missing "icon" field in condition');
      if (json['code'] == null) throw Exception('Missing "code" field in condition');

      return ConditionModel(
        text: json['text'] as String,
        icon: json['icon'] as String,
        code: json['code'] as int,
      );
    } catch (e) {
      // print('ERROR in ConditionModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
