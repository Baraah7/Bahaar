import 'package:latlong2/latlong.dart';

class PortPoint {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final List<String> facilities;

  const PortPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.facilities = const [],
  });
}
