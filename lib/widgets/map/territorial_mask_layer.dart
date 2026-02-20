import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/services/map/navigation_mask.dart';

/// Renders the territorial water mask as a visible boundary on the map.
///
/// The territorial mask is the authoritative definition of navigable water.
/// All other map layers (depth, GeoJSON zones, routes, markers) are expected
/// to remain inside this boundary.  When something falls outside, the app
/// shows a warning — this layer is purely the visual representation of the
/// boundary, not a clip path.
///
/// Visual design:
///  • A subtle teal border polygon traces the outer edge of the water territory.
///  • No fill is drawn so underlying depth colours remain visible.
class TerritorialMaskLayer extends StatefulWidget {
  final NavigationMask navigationMask;

  /// Whether to show the boundary at all.
  final bool isVisible;

  const TerritorialMaskLayer({
    super.key,
    required this.navigationMask,
    this.isVisible = true,
  });

  @override
  State<TerritorialMaskLayer> createState() => _TerritorialMaskLayerState();
}

class _TerritorialMaskLayerState extends State<TerritorialMaskLayer> {
  List<Polygon> _boundaryPolygons = [];

  @override
  void initState() {
    super.initState();
    // Always build on init — mask is guaranteed initialized before this widget
    // is added to the tree. Toggle is handled in build() via isVisible.
    _buildBoundary();
  }

  void _buildBoundary() {
    if (!widget.navigationMask.isInitialized) return;

    final cells = widget.navigationMask.getBoundaryWaterCells();
    final resolution = widget.navigationMask.resolution;
    final halfRes = resolution / 2;

    final polygons = cells.map((center) {
      return Polygon(
        points: [
          LatLng(center.latitude - halfRes, center.longitude - halfRes),
          LatLng(center.latitude - halfRes, center.longitude + halfRes),
          LatLng(center.latitude + halfRes, center.longitude + halfRes),
          LatLng(center.latitude + halfRes, center.longitude - halfRes),
        ],
        // No fill — only the teal border traces the territorial boundary
        color: Colors.transparent,
        borderStrokeWidth: 1.5,
        borderColor: const Color(0xFF00BFA5).withValues(alpha: 0.75), // teal
      );
    }).toList();

    // No setState needed — called synchronously from initState
    _boundaryPolygons = polygons;
  }

  @override
  Widget build(BuildContext context) {
    // isVisible toggles the layer on/off; polygons are always cached once built
    if (!widget.isVisible || _boundaryPolygons.isEmpty) {
      return const SizedBox.shrink();
    }

    return PolygonLayer(polygons: _boundaryPolygons);
  }
}

/// A small overlay warning badge that appears when a point (e.g. user location,
/// route destination) lies outside the territorial water mask.
class OutsideMaskWarning extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const OutsideMaskWarning({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
