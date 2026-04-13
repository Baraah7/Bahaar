class LocationModel {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String tzId;
  final int localtimeEpoch;
  final String localtime;

  LocationModel({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tzId,
    required this.localtimeEpoch,
    required this.localtime,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    try {
      // print('Parsing LocationModel with keys: ${json.keys.toList()}');

      if (json['name'] == null) throw Exception('Missing "name" field');
      if (json['region'] == null) throw Exception('Missing "region" field');
      if (json['country'] == null) throw Exception('Missing "country" field');
      if (json['lat'] == null) throw Exception('Missing "lat" field');
      if (json['lon'] == null) throw Exception('Missing "lon" field');
      if (json['tz_id'] == null) throw Exception('Missing "tz_id" field');
      if (json['localtime_epoch'] == null) throw Exception('Missing "localtime_epoch" field');
      if (json['localtime'] == null) throw Exception('Missing "localtime" field');

      return LocationModel(
        name: json['name'] as String,
        region: json['region'] as String,
        country: json['country'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        tzId: json['tz_id'] as String,
        localtimeEpoch: json['localtime_epoch'] as int,
        localtime: json['localtime'] as String,
      );
    } catch (e, stackTrace) {
      // print('ERROR in LocationModel.fromJson: $e');
      // print('Stack trace: $stackTrace');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
