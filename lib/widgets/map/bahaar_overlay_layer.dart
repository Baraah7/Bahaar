// lib/widgets/map/bahaar_overlay_layer.dart
// Renders three overlay types onto the existing FlutterMap:
//   1. Zone polygons  – northern/eastern/western, semi-transparent fills.
//   2. MPA circles    – red semi-transparent circles; tap → bottom sheet.
//   3. Spot markers   – colour-coded by confidence/MPA; tap → bottom sheet
//                       with a "Get Prediction" button.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/constants/fishing_spots_zones.dart';
import 'package:bahaar/constants/species_data.dart';
import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:bahaar/models/fishing_log/trip_model.dart';

// ---------------------------------------------------------------------------
// Public widget — drop it inside FlutterMap's children list.
// ---------------------------------------------------------------------------

class BahaarOverlayLayer extends StatelessWidget {
  /// Called when the user taps the "Get Prediction" button on a spot card.
  /// Receives the spot's [LatLng] and [speciesId] (first species of the spot).
  final void Function(LatLng latLng, String speciesId)? onGetPrediction;

  /// When true the MPA red polygons are rendered (Protected Zones toggle).
  final bool showMpaCircles;

  /// When true the fishing spot markers are rendered (Fishing Spots toggle).
  final bool showSpots;

