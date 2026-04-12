import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Bahaar/utilities/map/map_constants.dart';
import 'package:Bahaar/services/map/map_layer_manager.dart';
import 'package:Bahaar/widgets/map/depth_soundings_layer.dart'
    show MbTilesDb, MbTileProvider;

/// Enhanced depth layer widget with multiple visualization options:
/// 1. Bathymetric (colored depth map from local GEBCO mbtiles)
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

/// Bathymetric depth visualization layer — reads from bundled gebco_gulf_clipped
/// MBTiles asset (offline). Covers the Arabian/Persian Gulf region.
class _BathymetricDepthLayer extends StatefulWidget {
  final double opacity;

  const _BathymetricDepthLayer({required this.opacity});

  @override
  State<_BathymetricDepthLayer> createState() => _BathymetricDepthLayerState();
}

class _BathymetricDepthLayerState extends State<_BathymetricDepthLayer> {
  Database? _db;

  @override
  void initState() {
    super.initState();
    MbTilesDb.get().then((db) {
      if (mounted) setState(() => _db = db);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_db == null) return const SizedBox.shrink();

    return Opacity(
      opacity: widget.opacity,
      child: TileLayer(
        urlTemplate: 'mbtiles://{z}/{x}/{y}',
        tileProvider: MbTileProvider(_db!),
        minZoom: 4,
        maxZoom: 18,
        maxNativeZoom: 12,
        errorTileCallback: (tile, error, stackTrace) {},
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
          _buildLegendItem(const Color(0xFFC8F0C8), '0 m', 'Land / Coast'),
          _buildLegendItem(const Color(0xFFB8E8F8), '0–10 m', 'Very Shallow'),
          _buildLegendItem(const Color(0xFF80D0F8), '10–50 m', 'Shallow'),
          _buildLegendItem(const Color(0xFF50C0F8), '50–100 m', 'Moderate'),
          _buildLegendItem(const Color(0xFF10B0F0), '100–300 m', 'Deep'),
          _buildLegendItem(const Color(0xFF0090D8), '300–700 m', 'Very Deep'),
          _buildLegendItem(const Color(0xFF0060C8), '700–2000 m', 'Abyssal'),
          _buildLegendItem(const Color(0xFF0030A0), '2000 m+', 'Ultra Deep'),
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
