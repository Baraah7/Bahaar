import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

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
  void dispose() {
    _speciesCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<LatLng?> _getLocation() async {
    try {
      final loc = Location();
      final data = await loc.getLocation();
      if (data.latitude != null && data.longitude != null) {
        return LatLng(data.latitude!, data.longitude!);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final location = await _getLocation();
    if (!mounted) return;

    final weight = double.tryParse(_weightCtrl.text.trim());

    Navigator.of(context).pop(CatchFormResult(
      species: _speciesCtrl.text.trim(),
      weightKg: weight,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
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
              decoration: _inputDecoration('Species *', Icons.set_meal),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter species name' : null,
            ),
            const SizedBox(height: 12),

            // Weight field
            TextFormField(
              controller: _weightCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Weight (kg)', Icons.scale),
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
              decoration: _inputDecoration('Notes (optional)', Icons.notes),
              maxLines: 2,
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
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
