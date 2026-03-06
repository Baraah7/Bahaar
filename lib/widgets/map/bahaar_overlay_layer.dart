// lib/widgets/map/bahaar_overlay_layer.dart
// Renders three overlay types onto the existing FlutterMap:
//   1. Zone polygons  – northern/eastern/western, semi-transparent fills.
//   2. MPA circles    – red semi-transparent circles; tap → bottom sheet.
//   3. Spot markers   – colour-coded by confidence/MPA; tap → bottom sheet
//                       with a "Get Prediction" button.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/core/constants/zone_data.dart';
import 'package:Bahaar/core/constants/species_data.dart';

// ---------------------------------------------------------------------------
// Public widget — drop it inside FlutterMap's children list.
// ---------------------------------------------------------------------------

class BahaarOverlayLayer extends StatelessWidget {
  /// Called when the user taps "احصل على تنبؤ" on a spot card.
  /// Receives the spot's [LatLng] and [speciesId] (first species of the spot).
  final void Function(LatLng latLng, String speciesId)? onGetPrediction;

  /// When true the MPA red circles are rendered (controlled by the
  /// Protected Zones toggle, not the Fishing Spots toggle).
  final bool showMpaCircles;

  const BahaarOverlayLayer({
    super.key,
    this.onGetPrediction,
    this.showMpaCircles = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showMpaCircles)
          _MpaCircleLayer(
            onMpaTapped: (mpa) => _showMpaSheet(context, mpa),
          ),
        _SpotMarkerLayer(
          onSpotTapped: (spot) => _showSpotSheet(context, spot),
        ),
      ],
    );
  }

  // ── MPA bottom sheet ────────────────────────────────────────────────────────
  void _showMpaSheet(BuildContext context, Map<String, dynamic> mpa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.nature_people, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mpa['nameAr'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'منطقة محمية - الصيد مقيد',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نطاق المحمية: ${(mpa['radiusKm'] as double).toStringAsFixed(1)} كم',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Spot bottom sheet ───────────────────────────────────────────────────────
  void _showSpotSheet(BuildContext context, Map<String, dynamic> spot) {
    final isMpa = spot['mpa'] as bool;
    final speciesList = (spot['species'] as List).cast<String>();
    final firstSpecies = speciesList.isNotEmpty ? speciesList.first : 'hamour';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Icon(
                  Icons.location_pin,
                  color: isMpa ? Colors.red : Colors.green.shade700,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spot['nameAr'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isMpa)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'محمية',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),

              // Details row
              Row(children: [
                _InfoChip(
                  icon: Icons.water,
                  label: 'العمق: ${spot['depth']}م',
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.terrain,
                  label: kBottomTypeNamesAr[spot['bottomType']] ??
                      spot['bottomType'],
                ),
              ]),
              const SizedBox(height: 12),

              // Species chips
              Text(
                'الأسماك المتوقعة:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: speciesList.map((id) {
                  final s = kAllSpecies.firstWhere(
                    (e) => e['id'] == id,
                    orElse: () => {'nameAr': id},
                  );
                  return Chip(
                    label: Text(s['nameAr'] as String),
                    backgroundColor: const Color(0xFF0D4F54).withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF0D4F54),
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Prediction button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    final latLng = LatLng(
                      spot['lat'] as double,
                      spot['lng'] as double,
                    );
                    onGetPrediction?.call(latLng, firstSpecies);
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text(
                    'احصل على تنبؤ',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4F54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helper chip widget
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// MPA circle layer
// ---------------------------------------------------------------------------

class _MpaCircleLayer extends StatelessWidget {
  final void Function(Map<String, dynamic> mpa) onMpaTapped;
  const _MpaCircleLayer({required this.onMpaTapped});

  @override
  Widget build(BuildContext context) {
    final circles = kMPAs.map((mpa) {
      final center = mpa['center'] as List;
      return CircleMarker(
        point: LatLng(
          (center[0] as num).toDouble(),
          (center[1] as num).toDouble(),
        ),
        radius: (mpa['radiusKm'] as double) * 1000,
        useRadiusInMeter: true,
        color: Colors.red.withValues(alpha: 0.25),
        borderColor: Colors.red,
        borderStrokeWidth: 2.0,
      );
    }).toList();

    final markers = kMPAs.map((mpa) {
      final center = mpa['center'] as List;
      return Marker(
        point: LatLng(
          (center[0] as num).toDouble(),
          (center[1] as num).toDouble(),
        ),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => onMpaTapped(mpa),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.nature_people,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();

    return Stack(children: [
      CircleLayer(circles: circles),
      MarkerLayer(markers: markers),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Spot marker layer
// ---------------------------------------------------------------------------

class _SpotMarkerLayer extends StatelessWidget {
  final void Function(Map<String, dynamic> spot) onSpotTapped;
  const _SpotMarkerLayer({required this.onSpotTapped});

  Color _markerColor(Map<String, dynamic> spot) {
    if (spot['mpa'] == true) return Colors.red;
    if (spot['confidence'] == 'high') return Colors.green.shade600;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final markers = kConfirmedSpots.map((spot) {
      final color = _markerColor(spot);
      return Marker(
        point: LatLng(
          spot['lat'] as double,
          spot['lng'] as double,
        ),
        width: 44,
        height: 56,
        child: GestureDetector(
          onTap: () => onSpotTapped(spot),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.set_meal,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              // Small triangle pointer
              CustomPaint(
                size: const Size(10, 8),
                painter: _TrianglePainter(color),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }
}

// ---------------------------------------------------------------------------
// Triangle painter for marker pin
// ---------------------------------------------------------------------------

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
