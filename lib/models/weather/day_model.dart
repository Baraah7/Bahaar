class DayModel {
  final double maxtempC;
  final double maxtempF;
  final double mintempC;
  final double mintempF;
  final double avgtempC;
  final double avgtempF;
  final double maxwindMph;
  final double maxwindKph;
  final double totalprecipMm;
  final double totalprecipIn;
  final double totalsnowCm;
  final double avgvisKm;
  final double avgvisMiles;
  final int avghumidity;
  final bool dailyWillItRain;
  final int dailyChanceOfRain;
  final bool dailyWillItSnow;
  final int dailyChanceOfSnow;
  final String conditionText;
  final String conditionIcon;

  DayModel({
    required this.maxtempC,
    required this.maxtempF,
    required this.mintempC,
    required this.mintempF,
    required this.avgtempC,
    required this.avgtempF,
    required this.maxwindMph,
    required this.maxwindKph,
    required this.totalprecipMm,
    required this.totalprecipIn,
    required this.totalsnowCm,
    required this.avgvisKm,
    required this.avgvisMiles,
    required this.avghumidity,
    required this.dailyWillItRain,
    required this.dailyChanceOfRain,
    required this.dailyWillItSnow,
    required this.dailyChanceOfSnow,
    required this.conditionText,
    required this.conditionIcon,
  });

  factory DayModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing DayModel with keys: ${json.keys.toList()}');

      if (json['condition'] == null) throw Exception('Missing "condition" field in day');

      return DayModel(
        maxtempC: (json['maxtemp_c'] as num).toDouble(),
        maxtempF: (json['maxtemp_f'] as num).toDouble(),
        mintempC: (json['mintemp_c'] as num).toDouble(),
        mintempF: (json['mintemp_f'] as num).toDouble(),
        avgtempC: (json['avgtemp_c'] as num).toDouble(),
        avgtempF: (json['avgtemp_f'] as num).toDouble(),
        maxwindMph: (json['maxwind_mph'] as num).toDouble(),
        maxwindKph: (json['maxwind_kph'] as num).toDouble(),
        totalprecipMm: (json['totalprecip_mm'] as num).toDouble(),
        totalprecipIn: (json['totalprecip_in'] as num).toDouble(),
        totalsnowCm: (json['totalsnow_cm'] as num).toDouble(),
        avgvisKm: (json['avgvis_km'] as num).toDouble(),
        avgvisMiles: (json['avgvis_miles'] as num).toDouble(),
        avghumidity: json['avghumidity'] is int ? json['avghumidity'] as int : (json['avghumidity'] as num).toInt(),
        dailyWillItRain: json['daily_will_it_rain'] == 1,
        dailyChanceOfRain: json['daily_chance_of_rain'] is int ? json['daily_chance_of_rain'] as int : (json['daily_chance_of_rain'] as num).toInt(),
        dailyWillItSnow: json['daily_will_it_snow'] == 1,
        dailyChanceOfSnow: json['daily_chance_of_snow'] is int ? json['daily_chance_of_snow'] as int : (json['daily_chance_of_snow'] as num).toInt(),
        conditionText: json['condition']['text'] is String ? json['condition']['text'] as String : json['condition']['text'].toString(),
        conditionIcon: json['condition']['icon'] is String ? json['condition']['icon'] as String : json['condition']['icon'].toString(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
