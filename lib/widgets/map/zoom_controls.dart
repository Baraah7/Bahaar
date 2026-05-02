import 'package:bahaar/widgets/map/map_button_group.dart';
import 'package:bahaar/widgets/map/map_icon_button.dart';
import 'package:flutter/material.dart';

class MapZoomControls extends StatelessWidget {
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onMyLocation;
  final VoidCallback? onLogCatch;

  const MapZoomControls({
    super.key,
    this.onZoomIn,
    this.onZoomOut,
    this.onMyLocation,
    this.onLogCatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLogCatch != null) ...[
          MapButtonGroup(buttons: [
            MapIconButton(
              icon: Icons.phishing,
              tooltip: 'Log catch',
              onPressed: onLogCatch,
            ),
          ]),
          const SizedBox(height: 8),
        ],
        MapButtonGroup(buttons: [
          MapIconButton(icon: Icons.add, tooltip: 'Zoom in', onPressed: onZoomIn),
          MapIconButton(icon: Icons.remove, tooltip: 'Zoom out', onPressed: onZoomOut),
          MapIconButton(
              icon: Icons.my_location, tooltip: 'My location', onPressed: onMyLocation),
        ]),
      ],
    );
  }
}
