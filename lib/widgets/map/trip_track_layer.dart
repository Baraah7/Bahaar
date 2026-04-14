import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/navigation/dead_reckoning.dart';
import 'package:bahaar/navigation/trip_database.dart';
import 'package:bahaar/navigation/trip_recorder.dart';

/// Renders the live trip track, port markers, current-position marker,
/// and a DR uncertainty circle directly inside a [FlutterMap] widget tree.
///
/// Usage — add as a child layer inside FlutterMap:
///   FlutterMap(children: [ ..., const TripTrackLayer() ])
class TripTrackLayer extends StatefulWidget {
  const TripTrackLayer({super.key});

  @override
  State<TripTrackLayer> createState() => _TripTrackLayerState();
}

class _TripTrackLayerState extends State<TripTrackLayer> {
  final _recorder = TripRecorder.instance;

  @override
  void initState() {
    super.initState();
    _recorder.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _recorder.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_recorder.status == TripStatus.idle) return const SizedBox.shrink();

    final waypoints  = _recorder.waypoints;
    final currentPos = _recorder.currentPosition;
    final drFix      = _recorder.drFix;
    final depPort    = _recorder.departurePort;

    // ── Build track polyline ─────────────────────────────────────────────
    final trackPoints = waypoints
        .map((w) => LatLng(w.lat, w.lng))
        .toList();
    if (currentPos != null) trackPoints.add(currentPos.position);

    // ── Colour-coded segments by fix type ───────────────────────────────
    final gpsSegments       = <List<LatLng>>[];
    final celestialSegments = <List<LatLng>>[];
    final drSegments        = <List<LatLng>>[];

    if (waypoints.length >= 2) {
      List<LatLng> current = [LatLng(waypoints[0].lat, waypoints[0].lng)];
      FixType      currentType = waypoints[0].fixType;

      for (int i = 1; i < waypoints.length; i++) {
        final wp = waypoints[i];
        if (wp.fixType == currentType) {
          current.add(LatLng(wp.lat, wp.lng));
        } else {
          _pushSegment(current, currentType,
              gpsSegments, celestialSegments, drSegments);
          current     = [current.last, LatLng(wp.lat, wp.lng)];
          currentType = wp.fixType;
        }
      }
      _pushSegment(current, currentType,
          gpsSegments, celestialSegments, drSegments);
    }

    // ── Port markers ─────────────────────────────────────────────────────
    final portMarkers = <Marker>[];
    for (final route in _recorder.portRoutes) {
      portMarkers.add(_portMarker(route.port, isDeparture: route.isDeparture));
    }
    if (depPort != null &&
        !_recorder.portRoutes.any((r) => r.port.id == depPort.id)) {
      portMarkers.add(_portMarker(depPort, isDeparture: true));
    }

    // ── Current position marker ───────────────────────────────────────────
    final posMarkers = <Marker>[];
    if (currentPos != null) {
      posMarkers.add(_positionMarker(currentPos));
    }

    // ── DR uncertainty circle ─────────────────────────────────────────────
    final circles = <CircleMarker>[];
    if (drFix != null && currentPos != null) {
      final radiusM = drFix.uncertaintyNm * 1852.0;
      final color = drFix.reliability == DrReliability.exceeded
          ? Colors.red
          : Colors.orange;

      circles.add(CircleMarker(
        point:       currentPos.position,
        radius:      radiusM,
        useRadiusInMeter: true,
        color:       color.withValues(alpha: 0.10),
        borderColor: color.withValues(alpha: 0.5),
        borderStrokeWidth: 1.5,
      ));
    }

    return Stack(
      children: [
        // DR and celestial segments (dashed appearance via StrokePattern)
        if (drSegments.isNotEmpty)
          PolylineLayer(
            polylines: drSegments
                .map((pts) => Polyline(
                      points:       pts,
                      strokeWidth:  2.0,
                      color:        Colors.orange.withValues(alpha: 0.85),
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ))
                .toList(),
          ),
        if (celestialSegments.isNotEmpty)
          PolylineLayer(
            polylines: celestialSegments
                .map((pts) => Polyline(
                      points:       pts,
                      strokeWidth:  2.5,
                      color:        const Color(0xFF7C4DFF),
                      pattern: StrokePattern.dashed(segments: const [12, 4]),
                    ))
                .toList(),
          ),
        // GPS track (solid)
        if (gpsSegments.isNotEmpty)
          PolylineLayer(
            polylines: gpsSegments
                .map((pts) => Polyline(
                      points:      pts,
                      strokeWidth: 3.0,
                      color:       AppColors.accent,
                    ))
                .toList(),
          ),
        // DR uncertainty circle
        if (circles.isNotEmpty)
          CircleLayer(circles: circles),
        // Port markers
        if (portMarkers.isNotEmpty)
          MarkerLayer(markers: portMarkers),
        // Current position marker
        if (posMarkers.isNotEmpty)
          MarkerLayer(markers: posMarkers),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _pushSegment(
    List<LatLng> pts,
    FixType type,
    List<List<LatLng>> gps,
    List<List<LatLng>> celestial,
    List<List<LatLng>> dr,
  ) {
    if (pts.length < 2) return;
    switch (type) {
      case FixType.gps:          gps.add(List.of(pts));       break;
      case FixType.celestial:    celestial.add(List.of(pts)); break;
      case FixType.deadReckoning: dr.add(List.of(pts));       break;
    }
  }

  static Marker _portMarker(Port port, {required bool isDeparture}) {
    return Marker(
      point:  LatLng(port.lat, port.lng),
      width:  44,
      height: 52,
      child:  Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:  isDeparture ? AppColors.primary : AppColors.accent,
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.anchor, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              port.name,
              style: const TextStyle(color: Colors.white, fontSize: 9),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  static Marker _positionMarker(LivePosition pos) {
    final color = switch (pos.source) {
      FixType.gps          => AppColors.accent,
      FixType.celestial    => const Color(0xFF7C4DFF),
      FixType.deadReckoning => Colors.orange,
    };

    return Marker(
      point:  pos.position,
      width:  40,
      height: 40,
      child:  Container(
        decoration: BoxDecoration(
          color:  color.withValues(alpha: 0.15),
          shape:  BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          pos.source == FixType.deadReckoning
              ? Icons.navigation
              : Icons.my_location,
          color: color,
          size:  20,
        ),
      ),
    );
  }
}
