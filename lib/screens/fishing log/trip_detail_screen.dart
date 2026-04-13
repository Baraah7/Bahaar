import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app_localizations.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/screens/fishing%20log/location_picker_screen.dart';
import 'package:bahaar/services/fishing%20log/trip_service.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen view of a single trip. Allows editing and deleting each catch.
class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  static Future<bool> open(BuildContext context, Trip trip) async {
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
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _catches = List.of(widget.trip.catches);
  }

  Future<void> _addCatch() async {
    final l10n = AppLocalizations.of(context)!;
    final trip = widget.trip;
    DateTime? catchTime;
    if (trip.endTime != null) {
      catchTime = await _pickCatchTime(trip.startTime, trip.endTime!, l10n);
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

  Future<DateTime?> _pickCatchTime(DateTime start, DateTime end, AppLocalizations l10n) async {
    final midMinutes = start.difference(end).inMinutes.abs() ~/ 2;
    final initialTime = TimeOfDay.fromDateTime(start.add(Duration(minutes: midMinutes)));

    if (!mounted) return null;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: l10n.pickCatchTime,
    );
    if (picked == null) return null;

    final candidate = DateTime(
      start.year, start.month, start.day,
      picked.hour, picked.minute,
    );
    if (candidate.isBefore(start)) return start;
    if (candidate.isAfter(end)) return end;
    return candidate;
  }

  String _fmt(DateTime dt, String locale) {
    final t = dt.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return arabicN('$h:$m', locale);
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteCatch),
        content: Text(l10n.removeCatchConfirm(entry.species)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final dateStr = DateFormat('EEE d MMM yyyy', locale == 'ar' ? 'ar' : 'en').format(widget.trip.startTime.toLocal());
    final startStr = _fmt(widget.trip.startTime, locale);
    final endStr = widget.trip.endTime != null
        ? _fmt(widget.trip.endTime!, locale)
        : l10n.ongoing;
    final totalKg = _catches.fold<double>(0, (s, c) => s + (c.weightKg ?? 0));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F9),
        appBar: AppBar(
          title: Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(_dirty),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addCatch,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(l10n.addCatch),
        ),
        body: Column(
          children: [
            // Trip summary header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  _StatPill(icon: Icons.play_arrow_rounded, label: l10n.tripStart, value: startStr),
                  const SizedBox(width: 12),
                  _StatPill(icon: Icons.stop_rounded, label: l10n.tripEnd, value: endStr),
                  const SizedBox(width: 12),
                  _StatPill(
                    icon: Icons.set_meal_rounded,
                    label: l10n.catchWord,
                    value: arabicN('${_catches.length}', locale),
                  ),
                  if (totalKg > 0) ...[
                    const SizedBox(width: 12),
                    _StatPill(
                      icon: Icons.scale_rounded,
                      label: l10n.totalWeight,
                      value: '${arabicN(totalKg.toStringAsFixed(1), locale)} ${l10n.kgUnit}',
                    ),
                  ],
                ],
              ),
            ),

            // Catches list
            Expanded(
              child: _catches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.set_meal_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noCatchesLogged,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _catches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CatchCard(
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

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Catch card ────────────────────────────────────────────────────────────────

class _CatchCard extends StatelessWidget {
  final CatchEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatchCard({required this.entry, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final timeStr = arabicN(DateFormat('HH:mm').format(entry.timestamp.toLocal()), locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.set_meal_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.species,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      if (entry.weightKg != null)
                        _InfoChip(
                          icon: Icons.scale_rounded,
                          label: '${arabicN(entry.weightKg!.toStringAsFixed(1), locale)} ${l10n.kgUnit}',
                        ),
                      _InfoChip(icon: Icons.access_time_rounded, label: timeStr),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes!,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.latitude.toStringAsFixed(4)}, ${entry.longitude.toStringAsFixed(4)}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppColors.accent, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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

  static const _quickSpeciesKeys = [
    'quickSpeciesHamour',
    'quickSpeciesSafi',
    'quickSpeciesSobaity',
    'quickSpeciesChanad',
    'quickSpeciesZubaidi',
    'quickSpeciesShrimp',
    'quickSpeciesCrab',
  ];

  static const _quickSpeciesValues = [
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
    final picked = await LocationPickerScreen.open(context, initial: current);
    if (picked != null && mounted) {
      setState(() {
        _latCtrl.text = picked.latitude.toStringAsFixed(6);
        _lonCtrl.text = picked.longitude.toStringAsFixed(6);
        _mapPinned = true;
      });
    }
  }

  String _localizedSpecies(AppLocalizations l10n, int index) {
    switch (_quickSpeciesKeys[index]) {
      case 'quickSpeciesHamour':   return l10n.quickSpeciesHamour;
      case 'quickSpeciesSafi':     return l10n.quickSpeciesSafi;
      case 'quickSpeciesSobaity':  return l10n.quickSpeciesSobaity;
      case 'quickSpeciesChanad':   return l10n.quickSpeciesChanad;
      case 'quickSpeciesZubaidi':  return l10n.quickSpeciesZubaidi;
      case 'quickSpeciesShrimp':   return l10n.quickSpeciesShrimp;
      case 'quickSpeciesCrab':     return l10n.quickSpeciesCrab;
      default:                     return _quickSpeciesValues[index];
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_CatchEditResult(
      species: _speciesCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      location: _parseLocation(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.entry == null ? l10n.addCatch : l10n.editCatch,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Quick species chips
              Wrap(
                spacing: 8, runSpacing: 6,
                children: List.generate(_quickSpeciesKeys.length, (i) {
                  final label = _localizedSpecies(l10n, i);
                  return ActionChip(
                    label: Text(label,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0D4F54))),
                    backgroundColor: const Color(0xFF0D4F54).withValues(alpha: 0.08),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    onPressed: () => setState(() => _speciesCtrl.text = label),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Species
              TextFormField(
                controller: _speciesCtrl,
                decoration: _dec(l10n.speciesName, Icons.set_meal_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '!' : null,
              ),
              const SizedBox(height: 12),

              // Weight
              TextFormField(
                controller: _weightCtrl,
                decoration: _dec('Weight (kg)', Icons.scale_rounded),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: _dec(l10n.notesOptional, Icons.notes_rounded),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Location row
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.grey.shade500, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Catch Location',
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickOnMap,
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, color: AppColors.accent, size: 14),
                        const SizedBox(width: 4),
                        Text(l10n.pinOnMap,
                            style: TextStyle(color: AppColors.accent, fontSize: 11)),
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
                      decoration: _dec(l10n.latitude, null),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -90 || d > 90) return '!';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lonCtrl,
                      decoration: _dec(l10n.longitude, null),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = double.tryParse(v.trim());
                        if (d == null || d < -180 || d > 180) return '!';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_mapPinned) ...[
                const SizedBox(height: 4),
                Text(l10n.locationPinned,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(widget.entry == null ? Icons.add : Icons.save_rounded),
                  label: Text(widget.entry == null ? l10n.addCatch : l10n.saveChanges),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.grey.shade400, size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 10),
    );
  }
}
