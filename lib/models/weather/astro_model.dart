class AstroModel {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final String moonIllumination;
  final int isMoonUp;
  final int isSunUp;

  AstroModel({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
    required this.isMoonUp,
    required this.isSunUp,
  });

  factory AstroModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing AstroModel with keys: ${json.keys.toList()}');

      return AstroModel(
        sunrise: json['sunrise'] is String ? json['sunrise'] as String : json['sunrise'].toString(),
        sunset: json['sunset'] is String ? json['sunset'] as String : json['sunset'].toString(),
        moonrise: json['moonrise'] is String ? json['moonrise'] as String : json['moonrise'].toString(),
        moonset: json['moonset'] is String ? json['moonset'] as String : json['moonset'].toString(),
        moonPhase: json['moon_phase'] is String ? json['moon_phase'] as String : json['moon_phase'].toString(),
        moonIllumination: json['moon_illumination'] is String ? json['moon_illumination'] as String : json['moon_illumination'].toString(),
        isMoonUp: json['is_moon_up'] is int ? json['is_moon_up'] as int : (json['is_moon_up'] as num).toInt(),
        isSunUp: json['is_sun_up'] is int ? json['is_sun_up'] as int : (json['is_sun_up'] as num).toInt(),
      );
    } catch (e) {
      // print('ERROR in AstroModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
