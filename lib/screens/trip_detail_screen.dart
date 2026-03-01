import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/fishing/trip_model.dart';
import 'package:Bahaar/services/fishing/trip_service.dart';
import 'package:Bahaar/screens/location_picker_screen.dart';

/// Full-screen view of a single trip. Allows editing and deleting each catch.
class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  static Future<bool> open(BuildContext context, Trip trip) async {
    // Returns true if any changes were made (so caller can reload)
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
    );
    return changed ?? false;
  }

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _service = TripService.instance;
  late List<CatchEntry> _catches;
  bool _dirty = false; // track whether caller needs to refresh

  @override
  void initState() {
    super.initState();
    _catches = List.of(widget.trip.catches);
  }

  Future<void> _addCatch() async {
    final trip = widget.trip;
    // For finished trips, ask user to pick a time within the trip window
    DateTime? catchTime;
    if (trip.endTime != null) {
      catchTime = await _pickCatchTime(trip.startTime, trip.endTime!);
      if (catchTime == null || !mounted) return;
    }

    final result = await showModalBottomSheet<_CatchEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatchEditSheet(entry: null),
    );
    if (result == null || !mounted) return;

    final loc = result.location ?? LatLng(trip.startLat ?? 26.2154, trip.startLon ?? 50.5832);
    final entry = await _service.logCatch(
      tripId: trip.id,
      species: result.species,
      location: loc,
      weightKg: result.weightKg,
      notes: result.notes,
      timestamp: catchTime,
    );

    setState(() {
      _catches.add(entry);
      _catches.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _dirty = true;
    });
  }

  /// Shows a time picker constrained between [start] and [end].
  /// Returns null if cancelled.
  Future<DateTime?> _pickCatchTime(DateTime start, DateTime end) async {
    // Default to midpoint of trip
    final midMinutes = start.difference(end).inMinutes.abs() ~/ 2;
    final initialTime = TimeOfDay.fromDateTime(
        start.add(Duration(minutes: midMinutes)));

    if (!mounted) return null;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Pick catch time (${_fmt(start)} – ${_fmt(end)})',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0E7490),
            surface: Color(0xFF0D2E31),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;

    // Compose a DateTime on the same day as the trip start
    final candidate = DateTime(
      start.year, start.month, start.day,
      picked.hour, picked.minute,
    );

    // Clamp to trip window
    if (candidate.isBefore(start)) return start;
    if (candidate.isAfter(end)) return end;
    return candidate;
  }

  String _fmt(DateTime dt) {
    final t = dt.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _editCatch(CatchEntry entry) async {
    final result = await showModalBottomSheet<_CatchEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatchEditSheet(entry: entry),
    );
    if (result == null || !mounted) return;

    final updated = CatchEntry(
      id: entry.id,
      tripId: entry.tripId,
      timestamp: entry.timestamp,
      species: result.species,
      weightKg: result.weightKg,
      latitude: result.location?.latitude ?? entry.latitude,
      longitude: result.location?.longitude ?? entry.longitude,
      notes: result.notes,
      imagePath: entry.imagePath,
    );

    await _service.updateCatch(updated);
    setState(() {
      final idx = _catches.indexWhere((c) => c.id == entry.id);
      if (idx != -1) _catches[idx] = updated;
      _dirty = true;
    });
  }

  Future<void> _deleteCatch(CatchEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2E31),
        title: const Text('Delete catch?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${entry.species}" from this trip?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await _service.deleteCatch(entry.id);
    setState(() {
      _catches.removeWhere((c) => c.id == entry.id);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE d MMM yyyy')
        .format(widget.trip.startTime.toLocal());
    final startStr = DateFormat('HH:mm')
        .format(widget.trip.startTime.toLocal());
    final endStr = widget.trip.endTime != null
        ? DateFormat('HH:mm').format(widget.trip.endTime!.toLocal())
        : 'Ongoing';
    final totalKg =
        _catches.fold<double>(0, (s, c) => s + (c.weightKg ?? 0));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        // nothing — _dirty is returned via Navigator.pop below
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A2025),
        appBar: AppBar(
          title: Text(dateStr,
              style: const TextStyle(fontSize: 16)),
          backgroundColor: const Color(0xFF0D4F54),
          foregroundColor: Colors.white,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_dirty),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCatch,
          backgroundColor: const Color(0xFF0E7490),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Catch',
              style: TextStyle(color: Colors.white)),
        ),
        body: Column(
          children: [
            // Trip summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              color: const Color(0xFF0D2E31),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _HeaderStat(
                      icon: Icons.play_arrow,
                      label: 'Start',
                      value: startStr),
                  _HeaderStat(
                      icon: Icons.stop,
                      label: 'End',
                      value: endStr),
                  _HeaderStat(
                      icon: Icons.set_meal,
                      label: 'Catches',
                      value: '${_catches.length}'),
                  if (totalKg > 0)
                    _HeaderStat(
                        icon: Icons.scale,
                        label: 'Total weight',
                        value: '${totalKg.toStringAsFixed(1)} kg'),
                ],
              ),
            ),

            // Catches list
            Expanded(
              child: _catches.isEmpty
                  ? const Center(
                      child: Text('No catches logged.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 15)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: _catches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _CatchCard(
                            entry: _catches[i],
                            onEdit: () => _editCatch(_catches[i]),
                            onDelete: () => _deleteCatch(_catches[i]),
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Catch card ────────────────────────────────────────────────────────────────

class _CatchCard extends StatelessWidget {
  final CatchEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatchCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm').format(entry.timestamp.toLocal());

    return Card(
      color: const Color(0xFF0D2E31),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Fish icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0E7490).withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.set_meal,
                  color: Color(0xFF4FC3F7), size: 20),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.species,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (entry.weightKg != null) ...[
                        const Icon(Icons.scale,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${entry.weightKg!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Icon(Icons.access_time,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        timeStr,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  if (entry.notes != null &&
                      entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.notes!,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white24, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.latitude.toStringAsFixed(4)}, '
                        '${entry.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.teal, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header stat ───────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeaderStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ── Catch edit bottom sheet ───────────────────────────────────────────────────

class _CatchEditResult {
  final String species;
  final double? weightKg;
  final String? notes;
  final LatLng? location;
  const _CatchEditResult(
      {required this.species, this.weightKg, this.notes, this.location});
}

class _CatchEditSheet extends StatefulWidget {
  /// Non-null when editing an existing catch; null when adding a new one.
  final CatchEntry? entry;
  const _CatchEditSheet({required this.entry});

  @override
  State<_CatchEditSheet> createState() => _CatchEditSheetState();
}

class _CatchEditSheetState extends State<_CatchEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _speciesCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;

  bool _mapPinned = false;

  static const _quickSpecies = [
    'Hamour', 'Safi', 'Sobaity', 'Chanad', 'Zubaidi', 'Shrimp', 'Crab',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _speciesCtrl = TextEditingController(text: e?.species ?? '');
    _weightCtrl  = TextEditingController(text: e?.weightKg?.toString() ?? '');
    _notesCtrl   = TextEditingController(text: e?.notes ?? '');
    _latCtrl     = TextEditingController(
        text: e != null ? e.latitude.toStringAsFixed(6) : '');
    _lonCtrl     = TextEditingController(
        text: e != null ? e.longitude.toStringAsFixed(6) : '');
  }

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  LatLng? _parseLocation() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat != null && lon != null) return LatLng(lat, lon);
    return null;
  }

  Future<void> _pickOnMap() async {
    final current = _parseLocation();
    final picked =
        await LocationPickerScreen.open(context, initial: current);
    if (picked != null && mounted) {
      setState(() {
        _latCtrl.text = picked.latitude.toStringAsFixed(6);
        _lonCtrl.text = picked.longitude.toStringAsFixed(6);
        _mapPinned = true;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_CatchEditResult(
      species: _speciesCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      location: _parseLocation(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2E31),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.entry == null ? 'Add Catch' : 'Edit Catch',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Quick species chips
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _quickSpecies.map((s) {
                  return ActionChip(
                    label: Text(s,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFF1A5C62),
                    side: const BorderSide(color: Colors.teal),
                    onPressed: () =>
                        setState(() => _speciesCtrl.text = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Species
              TextFormField(
                controller: _speciesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Species *', Icons.set_meal),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Enter species name'
                        : null,
              ),
              const SizedBox(height: 12),

              // Weight
              TextFormField(
                controller: _weightCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Weight (kg)', Icons.scale),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'))
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Notes (optional)', Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Location row
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  const Text('Catch Location',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickOnMap,
                    child: const Row(
                      children: [
                        Icon(Icons.map_outlined,
                            color: Colors.teal, size: 14),
                        SizedBox(width: 4),
                        Text('Pin on Map',
                            style: TextStyle(
                                color: Colors.teal, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('Latitude', null),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -90 || d > 90) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lonCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('Longitude', null),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -180 || d > 180) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_mapPinned) ...[
                const SizedBox(height: 4),
                const Text('Location pinned on map.',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(widget.entry == null ? Icons.add : Icons.save),
                  label: Text(widget.entry == null ? 'Add Catch' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7490),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white38, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0E7490)),
      ),
      errorStyle: const TextStyle(
          color: Colors.orangeAccent, fontSize: 10),
    );
  }
}
