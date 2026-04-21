import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/fishing_log/fishing_log_localizations.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/screens/fishing%20log/location_picker_screen.dart';
import 'package:bahaar/services/fishing%20log/trip_service.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

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
    final l10n = FishingLogLocalizations.of(context);
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

    final loc = result.location ??
        LatLng(trip.startLat ?? 26.2154, trip.startLon ?? 50.5832);
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

  Future<DateTime?> _pickCatchTime(
      DateTime start, DateTime end, FishingLogLocalizations l10n) async {
    final midMinutes = start.difference(end).inMinutes.abs() ~/ 2;
    final initialTime =
        TimeOfDay.fromDateTime(start.add(Duration(minutes: midMinutes)));
    if (!mounted) return null;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: l10n.pickCatchTime,
    );
    if (picked == null) return null;
    final candidate = DateTime(
        start.year, start.month, start.day, picked.hour, picked.minute);
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
    final l10n = FishingLogLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteCatch,
            style: const TextStyle(color: AppColors.brown, fontWeight: FontWeight.w700)),
        content: Text(l10n.removeCatchConfirm(entry.species), style: const TextStyle(color: AppColors.brown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
    final l10n = FishingLogLocalizations.of(context);
    final locale = l10n.localeName;
    final dateStr = DateFormat(
            'EEE d MMM yyyy', locale == 'ar' ? 'ar' : 'en')
        .format(widget.trip.startTime.toLocal());
    final startStr = _fmt(widget.trip.startTime, locale);
    final endStr = widget.trip.endTime != null
        ? _fmt(widget.trip.endTime!, locale)
        : l10n.ongoing;
    final totalKg =
        _catches.fold<double>(0, (s, c) => s + (c.weightKg ?? 0));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: Column(
          children: [
            _TripHeader(
              dateStr: dateStr,
              startStr: startStr,
              endStr: endStr,
              catchCount: _catches.length,
              totalKg: totalKg,
              l10n: l10n,
              locale: locale,
              onBack: () => Navigator.of(context).pop(_dirty),
            ),
            Expanded(
              child: _catches.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      itemCount: _catches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _CatchCard(
                        entry: _catches[i],
                        index: i,
                        l10n: l10n,
                        locale: locale,
                        onEdit: () => _editCatch(_catches[i]),
                        onDelete: () => _deleteCatch(_catches[i]),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _addCatch,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addCatch,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _TripHeader extends StatelessWidget {
  final String dateStr;
  final String startStr;
  final String endStr;
  final int catchCount;
  final double totalKg;
  final FishingLogLocalizations l10n;
  final String locale;
  final VoidCallback onBack;

  const _TripHeader({
    required this.dateStr,
    required this.startStr,
    required this.endStr,
    required this.catchCount,
    required this.totalKg,
    required this.l10n,
    required this.locale,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.play_circle_outline_rounded,
                      label: l10n.tripStart,
                      value: startStr,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.stop_circle_outlined,
                      label: l10n.tripEnd,
                      value: endStr,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.set_meal_rounded,
                      label: l10n.catchWord,
                      value: arabicN('$catchCount', locale),
                    ),
                    if (totalKg > 0) ...[
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: Icons.scale_rounded,
                        label: l10n.totalWeight,
                        value:
                            '${arabicN(totalKg.toStringAsFixed(1), locale)} ${l10n.kgUnit}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 9, height: 1.2)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final FishingLogLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.set_meal_rounded,
                size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noCatchesLogged,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addCatch,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Catch card ────────────────────────────────────────────────────────────────

class _CatchCard extends StatelessWidget {
  final CatchEntry entry;
  final int index;
  final FishingLogLocalizations l10n;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CatchCard({
    required this.entry,
    required this.index,
    required this.l10n,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = arabicN(
        DateFormat('HH:mm').format(entry.timestamp.toLocal()), locale);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.set_meal_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.species,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      
                      // Number badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          arabicN('#${index + 1}', locale),
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (entry.weightKg != null)
                        _Badge(
                          icon: Icons.scale_rounded,
                          label:
                              '${arabicN(entry.weightKg!.toStringAsFixed(1), locale)} ${l10n.kgUnit}',
                          color: AppColors.accent,
                        ),
                      _Badge(
                        icon: Icons.access_time_rounded,
                        label: timeStr,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        entry.notes!,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey.shade400, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.latitude.toStringAsFixed(3)}, ${entry.longitude.toStringAsFixed(3)}',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Column(
              children: [
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.accent,
                  onTap: onEdit,
                ),
                const SizedBox(height: 4),
                _ActionBtn(
                  icon: Icons.delete_rounded,
                  color: AppColors.red.withValues(alpha: 0.8),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Catch edit sheet ──────────────────────────────────────────────────────────

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
    _weightCtrl = TextEditingController(text: e?.weightKg?.toString() ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _latCtrl = TextEditingController(
        text: e != null ? e.latitude.toStringAsFixed(6) : '');
    _lonCtrl = TextEditingController(
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

  String _localizedSpecies(FishingLogLocalizations l10n, int index) {
    switch (_quickSpeciesKeys[index]) {
      case 'quickSpeciesHamour':
        return l10n.quickSpeciesHamour;
      case 'quickSpeciesSafi':
        return l10n.quickSpeciesSafi;
      case 'quickSpeciesSobaity':
        return l10n.quickSpeciesSobaity;
      case 'quickSpeciesChanad':
        return l10n.quickSpeciesChanad;
      case 'quickSpeciesZubaidi':
        return l10n.quickSpeciesZubaidi;
      case 'quickSpeciesShrimp':
        return l10n.quickSpeciesShrimp;
      case 'quickSpeciesCrab':
        return l10n.quickSpeciesCrab;
      default:
        return _quickSpeciesValues[index];
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
    final l10n = FishingLogLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.entry != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        isEdit ? Icons.edit_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? l10n.editCatch : l10n.addCatch,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick species chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(_quickSpeciesKeys.length, (i) {
                  final label = _localizedSpecies(l10n, i);
                  final isSelected = _speciesCtrl.text == label;
                  return GestureDetector(
                    onTap: () => setState(() => _speciesCtrl.text = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Species field
              TextFormField(
                controller: _speciesCtrl,
                decoration: _dec(l10n.speciesName, Icons.set_meal_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '!' : null,
              ),
              const SizedBox(height: 12),

              // Weight field
              TextFormField(
                controller: _weightCtrl,
                decoration: _dec(l10n.kgUnit, Icons.scale_rounded),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*'))
                ],
              ),
              const SizedBox(height: 12),

              // Notes field
              TextFormField(
                controller: _notesCtrl,
                decoration: _dec(l10n.notesOptional, Icons.notes_rounded),
                maxLines: 2,
              ),
              const SizedBox(height: 18),

              // Location header
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.latitude.replaceAll(RegExp(r'\(.*\)'), '').trim(),
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickOnMap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined,
                              color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.pinOnMap,
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'))
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
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'))
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
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 12, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(l10n.locationPinned,
                        style: TextStyle(
                            color: Colors.green.shade600, fontSize: 11)),
                  ],
                ),
              ],
              const SizedBox(height: 22),

              // Save button
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(isEdit
                        ? Icons.save_rounded
                        : Icons.add_rounded),
                    label: Text(
                        isEdit ? l10n.saveChanges : l10n.addCatch,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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

  InputDecoration _dec(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.6), size: 20)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 10),
    );
  }
}
