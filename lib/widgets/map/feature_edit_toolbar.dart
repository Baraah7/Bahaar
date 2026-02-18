import 'package:flutter/material.dart';
import 'package:Bahaar/models/map/editable_map_feature.dart';
import 'package:Bahaar/models/map/feature_edit_state.dart';

/// Floating toolbar for feature editing controls.
/// Follows the same visual pattern as AdminEditToolbar.
class FeatureEditToolbar extends StatelessWidget {
  final FeatureEditState editState;
  final VoidCallback onClose;
  final ValueChanged<MapFeatureType> onStartAdd;
  final VoidCallback onStartSelect;
  final VoidCallback onConfirmDrawing;
  final VoidCallback onCancelDrawing;
  final VoidCallback onUndoVertex;
  final VoidCallback onMoveFeature;
  final VoidCallback onDeleteFeature;

  const FeatureEditToolbar({
    super.key,
    required this.editState,
    required this.onClose,
    required this.onStartAdd,
    required this.onStartSelect,
    required this.onConfirmDrawing,
    required this.onCancelDrawing,
    required this.onUndoVertex,
    required this.onMoveFeature,
    required this.onDeleteFeature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            _buildModeSelector(),
            const SizedBox(height: 8),
            if (_isAddMode) ...[
              _buildFeatureTypeSelector(),
              const SizedBox(height: 8),
            ],
            if (editState.isDrawing) ...[
              _buildDrawingControls(),
              const SizedBox(height: 8),
            ],
            if (editState.selectedFeature != null &&
                !editState.isDrawing) ...[
              _buildSelectedFeaturePanel(),
              const SizedBox(height: 8),
            ],
            const Divider(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  bool get _isAddMode =>
      editState.interaction == FeatureEditInteraction.addPoint ||
      editState.interaction == FeatureEditInteraction.addPolygon ||
      editState.interaction == FeatureEditInteraction.addPolyline;

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.map, color: Colors.purple, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Feature Edit Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Add',
                icon: Icons.add_location_alt,
                color: Colors.green,
                isSelected: _isAddMode,
                onTap: () {
                  // Default to fishing spot when entering add mode
                  onStartAdd(editState.selectedFeatureType ??
                      MapFeatureType.fishingSpot);
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ModeButton(
                label: 'Select',
                icon: Icons.touch_app,
                color: Colors.blue,
                isSelected:
                    editState.interaction == FeatureEditInteraction.select,
                onTap: onStartSelect,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Feature Type:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MapFeatureType>(
              value: editState.selectedFeatureType ?? MapFeatureType.fishingSpot,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: MapFeatureType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_iconForType(type), size: 16,
                          color: _colorForType(type)),
                      const SizedBox(width: 6),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) onStartAdd(type);
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _geometryHint(editState.selectedFeatureType),
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDrawingControls() {
    final vertexCount = editState.drawingVertices.length;
    final isPolygon =
        editState.interaction == FeatureEditInteraction.addPolygon;
    final minVertices = isPolygon ? 3 : 2;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drawing: $vertexCount ${vertexCount == 1 ? 'vertex' : 'vertices'}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (vertexCount < minVertices)
            Text(
              'Need at least $minVertices vertices',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      vertexCount > 0 ? onUndoVertex : null,
                  icon: const Icon(Icons.undo, size: 14),
                  label: const Text('Undo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      vertexCount >= minVertices ? onConfirmDrawing : null,
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancelDrawing,
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 11, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFeaturePanel() {
    final feature = editState.selectedFeature!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForType(feature.featureType), size: 16,
                  color: _colorForType(feature.featureType)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  feature.name.isNotEmpty
                      ? feature.name
                      : feature.featureType.displayName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            feature.featureType.displayName,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMoveFeature,
                  icon: const Icon(Icons.open_with, size: 14),
                  label: const Text('Move'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeleteFeature,
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _instructionText(),
            style: const TextStyle(fontSize: 10, color: Colors.purple),
          ),
          const SizedBox(height: 2),
          const Text(
            'Features are saved to Firestore',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _instructionText() {
    switch (editState.interaction) {
      case FeatureEditInteraction.addPoint:
        return 'Tap on the map to place a ${editState.selectedFeatureType?.displayName ?? "feature"}';
      case FeatureEditInteraction.addPolygon:
        return 'Tap vertices to draw a polygon, then tap Done';
      case FeatureEditInteraction.addPolyline:
        return 'Tap points to draw a line, then tap Done';
      case FeatureEditInteraction.select:
        return 'Tap a feature on the map to select it';
      case FeatureEditInteraction.moveFeature:
        return 'Tap the new location for the feature';
      case FeatureEditInteraction.browse:
        return 'Choose a mode above to start editing';
    }
  }

  String _geometryHint(MapFeatureType? type) {
    if (type == null) return '';
    switch (type.geometryType) {
      case GeometryType.point:
        return 'Tap to place a point marker';
      case GeometryType.lineString:
        return 'Tap multiple points to draw a line';
      case GeometryType.polygon:
        return 'Tap vertices to draw an area';
    }
  }

  IconData _iconForType(MapFeatureType type) {
    switch (type) {
      case MapFeatureType.fishingSpot:
        return Icons.location_on;
      case MapFeatureType.shippingLane:
        return Icons.route;
      case MapFeatureType.protectedZone:
        return Icons.shield;
      case MapFeatureType.fishingZone:
        return Icons.agriculture;
      case MapFeatureType.restrictedArea:
        return Icons.block;
      case MapFeatureType.reef:
        return Icons.water;
      case MapFeatureType.patrolRoute:
        return Icons.security;
    }
  }

  Color _colorForType(MapFeatureType type) {
    switch (type) {
      case MapFeatureType.fishingSpot:
        return Colors.blue;
      case MapFeatureType.shippingLane:
        return Colors.red;
      case MapFeatureType.protectedZone:
        return Colors.red;
      case MapFeatureType.fishingZone:
        return Colors.green;
      case MapFeatureType.restrictedArea:
        return Colors.red;
      case MapFeatureType.reef:
        return Colors.brown;
      case MapFeatureType.patrolRoute:
        return Colors.orange;
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
