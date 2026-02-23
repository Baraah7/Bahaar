import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/map/exclusion_zone_service.dart';

/// Map layer that renders oil/gas platform exclusion zones as red circles
/// with a platform icon at the center.
///
/// Each circle represents the mandatory 500m UNCLOS Article 60 safety buffer.
class ExclusionZoneLayer extends StatelessWidget {
  final ExclusionZoneService service;
  final bool isVisible;

  const ExclusionZoneLayer({
    super.key,
    required this.service,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || !service.isInitialized) return const SizedBox.shrink();

    final circles = service.zones.map((zone) {
      final color = zone.isGasInstallation
          ? Colors.orange.withValues(alpha: 0.25)
          : Colors.red.withValues(alpha: 0.20);
      final borderColor = zone.isGasInstallation
          ? Colors.orange.shade700
          : Colors.red.shade700;

      return CircleMarker(
        point: zone.center,
        radius: zone.bufferMeters,
        useRadiusInMeter: true,
        color: color,
        borderColor: borderColor,
        borderStrokeWidth: 2.0,
      );
    }).toList();

    final markers = service.zones.map((zone) {
      return Marker(
        point: zone.center,
        width: 36,
        height: 36,
        child: Tooltip(
          message: '${zone.name}\n${zone.operator}\n500m exclusion zone',
          child: Container(
            decoration: BoxDecoration(
              color: zone.isGasInstallation
                  ? Colors.orange.shade700
                  : Colors.red.shade800,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 4),
              ],
            ),
            child: Icon(
              zone.isGasInstallation ? Icons.local_fire_department : Icons.oil_barrel,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        CircleLayer(circles: circles),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

/// Alert banner shown when the user enters or approaches an exclusion zone.
class ExclusionZoneAlert extends StatelessWidget {
  final ExclusionZone zone;
  final double distanceMeters;
  final bool isViolation; // true = inside buffer, false = approaching
  final VoidCallback onDismiss;

  const ExclusionZoneAlert({
    super.key,
    required this.zone,
    required this.distanceMeters,
    required this.isViolation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isViolation ? Colors.red.shade800 : Colors.deepOrange;
    final icon = isViolation ? Icons.dangerous : Icons.warning_amber_rounded;
    final title = isViolation
        ? 'EXCLUSION ZONE VIOLATION'
        : 'Approaching Exclusion Zone';
    final distStr = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    final body = isViolation
        ? '${zone.name}\nYou are inside the 500m safety exclusion zone ($distStr from platform). Exit immediately.'
        : '${zone.name}\nApproaching oil/gas platform. Safety zone boundary in $distStr.';

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UNCLOS Article 60 — 500m mandatory safety buffer',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
