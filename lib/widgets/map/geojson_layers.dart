import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoJsonLayerBuilder {
  final Map<String, dynamic> geoJsonData;

  GeoJsonLayerBuilder(this.geoJsonData);

  /// Extract features by type from GeoJSON
  List<Map<String, dynamic>> getFeaturesByType(String type) {
    final features = geoJsonData['features'] as List;
    return features
        .where((f) => f['properties']['type'] == type)
        .map((f) => f as Map<String, dynamic>)
        .toList();
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

  /// Build circle markers for protected zones (centroid of each polygon).
  /// [onTap] receives the feature's properties map when a marker is tapped.
  List<Marker> buildProtectedZoneMarkers({
    bool isVisible = true,
    void Function(Map<String, dynamic> properties)? onTap,
  }) {
    if (!isVisible) return [];

    final protected = getFeaturesByType('protected_zone');
    final markers = <Marker>[];

    for (final feature in protected) {
      final coords = feature['geometry']['coordinates'][0] as List;
      final props = feature['properties'] as Map<String, dynamic>;

      double latSum = 0, lngSum = 0;
      for (final c in coords) {
        lngSum += (c[0] as num).toDouble();
        latSum += (c[1] as num).toDouble();
      }
      final centroid = LatLng(latSum / coords.length, lngSum / coords.length);

      markers.add(Marker(
        point: centroid,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => onTap?.call(props),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.nature_people,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ));
    }

    return markers;
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

  void _showSheet(BuildContext context, Map<String, dynamic> props) {
    const typeAr = {'Marine': 'بحرية', 'Wilderness': 'برية'};
    final areaType = props['protected_area_type'] as String?;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.nature_people, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    props['arabic_name'] as String? ?? props['name'] as String? ?? '',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'منطقة محمية - الصيد مقيد',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (props['year_of_declaration'] != null)
                _InfoRow(Icons.calendar_today_outlined, 'سنة الإعلان: ${props['year_of_declaration']}'),
              if (props['area_km2'] != null)
                _InfoRow(Icons.straighten, 'المساحة: ${props['area_km2']} كم²'),
              if (areaType != null)
                _InfoRow(Icons.category_outlined, typeAr[areaType] ?? areaType),
              if ((props['authority_ar'] as String?) != null)
                _InfoRow(Icons.account_balance_outlined, props['authority_ar'] as String),
              if ((props['description_ar'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  props['description_ar'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PolygonLayer(
        polygons: builder.buildProtectedZones(isVisible: showProtectedZones),
      ),
      MarkerLayer(
        markers: builder.buildProtectedZoneMarkers(
          isVisible: showProtectedZones,
          onTap: (props) => _showSheet(context, props),
        ),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ),
      ]),
    );
  }
}
