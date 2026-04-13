import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:bahaar/services/map/outline_edit_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brush mode
// ─────────────────────────────────────────────────────────────────────────────

enum OutlineBrushMode { erase, restore }

// ─────────────────────────────────────────────────────────────────────────────
// Live edited outline layer
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the territorial boundary with live edits applied.
///
/// Listens to [OutlineEditService.watchEdits] via a stream subscription and
/// rebuilds whenever edits change.  Erase strokes hide nearby boundary cells;
/// restore strokes bring them back.
class EditedTerritorialOutlineLayer extends StatefulWidget {
  final NavigationMask navigationMask;
  final OutlineEditService editService;
  final bool isVisible;

  const EditedTerritorialOutlineLayer({
    super.key,
    required this.navigationMask,
    required this.editService,
    this.isVisible = true,
  });

  @override
  State<EditedTerritorialOutlineLayer> createState() =>
      _EditedTerritorialOutlineLayerState();
}

class _EditedTerritorialOutlineLayerState
    extends State<EditedTerritorialOutlineLayer> {
  StreamSubscription<List<OutlineEdit>>? _sub;
  List<OutlineEdit> _edits = [];

  @override
  void initState() {
    super.initState();
    _sub = widget.editService.watchEdits().listen((edits) {
      if (mounted) setState(() => _edits = edits);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || !widget.navigationMask.isInitialized) {
      return const SizedBox.shrink();
    }

    final boundaryCells = widget.navigationMask.getBoundaryWaterCells();
    final resolution = widget.navigationMask.resolution;
    final halfRes = resolution / 2;

    // Apply edits: for each boundary cell, decide whether to show it.
    // Erase wins over restore if the last edit touching the cell is an erase.
    final polygons = <Polygon>[];

    for (final center in boundaryCells) {
      bool show = true;

      // Walk edits in order (oldest first). Last applicable edit wins.
      for (final edit in _edits) {
        final latDiff = (center.latitude - edit.point.latitude).abs();
        final lonDiff = (center.longitude - edit.point.longitude).abs();
        if (latDiff <= edit.radiusDegrees && lonDiff <= edit.radiusDegrees) {
          show = !edit.isErase;
        }
      }

      if (!show) continue;

      polygons.add(Polygon(
        points: [
          LatLng(center.latitude - halfRes, center.longitude - halfRes),
          LatLng(center.latitude - halfRes, center.longitude + halfRes),
          LatLng(center.latitude + halfRes, center.longitude + halfRes),
          LatLng(center.latitude + halfRes, center.longitude - halfRes),
        ],
        color: Colors.transparent,
        borderStrokeWidth: 1.5,
        borderColor: const Color(0xFF00BFA5).withValues(alpha: 0.75),
      ));
    }

    return PolygonLayer(polygons: polygons);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor toolbar
// ─────────────────────────────────────────────────────────────────────────────

/// Floating toolbar shown while the admin is editing the territorial outline.
class TerritorialOutlineEditorToolbar extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onReset;
  final OutlineBrushMode brushMode;
  final double brushRadius; // in degrees
  final ValueChanged<OutlineBrushMode> onBrushModeChanged;
  final ValueChanged<double> onBrushRadiusChanged;

  const TerritorialOutlineEditorToolbar({
    super.key,
    required this.onClose,
    required this.onReset,
    required this.brushMode,
    required this.brushRadius,
    required this.onBrushModeChanged,
    required this.onBrushRadiusChanged,
  });

  @override
  State<TerritorialOutlineEditorToolbar> createState() =>
      _TerritorialOutlineEditorToolbarState();
}

class _TerritorialOutlineEditorToolbarState
    extends State<TerritorialOutlineEditorToolbar> {
  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Outline Edits'),
        content: const Text(
          'This will remove ALL edits to the territorial outline and restore the '
          'original boundary for all users. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.border_style, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Outline Editor',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),

          // Brush mode
          const Text('Brush Mode:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Erase',
                  icon: Icons.remove_circle_outline,
                  color: Colors.red,
                  isSelected:
                      widget.brushMode == OutlineBrushMode.erase,
                  onTap: () => widget
                      .onBrushModeChanged(OutlineBrushMode.erase),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'Restore',
                  icon: Icons.add_circle_outline,
                  color: Colors.teal,
                  isSelected:
                      widget.brushMode == OutlineBrushMode.restore,
                  onTap: () => widget
                      .onBrushModeChanged(OutlineBrushMode.restore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Brush radius
          const Text('Brush Radius:', style: TextStyle(fontSize: 12)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: widget.brushRadius,
                  min: 0.001,
                  max: 0.01,
                  divisions: 9,
                  activeColor: Colors.teal,
                  onChanged: widget.onBrushRadiusChanged,
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${(widget.brushRadius * 111000).round()}m',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(),

          // Reset + info
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmReset,
              icon: const Icon(Icons.restore, size: 16),
              label: const Text('Reset All Edits'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap or drag on the outline to edit it.',
                  style: TextStyle(fontSize: 10, color: Colors.teal),
                ),
                SizedBox(height: 2),
                Text(
                  'Changes are saved instantly and visible to all users.',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paint stroke preview layer
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a semi-transparent circle under the user's finger while they paint.
class OutlinePaintPreviewLayer extends StatelessWidget {
  final LatLng? center;
  final double radiusDegrees;
  final OutlineBrushMode mode;

  const OutlinePaintPreviewLayer({
    super.key,
    required this.center,
    required this.radiusDegrees,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (center == null) return const SizedBox.shrink();
    final color =
        mode == OutlineBrushMode.erase ? Colors.red : Colors.teal;
    return CircleLayer(
      circles: [
        CircleMarker(
          point: center!,
          radius: radiusDegrees * 111000, // approx metres
          useRadiusInMeter: true,
          color: color.withValues(alpha: 0.18),
          borderStrokeWidth: 1.5,
          borderColor: color.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
