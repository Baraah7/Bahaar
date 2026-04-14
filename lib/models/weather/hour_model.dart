class HourModel {
  final int timeEpoch;
  final String time;
  final double tempC;
  final double tempF;
  final int isDay;
  final String conditionText;
  final String conditionIcon;
  final double windMph;
  final double windKph;
  final int windDegree;
  final String windDir;
  final double pressureMb;
  final double pressureIn;
  final double precipMm;
  final double precipIn;
  final double snowCm;
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
  final bool willItRain;
  final int chanceOfRain;
  final bool willItSnow;
  final int chanceOfSnow;
  final double visKm;
  final double visMiles;
  final double gustMph;
  final double gustKph;
  final double uv;
  // Solar radiation fields - optional (may not be in all API responses)
  final double? shortRad;
  final double? diffRad;
  final double? dni;
  final double? gti;

  HourModel({
    required this.timeEpoch,
    required this.time,
    required this.tempC,
    required this.tempF,
    required this.isDay,
    required this.conditionText,
    required this.conditionIcon,
    required this.windMph,
    required this.windKph,
    required this.windDegree,
    required this.windDir,
    required this.pressureMb,
    required this.pressureIn,
    required this.precipMm,
    required this.precipIn,
    required this.snowCm,
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
    required this.willItRain,
    required this.chanceOfRain,
    required this.willItSnow,
    required this.chanceOfSnow,
    required this.visKm,
    required this.visMiles,
    required this.gustMph,
    required this.gustKph,
    required this.uv,
    this.shortRad,
    this.diffRad,
    this.dni,
    this.gti,
  });

  factory HourModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing HourModel for time: ${json['time']}');

      if (json['condition'] == null) throw Exception('Missing "condition" field in hour');

      return HourModel(
        timeEpoch: json['time_epoch'] as int,
        time: json['time'] is String ? json['time'] as String : json['time'].toString(),
        tempC: (json['temp_c'] as num).toDouble(),
        tempF: (json['temp_f'] as num).toDouble(),
        isDay: json['is_day'] as int,
        conditionText: json['condition']['text'] is String ? json['condition']['text'] as String : json['condition']['text'].toString(),
        conditionIcon: json['condition']['icon'] is String ? json['condition']['icon'] as String : json['condition']['icon'].toString(),
        windMph: (json['wind_mph'] as num).toDouble(),
        windKph: (json['wind_kph'] as num).toDouble(),
        windDegree: json['wind_degree'] as int,
        windDir: json['wind_dir'] is String ? json['wind_dir'] as String : json['wind_dir'].toString(),
        pressureMb: (json['pressure_mb'] as num).toDouble(),
        pressureIn: (json['pressure_in'] as num).toDouble(),
        precipMm: (json['precip_mm'] as num).toDouble(),
        precipIn: (json['precip_in'] as num).toDouble(),
        snowCm: (json['snow_cm'] as num).toDouble(),
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
        willItRain: (json['will_it_rain'] as int) == 1,
        chanceOfRain: (json['chance_of_rain'] as num).toInt(),
        willItSnow: (json['will_it_snow'] as int) == 1,
        chanceOfSnow: (json['chance_of_snow'] as num).toInt(),
        visKm: (json['vis_km'] as num).toDouble(),
        visMiles: (json['vis_miles'] as num).toDouble(),
        gustMph: (json['gust_mph'] as num).toDouble(),
        gustKph: (json['gust_kph'] as num).toDouble(),
        uv: (json['uv'] as num).toDouble(),
        // Solar radiation fields - optional, may be null in some API responses
        shortRad: json['short_rad'] != null ? (json['short_rad'] as num).toDouble() : null,
        diffRad: json['diff_rad'] != null ? (json['diff_rad'] as num).toDouble() : null,
        dni: json['dni'] != null ? (json['dni'] as num).toDouble() : null,
        gti: json['gti'] != null ? (json['gti'] as num).toDouble() : null,
      );
    } catch (e) {
      // print('ERROR in HourModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}
