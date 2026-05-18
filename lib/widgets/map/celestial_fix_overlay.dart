import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/celestial%20navigation/celestial_fix_notifier.dart';
import 'package:bahaar/celestial%20navigation/confidence_engine.dart';

// 1 NM ≈ 1852 m; 1 degree latitude ≈ 111 319 m
const double _kMetresPerDeg = 111319.0;
const double _kMetresPerNm = 1852.0;

/// FlutterMap layers (CircleLayer + MarkerLayer) for the DS-1 celestial fix.
///
/// Drop inside FlutterMap.children. Reads from [CelestialFixNotifier.instance]
/// so it reacts whenever the DS-1 screen posts or clears a fix.
class CelestialFixLayer extends StatefulWidget {
  const CelestialFixLayer({super.key});

  @override
  State<CelestialFixLayer> createState() => _CelestialFixLayerState();
}

class _CelestialFixLayerState extends State<CelestialFixLayer> {
  @override
  void initState() {
    super.initState();
    CelestialFixNotifier.instance.addListener(_onFixChanged);
  }

  @override
  void dispose() {
    CelestialFixNotifier.instance.removeListener(_onFixChanged);
    super.dispose();
  }

  void _onFixChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final fix = CelestialFixNotifier.instance.fix;
    if (fix == null) return const SizedBox.shrink();

    final isLowConf = fix.decision == FixDecision.lowConfidenceWarning;
    final circleColor =
        isLowConf ? Colors.orange : const Color(0xFF0D47A1); // dark blue

    // Convert uncertainty NM → metres → degrees latitude for CircleLayer
    final uncertaintyMetres = fix.uncertaintyNm * _kMetresPerNm;
    final radiusDeg = uncertaintyMetres / _kMetresPerDeg;

    // Build a polygon approximation of the uncertainty circle (36 points)
    final circlePoints = List.generate(37, (i) {
      final angle = i * 10.0 * (3.14159265358979 / 180.0);
      return LatLng(
        fix.position.latitude + radiusDeg * _cos(angle),
        fix.position.longitude +
            radiusDeg / _cosLat(fix.position.latitude) * _sin(angle),
      );
    });

    return Stack(
      children: [
        // Uncertainty circle
        PolygonLayer(
          polygons: [
            Polygon(
              points: circlePoints,
              color: circleColor.withValues(alpha: 0.08),
              borderColor: circleColor.withValues(alpha: 0.6),
              borderStrokeWidth: isLowConf ? 1.5 : 2.0,
            ),
          ],
        ),
        // Fix marker
        MarkerLayer(
          markers: [
            Marker(
              point: fix.position,
              width: 44,
              height: 44,
              child: _FixMarker(fix: fix),
            ),
          ],
        ),
      ],
    );
  }

  static double _cos(double rad) => rad == 0 ? 1.0 : (1.0 - rad * rad / 2.0 + rad * rad * rad * rad / 24.0); // approx
  static double _sin(double rad) => rad - rad * rad * rad / 6.0; // approx
  static double _cosLat(double lat) {
    final r = lat * 3.14159265358979 / 180.0;
    return r == 0 ? 1.0 : (1.0 - r * r / 2.0 + r * r * r * r / 24.0);
  }
}

class _FixMarker extends StatelessWidget {
  final CelestialFix fix;
  const _FixMarker({required this.fix});

  @override
  Widget build(BuildContext context) {
    final isLow = fix.decision == FixDecision.lowConfidenceWarning;
    final bgColor = isLow ? Colors.orange : const Color(0xFF0D47A1);

    return Tooltip(
      message: 'DS-1 Fix  score ${fix.confidenceScore}/100\n'
          '±${fix.uncertaintyNm.toStringAsFixed(0)} NM  '
          '${fix.timestamp.hour.toString().padLeft(2, '0')}:'
          '${fix.timestamp.minute.toString().padLeft(2, '0')} UTC',
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.explore, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Positioned spoofing-alert banner to place in the map's Stack.
/// Shows when [CelestialFixNotifier.instance.spoofingAlert] is true.
class CelestialSpoofingAlert extends StatefulWidget {
  const CelestialSpoofingAlert({super.key});

  @override
  State<CelestialSpoofingAlert> createState() => _CelestialSpoofingAlertState();
}

class _CelestialSpoofingAlertState extends State<CelestialSpoofingAlert> {
  @override
  void initState() {
    super.initState();
    CelestialFixNotifier.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    CelestialFixNotifier.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!CelestialFixNotifier.instance.spoofingAlert) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 8,
      left: 60,
      right: 10,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'GPS SPOOFING ALERT — Celestial fix diverges > 2 NM',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => CelestialFixNotifier.instance.clearFix(),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
