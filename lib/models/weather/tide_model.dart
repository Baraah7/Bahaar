class TideEntry {
  final String time;
  final double heightMt;
  final String type; // "HIGH" or "LOW"

  TideEntry({required this.time, required this.heightMt, required this.type});

  factory TideEntry.fromJson(Map<String, dynamic> json) => TideEntry(
        time: json['tide_time'] as String,
        heightMt: double.tryParse(json['tide_height_mt'].toString()) ?? 0.0,
        type: (json['tide_type'] as String).toUpperCase(),
      );

  // WorldTides API v3 format: {"date": "2024-01-01T05:30+03:00", "height": 1.23, "type": "High"}
  factory TideEntry.fromWorldTidesJson(Map<String, dynamic> json) => TideEntry(
        time: json['date'] as String,
        heightMt: (json['height'] as num).toDouble(),
        type: (json['type'] as String).toUpperCase(),
      );

  // Stormglass API format: {"time": "2024-01-01T05:00:00+00:00", "height": 1.23, "type": "high"}
  factory TideEntry.fromStormglassJson(Map<String, dynamic> json) => TideEntry(
        time: json['time'] as String,
        heightMt: (json['height'] as num).toDouble(),
        type: (json['type'] as String).toUpperCase(),
      );

  bool get isHigh => type == 'HIGH';

  DateTime get dateTime => DateTime.parse(time);

  String get formattedTime {
    final dt = dateTime;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