  const BahaarOverlayLayer({
    super.key,
    this.onGetPrediction,
    this.showMpaCircles = true,
    this.showSpots = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showMpaCircles)
          _MpaCircleLayer(
            onMpaTapped: (mpa) => _showMpaSheet(context, mpa),
          ),
        if (showSpots)
          _SpotMarkerLayer(
            onSpotTapped: (spot) => _showSpotSheet(context, spot),
          ),
      ],
    );
  }

  static const _typeAr = {'Marine': 'بحرية', 'Wilderness': 'برية'};
  static const _typeEn = {'Marine': 'Marine', 'Wilderness': 'Wilderness'};

  // ── MPA bottom sheet ────────────────────────────────────────────────────────
  void _showMpaSheet(BuildContext context, Map<String, dynamic> mpa) {
    final l10n = MapLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? mpa['nameAr'] as String : (mpa['nameEn'] as String? ?? mpa['nameAr'] as String),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      if (!isAr && (mpa['nameAr'] as String?) != null)
                        Text(
                          mpa['nameAr'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
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
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.protectedAreaRestricted,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if ((mpa['year'] as String?) != null)
                _MpaInfoRow(Icons.calendar_today_outlined, l10n.declarationYearLabel(mpa['year'] as String)),
              if ((mpa['area_km2'] as num?) != null)
                _MpaInfoRow(Icons.straighten, l10n.areaLabel('${mpa['area_km2']}')),
              if ((mpa['type'] as String?) != null)
                _MpaInfoRow(Icons.category_outlined, (isAr ? _typeAr : _typeEn)[mpa['type']] ?? mpa['type'] as String),
              if ((mpa['authority'] as String?) != null)
                _MpaInfoRow(Icons.account_balance_outlined, mpa['authority'] as String),
              if ((mpa['description'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  mpa['description'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Spot bottom sheet ───────────────────────────────────────────────────────
  void _showSpotSheet(BuildContext context, Map<String, dynamic> spot) {
    final l10n = MapLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final isMpa = spot['mpa'] as bool;
    final speciesList = (spot['species'] as List).cast<String>();
    final firstSpecies = speciesList.isNotEmpty ? speciesList.first : 'hamour';
    final bottomTypeNames = isAr ? kBottomTypeNamesAr : kBottomTypeNamesEn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                    isAr ? spot['nameAr'] as String : (spot['nameEn'] as String? ?? spot['nameAr'] as String),
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
                    child: Text(
                      l10n.protectedLabel,
                      style: const TextStyle(
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
                  label: l10n.depthLabel('${spot['depth']}'),
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.terrain,
                  label: bottomTypeNames[spot['bottomType']] ?? spot['bottomType'] as String,
                ),
              ]),
              const SizedBox(height: 12),

              // Species chips
              Text(
                l10n.expectedSpecies,
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
                    orElse: () => {'nameAr': id, 'nameEn': id},
                  );
                  return Chip(
                    label: Text(isAr ? s['nameAr'] as String : s['nameEn'] as String),
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
                  label: Text(
                    l10n.getPrediction,
                    style: const TextStyle(fontSize: 16),
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

class _MpaInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MpaInfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// MPA polygon layer
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> _loadMpas() async {
  final raw = await rootBundle.loadString('assets/data/protected-areas.json');
  final list = jsonDecode(raw) as List;
  return list.cast<Map<String, dynamic>>();
}

class _MpaCircleLayer extends StatefulWidget {
  final void Function(Map<String, dynamic> mpa) onMpaTapped;
  const _MpaCircleLayer({required this.onMpaTapped});

  @override
  State<_MpaCircleLayer> createState() => _MpaCircleLayerState();
}

class _MpaCircleLayerState extends State<_MpaCircleLayer> {
  late final Future<List<Map<String, dynamic>>> _mpasFuture;

  @override
  void initState() {
    super.initState();
    _mpasFuture = _loadMpas();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _mpasFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final mpas = snapshot.data!;

        final polygons = mpas.map((mpa) {
          final pts = (mpa['polygon'] as List).map((p) {
            final pair = p as List;
            return LatLng((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
          }).toList();
          return Polygon(
            points: pts,
            color: Colors.red.withValues(alpha: 0.20),
            borderColor: Colors.red,
            borderStrokeWidth: 2.0,
          );
        }).toList();

        final markers = mpas.map((mpa) {
          final center = mpa['center'] as List;
          return Marker(
            point: LatLng(
              (center[0] as num).toDouble(),
              (center[1] as num).toDouble(),
            ),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () => widget.onMpaTapped(mpa),
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
          PolygonLayer(polygons: polygons),
          MarkerLayer(markers: markers),
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Catch marker layer — orange dots shown during an active trip
// ---------------------------------------------------------------------------

/// Renders logged catches from the current trip as orange markers.
/// Styled distinctly from the blue fishing-prediction spot markers.
class CatchMarkerLayer extends StatelessWidget {
  final List<CatchEntry> catches;
  const CatchMarkerLayer({super.key, required this.catches});

  void _showCatchInfo(BuildContext context, List<CatchEntry> group) {
    if (group.length == 1) {
      _showSingleCatch(context, group.first);
    } else {
      _showGroupSheet(context, group);
    }
  }

  void _showSingleCatch(BuildContext context, CatchEntry c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8F00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phishing, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.species,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (c.weightKg != null)
              _CatchInfoRow(Icons.scale_rounded, '${c.weightKg!.toStringAsFixed(1)} kg'),
            _CatchInfoRow(
              Icons.access_time_rounded,
              '${c.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${c.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
            ),
            if (c.location != null)
              _CatchInfoRow(
                Icons.location_on_rounded,
                '${c.latitude!.toStringAsFixed(4)}, ${c.longitude!.toStringAsFixed(4)}',
              ),
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _CatchInfoRow(Icons.notes_rounded, c.notes!),
            ],
          ],
        ),
      ),
    );
  }

  void _showGroupSheet(BuildContext context, List<CatchEntry> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.phishing, color: Color(0xFFFF8F00), size: 22),
                const SizedBox(width: 8),
                Text('${group.length} catches at this location',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: group.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = group[i];
                    final t = c.timestamp.toLocal();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phishing, color: Color(0xFFFF8F00)),
                      title: Text(c.species, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
                        '${c.weightKg != null ? '  •  ${c.weightKg!.toStringAsFixed(1)} kg' : ''}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final located = catches.where((c) => c.location != null).toList();
    if (located.isEmpty) return const SizedBox.shrink();

    // Group catches that share the same coordinate (exact match)
    final Map<String, List<CatchEntry>> groups = {};
    for (final c in located) {
      final key = '${c.latitude!.toStringAsFixed(6)},${c.longitude!.toStringAsFixed(6)}';
      groups.putIfAbsent(key, () => []).add(c);
    }

    final markers = groups.entries.map((e) {
      final group = e.value;
      final point = group.first.location!;
      final count = group.length;
      return Marker(
        point: point,
        width: count > 1 ? 36 : 28,
        height: count > 1 ? 36 : 28,
        child: GestureDetector(
          onTap: () => _showCatchInfo(context, group),
          child: count > 1 ? _CatchDotWithCount(count: count) : const _CatchDot(),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }
}

class _CatchInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CatchInfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _CatchDot extends StatelessWidget {
  const _CatchDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF8F00),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: const Icon(Icons.phishing, color: Colors.white, size: 12),
    );
  }
}

class _CatchDotWithCount extends StatelessWidget {
  final int count;
  const _CatchDotWithCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF8F00),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: const Icon(Icons.phishing, color: Colors.white, size: 14),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Spot marker layer — small blue dots (fishing prediction spots)
// ---------------------------------------------------------------------------

class _SpotMarkerLayer extends StatelessWidget {
  final void Function(Map<String, dynamic> spot) onSpotTapped;
  const _SpotMarkerLayer({required this.onSpotTapped});

  Color _spotColor(Map<String, dynamic> spot) {
    if (spot['mpa'] as bool? ?? false) return Colors.red.shade600;
    return (spot['confidence'] as String? ?? 'medium') == 'high'
        ? Colors.green.shade600
        : Colors.orange.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final markers = kConfirmedSpots.map((spot) {
      final color = _spotColor(spot);
      return Marker(
        point: LatLng(spot['lat'] as double, spot['lng'] as double),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => onSpotTapped(spot),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.phishing, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }
}
