import 'package:latlong2/latlong.dart';

class Marina {
  final String id;
  final String name;
  final LatLng location;
  final MarinaType type;
  final double? depth;
  final List<String> facilities;
  final String? osmId;
  final bool isValidated;
  final Map<String, dynamic>? metadata;

  const Marina({
    required this.id,
    required this.name,
    required this.location,
    this.type = MarinaType.port,
    this.depth,
    this.facilities = const [],
    this.osmId,
    this.isValidated = false,
    this.metadata,
  });

  factory Marina.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return Marina(
      id: json['id'] as String,
      name: properties['name'] as String,
      location: LatLng(coordinates[1], coordinates[0]),
      depth: properties['depth_m'] as double?,
      facilities: (properties['facilities'] as List?)?.cast<String>() ?? [],
      osmId: properties['osm_id'] as String?,
      isValidated: properties['validated'] as bool? ?? false,
      metadata: properties,
    );
  }

  factory Marina.fromOsmNode(Map<String, dynamic> osmData) {
    final tags = osmData['tags'] as Map<String, dynamic>;
    final lat = osmData['lat'] as double;
    final lon = osmData['lon'] as double;

    return Marina(
      id: 'osm_${osmData['id']}',
      name: tags['name'] as String? ?? 'Unnamed Marina',
      location: LatLng(lat, lon),
      depth: _parseDepth(tags),
      osmId: osmData['id'].toString(),
      isValidated: false,
      metadata: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Feature',
      'id': id,
      'properties': {
        'name': name,
        'type': type.value,
        if (depth != null) 'depth_m': depth,
        'facilities': facilities,
        if (osmId != null) 'osm_id': osmId,
        'validated': isValidated,
        if (metadata != null) ...metadata!,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude],
      },
    };
  }

  static double? _parseDepth(Map<String, dynamic> tags) {
    final depthStr = tags['depth'] as String?;
    if (depthStr == null) return null;
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(depthStr);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  String toString() {
    return 'Marina(id: $id, name: $name, type: ${type.displayName}, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Marina && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum MarinaType {
  port('port', 'Port');

  final String value;
  final String displayName;

  const MarinaType(this.value, this.displayName);
}
