import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/ais_model.dart';
import 'package:Bahaar/services/ais_service.dart';

/// Map layer that draws AIS vessels with:
/// - A directional arrow icon coloured by collision risk
/// - A 5-minute projected path line
class AisVesselLayer extends StatelessWidget {
  final AisService service;
  final bool isVisible;

  const AisVesselLayer({
    super.key,
    required this.service,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || !service.isInitialized) return const SizedBox.shrink();

    final riskMap = {
      for (final r in service.cpaAlerts) r.vessel.mmsi: r.risk,
    };

    // Projected path polylines
    final pathLines = <Polyline>[];
    // Vessel markers
    final markers = <Marker>[];

    for (final vessel in service.vessels) {
      final risk = riskMap[vessel.mmsi] ?? CollisionRisk.none;
      final color = _riskColor(risk);

      // 5-min projected path
      final pathPoints = service
          .getProjectedPath(vessel)
          .map((p) => LatLng(p.$1, p.$2))
          .toList();

      if (pathPoints.length >= 2) {
        pathLines.add(Polyline(
          points: pathPoints,
          color: color.withValues(alpha: 0.55),
          strokeWidth: 1.5,
          pattern: StrokePattern.dashed(segments: const [8, 6]),
        ));
      }

      // Vessel marker
      final displayHeading =
          vessel.headingDegrees ?? vessel.cogDegrees;

      markers.add(Marker(
        point: LatLng(vessel.latitude, vessel.longitude),
        width: 44,
        height: 44,
        child: Tooltip(
          message: _vesselTooltip(vessel, riskMap[vessel.mmsi]),
          child: Transform.rotate(
            angle: displayHeading * math.pi / 180,
            child: Icon(
              Icons.navigation, // arrow-up shape, rotated to heading
              color: color,
              size: 28,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ),
      ));
    }

    return Stack(
      children: [
        PolylineLayer(polylines: pathLines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Color _riskColor(CollisionRisk risk) {
    switch (risk) {
      case CollisionRisk.danger:
        return Colors.red;
      case CollisionRisk.caution:
        return Colors.orange;
      case CollisionRisk.none:
        return Colors.lightBlue;
    }
  }

  String _vesselTooltip(AisVessel vessel, CollisionRisk? risk) {
    final lines = [
      vessel.name.isNotEmpty ? vessel.name : 'MMSI ${vessel.mmsi}',
      '${vessel.vesselType.name.toUpperCase()}  |  ${vessel.sogKnots.toStringAsFixed(1)} kn  |  COG ${vessel.cogDegrees.toStringAsFixed(0)}°',
    ];
    if (risk != null && risk != CollisionRisk.none) {
      final cpa = service.cpaAlerts
          .firstWhere((r) => r.vessel.mmsi == vessel.mmsi);
      lines.add(
        'CPA ${cpa.dcpaNm.toStringAsFixed(2)} nm in ${cpa.tcpaMinutes.toStringAsFixed(1)} min',
      );
    }
    return lines.join('\n');
  }
}

/// Alert banner shown when a vessel poses a collision risk.
class AisCollisionAlert extends StatelessWidget {
  final CpaResult cpa;
  final VoidCallback onDismiss;

  const AisCollisionAlert({
    super.key,
    required this.cpa,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = cpa.risk == CollisionRisk.danger;
    final color = isDanger ? Colors.red.shade800 : Colors.deepOrange;
    final vesselName = cpa.vessel.name.isNotEmpty
        ? cpa.vessel.name
        : 'MMSI ${cpa.vessel.mmsi}';

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
              const Icon(Icons.directions_boat, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDanger ? 'COLLISION RISK' : 'Vessel Approaching',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$vesselName — CPA ${cpa.dcpaNm.toStringAsFixed(2)} nm '
                      'in ${cpa.tcpaMinutes.toStringAsFixed(1)} min',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '${cpa.vessel.sogKnots.toStringAsFixed(1)} kn  |  '
                      'COG ${cpa.vessel.cogDegrees.toStringAsFixed(0)}°',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
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
