import 'package:bahaar/widgets/map/map_button_group.dart';
import 'package:bahaar/widgets/map/map_icon_button.dart';
import 'package:flutter/material.dart';

class MapLeftToolbar extends StatelessWidget {
  final bool showLayerControls;
  final bool showDepthLegend;
  final bool hasRoute;
  final bool hasNavMode;
  final bool maskInitialized;
  final bool celestialFixActive;
  final VoidCallback onToggleLayers;
  final VoidCallback onToggleLegend;
  final VoidCallback onOpenCelestial;
  final VoidCallback onToggleNav;

  const MapLeftToolbar({
    super.key,
    required this.showLayerControls,
    required this.showDepthLegend,
    required this.hasRoute,
    required this.hasNavMode,
    required this.maskInitialized,
    required this.celestialFixActive,
    required this.onToggleLayers,
    required this.onToggleLegend,
    required this.onOpenCelestial,
    required this.onToggleNav,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      left: 12,
      child: Column(
        children: [
          MapButtonGroup(buttons: [
            MapIconButton(
              icon: showLayerControls ? Icons.layers : Icons.layers_outlined,
              tooltip: 'Layers',
              onPressed: onToggleLayers,
              isActive: showLayerControls,
            ),
            MapIconButton(
              icon: showDepthLegend
                  ? Icons.legend_toggle
                  : Icons.legend_toggle_outlined,
              tooltip: 'Depth legend',
              onPressed: onToggleLegend,
              isActive: showDepthLegend,
            ),
          ]),
          const SizedBox(height: 8),
          MapButtonGroup(buttons: [
            MapIconButton(
              icon: Icons.explore,
              tooltip: 'Celestial Navigation (DS-1)',
              onPressed: onOpenCelestial,
              isActive: celestialFixActive,
              activeColor: const Color(0xFF0D47A1),
            ),
          ]),
          const SizedBox(height: 8),
          MapButtonGroup(buttons: [
            MapIconButton(
              icon: hasRoute || hasNavMode
                  ? Icons.close
                  : Icons.directions_boat_outlined,
              tooltip: hasRoute
                  ? 'Clear route'
                  : hasNavMode
                      ? 'Cancel navigation'
                      : 'Navigate',
              onPressed: maskInitialized ? onToggleNav : null,
              isActive: hasRoute || hasNavMode,
              activeColor: Colors.orange,
            ),
          ]),
        ],
      ),
    );
  }
}
