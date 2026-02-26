import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/map/editable_map_feature.dart';

/// Service for parsing and managing GeoJSON data on the map
class GeoJsonLayerBuilder {
  final Map<String, dynamic> geoJsonData;

  GeoJsonLayerBuilder(this.geoJsonData);

  /// Create a new GeoJsonLayerBuilder that merges asset data with Firestore features.
  /// Firestore features are converted to GeoJSON format and appended to the asset features.
  factory GeoJsonLayerBuilder.withFirestoreFeatures(
    Map<String, dynamic> assetGeoJson,
    List<EditableMapFeature> firestoreFeatures,
  ) {
    final assetFeatures =
        List<dynamic>.from(assetGeoJson['features'] as List? ?? []);

    // Convert Firestore features to GeoJSON format and append
    for (final feature in firestoreFeatures) {
      assetFeatures.add(feature.toGeoJsonFeature());
    }

    return GeoJsonLayerBuilder({
      'type': 'FeatureCollection',
      'features': assetFeatures,
    });
  }

  /// Extract features by type from GeoJSON
  List<Map<String, dynamic>> getFeaturesByType(String type) {
    final features = geoJsonData['features'] as List;
    return features
        .where((f) => f['properties']['type'] == type)
        .map((f) => f as Map<String, dynamic>)
        .toList();
  }

  /// Build fishing spot markers from GeoJSON
  List<Marker> buildFishingSpotMarkers({bool isVisible = true}) {
    if (!isVisible) return [];

    final spots = getFeaturesByType('fishing_spot');
    return spots.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final name = feature['properties']['name'] as String?;

      return Marker(
        point: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()), // GeoJSON is [lng, lat]
        width: 30,
        height: 30,
        child: Tooltip(
          message: name ?? 'Fishing Spot',
          child: Icon(
            Icons.location_on,
            color: Colors.blue.withValues(alpha: 0.8),
            size: 25,
          ),
        ),
      );
    }).toList();
  }

  /// Build shipping lanes polylines from GeoJSON
  List<Polyline> buildShippingLanes({bool isVisible = true}) {
    if (!isVisible) return [];

    final lanes = getFeaturesByType('shipping_lane');
    final routes = getFeaturesByType('patrol_route');
    final allLines = [...lanes, ...routes];

    return allLines.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final type = feature['properties']['type'] as String;

      return Polyline(
        points: coords.map((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()); // GeoJSON is [lng, lat]
        }).toList(),
        strokeWidth: type == 'shipping_lane' ? 3.0 : 2.0,
        color: type == 'shipping_lane'
            ? Colors.red.withValues(alpha: 0.6)
            : Colors.orange.withValues(alpha: 0.6),
      );
    }).toList();
  }

  /// Build protected zone polygons from GeoJSON
  List<Polygon> buildProtectedZones({bool isVisible = true}) {
    if (!isVisible) return [];

    final polygons = <Polygon>[];
    final protected = getFeaturesByType('protected_zone');
    final reefs = getFeaturesByType('reef');

    for (final feature in [...protected, ...reefs]) {
      final coords = feature['geometry']['coordinates'][0] as List;
      final type = feature['properties']['type'] as String;

      polygons.add(Polygon(
        points: coords.map((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList(),
        color: type == 'protected_zone'
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.brown.withValues(alpha: 0.15),
        borderStrokeWidth: 2.0,
        borderColor: type == 'protected_zone'
            ? Colors.red.withValues(alpha: 0.6)
            : Colors.brown.withValues(alpha: 0.6),
      ));
    }

    return polygons;
  }

  /// Build fishing zone polygons from GeoJSON
  List<Polygon> buildFishingZones({bool isVisible = true}) {
    if (!isVisible) return [];

    final zones = getFeaturesByType('fishing_zone');
    final polygons = <Polygon>[];

    for (final feature in zones) {
      final coords = feature['geometry']['coordinates'][0] as List;

      polygons.add(Polygon(
        points: coords.map((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList(),
        color: Colors.green.withValues(alpha: 0.15),
        borderStrokeWidth: 2.0,
        borderColor: Colors.green.withValues(alpha: 0.6),
      ));
    }

    return polygons;
  }

  /// Build restricted area polygons from GeoJSON
  List<Polygon> buildRestrictedAreas({bool isVisible = true}) {
    if (!isVisible) return [];

    final areas = getFeaturesByType('restricted_area');
    final polygons = <Polygon>[];

    for (final feature in areas) {
      final coords = feature['geometry']['coordinates'][0] as List;

      polygons.add(Polygon(
        points: coords.map((coord) {
          return LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList(),
        color: Colors.red.withValues(alpha: 0.25),
        borderStrokeWidth: 3.0,
        borderColor: Colors.red.withValues(alpha: 0.9),
      ));
    }

    return polygons;
  }

  /// Build all zone polygons (protected + fishing + restricted zones)
  List<Polygon> buildAllZones({
    bool showProtected = true,
    bool showFishing = true,
    bool showRestricted = true,
  }) {
    return [
      ...buildProtectedZones(isVisible: showProtected),
      ...buildFishingZones(isVisible: showFishing),
      ...buildRestrictedAreas(isVisible: showRestricted),
    ];
  }

  /// Get feature count by type
  int getFeatureCount(String type) {
    return getFeaturesByType(type).length;
  }

  /// Get all feature types in the GeoJSON
  Set<String> getAllFeatureTypes() {
    final features = geoJsonData['features'] as List;
    return features
        .map((f) => f['properties']['type'] as String)
        .toSet();
  }
}

/// Widget for displaying GeoJSON features on the map
class GeoJsonMapLayers extends StatelessWidget {
  final GeoJsonLayerBuilder builder;
  final bool showProtectedZones;

  const GeoJsonMapLayers({
    super.key,
    required this.builder,
    this.showProtectedZones = true,
  });

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: builder.buildProtectedZones(isVisible: showProtectedZones),
    );
  }
}
