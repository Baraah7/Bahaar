import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/screens/location_picker_screen.dart';

/// Bottom sheet form for logging a single catch during an active trip.
class CatchForm extends StatefulWidget {
  const CatchForm({super.key});

  /// Show the form and return a [CatchFormResult] if submitted, or null.
  static Future<CatchFormResult?> show(BuildContext context) {
    return showModalBottomSheet<CatchFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CatchForm(),
    );
  }

  @override
  State<CatchForm> createState() => _CatchFormState();
}

class _CatchFormState extends State<CatchForm> {
  final _formKey = GlobalKey<FormState>();
  final _speciesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  bool _locating = false;
  bool _locationLocked = false; // true once GPS populated the fields
  bool _mapPinned = false;     // true when location was pinned on the map

  // Common Gulf species for quick-pick
  static const _quickSpecies = [
    'Hamour',
    'Safi',
    'Sobaity',
    'Chanad',
    'Zubaidi',
    'Shrimp',
    'Crab',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
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

  Future<void> _fetchLocation() async {
    setState(() => _locating = true);
    try {
      final loc = Location();
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null && mounted) {
        setState(() {
          _latCtrl.text = data.latitude!.toStringAsFixed(6);
          _lonCtrl.text = data.longitude!.toStringAsFixed(6);
          _locationLocked = true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _pickOnMap() async {
    final current = _parseLocation();
    final picked = await LocationPickerScreen.open(context, initial: current);
    if (picked != null && mounted) {
      setState(() {
        _latCtrl.text = picked.latitude.toStringAsFixed(6);
        _lonCtrl.text = picked.longitude.toStringAsFixed(6);
        _locationLocked = true;
        _mapPinned = true;
      });
    }
  }

  LatLng? _parseLocation() {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat != null && lon != null) return LatLng(lat, lon);
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final location = _parseLocation();
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (!mounted) return;
    Navigator.of(context).pop(CatchFormResult(
      species: _speciesCtrl.text.trim(),
      weightKg: weight,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      location: location,
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
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log Catch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Quick-pick species chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _quickSpecies.map((s) {
                  return ActionChip(
                    label: Text(s,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                    backgroundColor: const Color(0xFF1A5C62),
                    side: const BorderSide(color: Colors.teal),
                    onPressed: () => _speciesCtrl.text = s,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Species field
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

              // Weight field
              TextFormField(
                controller: _weightCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Weight (kg)', Icons.scale),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
              ),
              const SizedBox(height: 12),

              // Notes field
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Notes (optional)', Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ── Catch location ───────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Catch Location',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (_locating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.teal),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _fetchLocation,
                          child: const Row(
                            children: [
                              Icon(Icons.my_location,
                                  color: Colors.teal, size: 14),
                              SizedBox(width: 4),
                              Text('Re-fetch GPS',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                _mapPinned
                    ? 'Location pinned on map.'
                    : _locationLocked
                        ? 'GPS location auto-filled — edit if needed.'
                        : 'Location blank — GPS unavailable.',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Log Catch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7490),
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
      errorStyle:
          const TextStyle(color: Colors.orangeAccent, fontSize: 10),
    );
  }
}

class CatchFormResult {
  final String species;
  final double? weightKg;
  final String? notes;
  final LatLng? location;

  const CatchFormResult({
    required this.species,
    this.weightKg,
    this.notes,
    this.location,
  });
}
