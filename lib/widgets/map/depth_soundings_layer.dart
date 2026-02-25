import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// GEBCO bathymetric tile layer for depth soundings.
/// Uses the GEBCO public WMTS tile service — no API key required.
class DepthSoundingsLayer extends StatelessWidget {
  final double opacity;

  const DepthSoundingsLayer({super.key, this.opacity = 0.6});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: TileLayer(
        urlTemplate:
            'https://tiles.gebco.net/tiles/gebco_latest/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.bahaar.app',
        maxZoom: 14,
        minZoom: 4,
        errorTileCallback: (tile, error, stackTrace) {
          // Silently ignore tile load errors (offline or GEBCO unavailable)
        },
      ),
    );
  }
}
