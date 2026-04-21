import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:bahaar/models/map/nav_mode.dart';
import 'package:bahaar/models/map/port_point.dart';
import 'package:bahaar/widgets/map/step_chip.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class NavInstructionsPanel extends StatelessWidget {
  final NavMode navMode;
  final LatLng? seaOrigin;
  final LatLng? seaDestination;
  final LatLng? seaToLandOrigin;
  final PortPoint? selectedPort;
  final PortPoint? returnPort;
  final LatLng? customLandDestination;
  final LatLng? customLandOrigin;
  final MapLocalizations l10n;

  const NavInstructionsPanel({
    super.key,
    required this.navMode,
    required this.l10n,
    this.seaOrigin,
    this.seaDestination,
    this.seaToLandOrigin,
    this.selectedPort,
    this.returnPort,
    this.customLandDestination,
    this.customLandOrigin,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 90,
      left: 68,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  navMode == NavMode.seaToSea
                      ? l10n.seaToSea
                      : navMode == NavMode.seaToLand
                          ? l10n.returnSeaToLand
                          : l10n.landToSea,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              navMode == NavMode.seaToSea
                  ? seaOrigin == null
                      ? l10n.stepTapSeaDeparture
                      : seaDestination == null
                          ? l10n.stepTapSeaDestination
                          : l10n.calculatingRoute
                  : navMode == NavMode.seaToLand
                      ? seaToLandOrigin == null
                          ? l10n.stepTapSeaDeparture
                          : selectedPort == null
                              ? l10n.stepTapPortDock
                              : customLandDestination == null
                                  ? l10n.stepTapLandDestination
                                  : l10n.calculatingRoute
                      : selectedPort == null
                          ? l10n.stepTapPort
                          : seaDestination == null
                              ? l10n.stepTapSeaDestination
                              : l10n.calculatingRoute,
              style: const TextStyle(fontSize: 12),
            ),
            if (navMode == NavMode.landToSea && customLandOrigin != null) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.location_on, label: l10n.customOriginSet),
            ],
            if (seaOrigin != null && navMode == NavMode.seaToSea) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.radio_button_checked, label: l10n.departureSet),
            ],
            if (seaToLandOrigin != null && navMode == NavMode.seaToLand) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.radio_button_checked, label: l10n.seaDepartureSet),
            ],
            if (selectedPort != null) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.anchor, label: '${l10n.portLabel}: ${selectedPort!.name}'),
            ],
            if (returnPort != null && navMode == NavMode.seaToLand && selectedPort == null) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.history, label: '${l10n.lastPort}: ${returnPort!.name}'),
            ],
            if (customLandDestination != null) ...[
              const SizedBox(height: 6),
              StepChip(icon: Icons.home, label: l10n.landDestinationSet),
            ],
          ],
        ),
      ),
    );
  }
}
