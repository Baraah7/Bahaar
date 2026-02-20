import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/utilities/map_constants.dart';
import 'package:Bahaar/services/map/map_layer_manager.dart';

/// Enhanced depth layer widget with multiple visualization options:
/// 1. Bathymetric (colored depth map)
/// 2. Nautical (OpenSeaMap navigation chart)
/// 3. Combined (both layers)
///
/// NOTE: This layer is purely a visual representation of water depth.
/// It is NOT the territorial water mask. The territorial mask is a separate
/// concept managed by [TerritorialMaskLayer].
class EnhancedDepthLayer extends StatelessWidget {
  final bool isVisible;
  final double opacity;
  final DepthVisualizationType visualizationType;

  const EnhancedDepthLayer({
    super.key,
    required this.isVisible,
    required this.opacity,
    required this.visualizationType,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    switch (visualizationType) {
      case DepthVisualizationType.bathymetric:
        return _BathymetricDepthLayer(opacity: opacity);
      case DepthVisualizationType.nautical:
        return _NauticalChartLayer(opacity: opacity);
      case DepthVisualizationType.combined:
        return Stack(
          children: [
            _BathymetricDepthLayer(opacity: opacity * 0.6),
            _NauticalChartLayer(opacity: opacity),
          ],
        );
    }
  }
}

/// Bathymetric depth visualization layer (colored depth map).
/// Shows actual water depth using colors — lighter blue = shallow, darker = deep.
/// Tiles come from EMODnet Bathymetry and cover the full area including outside
/// territorial waters. The territorial mask is a separate layer.
class _BathymetricDepthLayer extends StatelessWidget {
  final double opacity;

  const _BathymetricDepthLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: TileLayer(
        // GEBCO 2024 (General Bathymetric Chart of the Oceans) via NCEI/ArcGIS.
        // Global coverage including the Persian Gulf with actual depth colour
        // variation: light blue (0–10 m shallow) → dark navy/purple (deep).
        // Note: ArcGIS tile order is {z}/{y}/{x} (row before column), not {z}/{x}/{y}.
        urlTemplate:
            'https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/GEBCO_basemap_NCEI/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: MapConstants.userAgent,
        maxZoom: 17,
        minZoom: 2,
        tileProvider: NetworkTileProvider(),
        keepBuffer: 2,
      ),
    );
  }
}

/// Nautical chart layer with navigation symbols (OpenSeaMap).
class _NauticalChartLayer extends StatelessWidget {
  final double opacity;

  const _NauticalChartLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: TileLayer(
        urlTemplate: MapConstants.openSeaMapUrl,
        userAgentPackageName: MapConstants.userAgent,
        maxZoom: MapConstants.openSeaMapMaxZoom.toDouble(),
        minZoom: MapConstants.openSeaMapMinZoom.toDouble(),
        tileProvider: NetworkTileProvider(),
        keepBuffer: 2,
      ),
    );
  }
}

/// Legend widget showing depth color scale
class DepthLegend extends StatelessWidget {
  const DepthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Depth',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFFE6F3FF), '0–10 m', 'Very Shallow'),
          _buildLegendItem(const Color(0xFF99CCFF), '10–50 m', 'Shallow'),
          _buildLegendItem(const Color(0xFF4DA6FF), '50–200 m', 'Medium'),
          _buildLegendItem(const Color(0xFF0066CC), '200–1000 m', 'Deep'),
          _buildLegendItem(const Color(0xFF003D7A), '1000–3000 m', 'Very Deep'),
          _buildLegendItem(const Color(0xFF001F3F), '3000 m+', 'Abyssal'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String depth, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            depth,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
