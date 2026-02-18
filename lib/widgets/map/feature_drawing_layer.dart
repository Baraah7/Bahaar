import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/map/editable_map_feature.dart';
import 'package:Bahaar/models/map/feature_edit_state.dart';

/// Renders in-progress drawings and selection highlights on the map
/// during feature edit mode.
class FeatureDrawingLayer extends StatelessWidget {
  final FeatureEditState editState;

  const FeatureDrawingLayer({
    super.key,
    required this.editState,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Drawing preview polygon/polyline
        if (editState.isDrawing && editState.drawingVertices.length >= 2)
          _buildDrawingPreview(),

        // Vertex markers for drawing
        if (editState.isDrawing && editState.drawingVertices.isNotEmpty)
          MarkerLayer(markers: _buildVertexMarkers()),

        // Selection highlight for selected feature
        if (editState.selectedFeature != null && !editState.isDrawing)
          _buildSelectionHighlight(),

        // Move indicator
        if (editState.interaction == FeatureEditInteraction.moveFeature)
          MarkerLayer(markers: _buildMoveIndicator()),
      ],
    );
  }

  Widget _buildDrawingPreview() {
    final vertices = editState.drawingVertices;
    final isPolygon =
        editState.interaction == FeatureEditInteraction.addPolygon;

    if (isPolygon && vertices.length >= 3) {
      return PolygonLayer(
        polygons: [
          Polygon(
            points: vertices,
            color: Colors.green.withValues(alpha: 0.15),
            borderStrokeWidth: 2.0,
            borderColor: Colors.green.withValues(alpha: 0.8),
          ),
        ],
      );
    } else {
      return PolylineLayer(
        polylines: [
          Polyline(
            points: vertices,
            strokeWidth: 2.5,
            color: Colors.green.withValues(alpha: 0.8),
          ),
        ],
      );
    }
  }

  List<Marker> _buildVertexMarkers() {
    return editState.drawingVertices.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final isFirst = index == 0;

      return Marker(
        point: point,
        width: isFirst ? 20 : 16,
        height: isFirst ? 20 : 16,
        child: Container(
          decoration: BoxDecoration(
            color: isFirst ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.green,
              width: 2,
            ),
          ),
          child: isFirst
              ? const Icon(Icons.circle, size: 8, color: Colors.white)
              : null,
        ),
      );
    }).toList();
  }

  Widget _buildSelectionHighlight() {
    final feature = editState.selectedFeature!;
    final coords = feature.coordinates;

    switch (feature.geometryType) {
      case GeometryType.point:
        return MarkerLayer(
          markers: [
            Marker(
              point: coords.first,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case GeometryType.lineString:
        return PolylineLayer(
          polylines: [
            Polyline(
              points: coords,
              strokeWidth: 5.0,
              color: Colors.amber.withValues(alpha: 0.6),
            ),
          ],
        );

      case GeometryType.polygon:
        return PolygonLayer(
          polygons: [
            Polygon(
              points: coords,
              color: Colors.amber.withValues(alpha: 0.15),
              borderStrokeWidth: 3.0,
              borderColor: Colors.amber.withValues(alpha: 0.8),
            ),
          ],
        );
    }
  }

  List<Marker> _buildMoveIndicator() {
    if (editState.selectedFeature == null) return [];

    final feature = editState.selectedFeature!;
    LatLng center;

    if (feature.geometryType == GeometryType.point) {
      center = feature.coordinates.first;
    } else {
      // Compute centroid
      double sumLat = 0, sumLng = 0;
      for (final c in feature.coordinates) {
        sumLat += c.latitude;
        sumLng += c.longitude;
      }
      center = LatLng(
        sumLat / feature.coordinates.length,
        sumLng / feature.coordinates.length,
      );
    }

    return [
      Marker(
        point: center,
        width: 50,
        height: 50,
        child: const Icon(
          Icons.open_with,
          color: Colors.blue,
          size: 30,
        ),
      ),
    ];
  }
}
