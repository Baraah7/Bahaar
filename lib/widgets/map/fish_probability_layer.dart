import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/services/fishRecognition/fish_probability_service.dart';
import 'package:bahaar/models/fish_recognition/fish_probability_model.dart';

/// Renders a fish-probability heatmap as pre-computed grid polygons.
/// Only visible at zoom < 12; no computation happens at build time.
class FishProbabilityLayer extends StatelessWidget {
  final FishProbabilityService service;
  final Set<FishSpecies> selectedSpecies;
  final double currentZoom;

  const FishProbabilityLayer({
    super.key,
    required this.service,
    required this.selectedSpecies,
    required this.currentZoom,
  });

  // Half-size of each cell polygon (0.15° / 2)
  static const double _halfRes = 0.075;

  @override
  Widget build(BuildContext context) {
    if (!service.isInitialized ||
        selectedSpecies.isEmpty ||
        currentZoom >= 12) {
      return const SizedBox.shrink();
    }

    final polygons = _buildHeatmapPolygons();
    if (polygons.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(polygons: polygons);
  }

  List<Polygon> _buildHeatmapPolygons() {
    final polygons = <Polygon>[];
    for (final species in selectedSpecies) {
      for (final cell in service.getCellsForSpecies(species)) {
        polygons.add(Polygon(
          points: [
            LatLng(cell.latitude - _halfRes, cell.longitude - _halfRes),
            LatLng(cell.latitude - _halfRes, cell.longitude + _halfRes),
            LatLng(cell.latitude + _halfRes, cell.longitude + _halfRes),
            LatLng(cell.latitude + _halfRes, cell.longitude - _halfRes),
          ],
          color: _cellColor(cell.level, species),
          borderStrokeWidth: 0,
          borderColor: Colors.transparent,
        ));
      }
    }
    return polygons;
  }

  /// Each species has its own colour family; level modulates opacity.
  Color _cellColor(FishProbabilityLevel level, FishSpecies species) {
    final opacity = switch (level) {
      FishProbabilityLevel.veryLow => 0.10,
      FishProbabilityLevel.low => 0.20,
      FishProbabilityLevel.moderate => 0.32,
      FishProbabilityLevel.high => 0.48,
      FishProbabilityLevel.veryHigh => 0.55,
    };
    return species.color.withValues(alpha: opacity);
  }
}
