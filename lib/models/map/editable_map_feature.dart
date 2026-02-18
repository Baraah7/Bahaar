import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Types of map features that can be created/edited
enum MapFeatureType {
  fishingSpot,
  shippingLane,
  protectedZone,
  fishingZone,
  restrictedArea,
  reef,
  patrolRoute,
}

/// Geometry types for map features
enum GeometryType { point, lineString, polygon }

/// Extension to provide display info and geometry mapping for feature types
extension MapFeatureTypeExtension on MapFeatureType {
  String get displayName {
    switch (this) {
      case MapFeatureType.fishingSpot:
        return 'Fishing Spot';
      case MapFeatureType.shippingLane:
        return 'Shipping Lane';
      case MapFeatureType.protectedZone:
        return 'Protected Zone';
      case MapFeatureType.fishingZone:
        return 'Fishing Zone';
      case MapFeatureType.restrictedArea:
        return 'Restricted Area';
      case MapFeatureType.reef:
        return 'Reef';
      case MapFeatureType.patrolRoute:
        return 'Patrol Route';
    }
  }

  String get geoJsonType {
    switch (this) {
      case MapFeatureType.fishingSpot:
        return 'fishing_spot';
      case MapFeatureType.shippingLane:
        return 'shipping_lane';
      case MapFeatureType.protectedZone:
        return 'protected_zone';
      case MapFeatureType.fishingZone:
        return 'fishing_zone';
      case MapFeatureType.restrictedArea:
        return 'restricted_area';
      case MapFeatureType.reef:
        return 'reef';
      case MapFeatureType.patrolRoute:
        return 'patrol_route';
    }
  }

  GeometryType get geometryType {
    switch (this) {
      case MapFeatureType.fishingSpot:
        return GeometryType.point;
      case MapFeatureType.shippingLane:
      case MapFeatureType.patrolRoute:
        return GeometryType.lineString;
      case MapFeatureType.protectedZone:
      case MapFeatureType.fishingZone:
      case MapFeatureType.restrictedArea:
      case MapFeatureType.reef:
        return GeometryType.polygon;
    }
  }

  static MapFeatureType fromGeoJsonType(String type) {
    switch (type) {
      case 'fishing_spot':
        return MapFeatureType.fishingSpot;
      case 'shipping_lane':
        return MapFeatureType.shippingLane;
      case 'protected_zone':
        return MapFeatureType.protectedZone;
      case 'fishing_zone':
        return MapFeatureType.fishingZone;
      case 'restricted_area':
        return MapFeatureType.restrictedArea;
      case 'reef':
        return MapFeatureType.reef;
      case 'patrol_route':
        return MapFeatureType.patrolRoute;
      default:
        return MapFeatureType.fishingSpot;
    }
  }
}

/// Unified model representing any editable map feature
class EditableMapFeature {
  final String? id;
  final MapFeatureType featureType;
  final String name;
  final List<LatLng> coordinates;
  final Map<String, dynamic> properties;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool deleted;

  const EditableMapFeature({
    this.id,
    required this.featureType,
    required this.name,
    required this.coordinates,
    this.properties = const {},
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deleted = false,
  });

  GeometryType get geometryType => featureType.geometryType;

  EditableMapFeature copyWith({
    String? id,
    MapFeatureType? featureType,
    String? name,
    List<LatLng>? coordinates,
    Map<String, dynamic>? properties,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return EditableMapFeature(
      id: id ?? this.id,
      featureType: featureType ?? this.featureType,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      properties: properties ?? this.properties,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Create from a Firestore document snapshot
  factory EditableMapFeature.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final coordsList = (data['coordinates'] as List<dynamic>?) ?? [];
    final coordinates = coordsList.map((c) {
      final map = c as Map<String, dynamic>;
      return LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      );
    }).toList();

    return EditableMapFeature(
      id: doc.id,
      featureType: MapFeatureTypeExtension.fromGeoJsonType(
          data['type'] as String? ?? 'fishing_spot'),
      name: data['name'] as String? ?? '',
      coordinates: coordinates,
      properties:
          Map<String, dynamic>.from(data['properties'] as Map? ?? {}),
      createdBy: data['created_by'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      deleted: data['deleted'] as bool? ?? false,
    );
  }

  /// Create from a GeoJSON feature map (from asset file)
  factory EditableMapFeature.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final geoType = geometry['type'] as String? ?? 'Point';
    final rawCoords = geometry['coordinates'];

    final featureType = MapFeatureTypeExtension.fromGeoJsonType(
        props['type'] as String? ?? 'fishing_spot');

    List<LatLng> coordinates;
    if (geoType == 'Point') {
      final coord = rawCoords as List<dynamic>;
      coordinates = [
        LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble())
      ];
    } else if (geoType == 'LineString') {
      coordinates = (rawCoords as List<dynamic>).map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
            (coord[1] as num).toDouble(), (coord[0] as num).toDouble());
      }).toList();
    } else {
      // Polygon — first ring
      final ring = (rawCoords as List<dynamic>).first as List<dynamic>;
      coordinates = ring.map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
            (coord[1] as num).toDouble(), (coord[0] as num).toDouble());
      }).toList();
    }

    // Remove 'type' from properties since it's stored as featureType
    final cleanProps = Map<String, dynamic>.from(props)..remove('type');

    return EditableMapFeature(
      id: feature['id'] as String?,
      featureType: featureType,
      name: props['name'] as String? ?? '',
      coordinates: coordinates,
      properties: cleanProps,
    );
  }

  /// Convert to a Firestore-compatible map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'type': featureType.geoJsonType,
      'name': name,
      'geometry_type': geometryType.name,
      'coordinates': coordinates
          .map((c) => {'lat': c.latitude, 'lng': c.longitude})
          .toList(),
      'properties': properties,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'deleted': deleted,
    };
  }

  /// Convert back to GeoJSON feature format for rendering with GeoJsonLayerBuilder
  Map<String, dynamic> toGeoJsonFeature() {
    final geoType = geometryType;
    dynamic coords;

    if (geoType == GeometryType.point) {
      coords = [coordinates.first.longitude, coordinates.first.latitude];
    } else if (geoType == GeometryType.lineString) {
      coords = coordinates
          .map((c) => [c.longitude, c.latitude])
          .toList();
    } else {
      // Polygon — wrap in outer ring array
      coords = [
        coordinates.map((c) => [c.longitude, c.latitude]).toList()
      ];
    }

    final geoJsonGeomType = geoType == GeometryType.point
        ? 'Point'
        : geoType == GeometryType.lineString
            ? 'LineString'
            : 'Polygon';

    return {
      'type': 'Feature',
      'id': id ?? '',
      'properties': {
        'type': featureType.geoJsonType,
        'name': name,
        ...properties,
      },
      'geometry': {
        'type': geoJsonGeomType,
        'coordinates': coords,
      },
    };
  }
}
