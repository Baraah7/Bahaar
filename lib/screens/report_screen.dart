// lib/screens/report_screen.dart
// Catch report submission form.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Bahaar/core/constants/species_data.dart';
import 'package:Bahaar/services/bahaar_ai_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BahaarAIService();
  final _location = Location();

  // Form state
  LatLng? _currentLocation;
  String _selectedSpeciesId = 'hamour';
  double? _quantity;
  int _successRating = 0;
  String _selectedMethod = 'gargoor';
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isSubmitting = false;
  bool _showLocationMap = false;

  // Mini-map for location adjustment
  final MapController _miniMapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _service.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      bool svc = await _location.serviceEnabled();
      if (!svc) svc = await _location.requestService();
      if (!svc) return;

      var perm = await _location.hasPermission();
      if (perm == PermissionStatus.denied) {
        perm = await _location.requestPermission();
      }
      if (perm != PermissionStatus.granted) return;

      final data = await _location.getLocation();
      if (mounted && data.latitude != null && data.longitude != null) {
        setState(() {
          _currentLocation = LatLng(data.latitude!, data.longitude!);
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_successRating == 0) {
      _showSnack('يرجى تحديد تقييم النجاح');
      return;
    }
    if (_currentLocation == null) {
      _showSnack('يرجى تحديد الموقع');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showSnack('يرجى تسجيل الدخول أولاً');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call Bahaar AI backend
      await _service.submitReport(
        userId: uid,
        lat: _currentLocation!.latitude,
        lng: _currentLocation!.longitude,
        speciesId: _selectedSpeciesId,
        successRating: _successRating,
        quantity: _quantity,
        method: _selectedMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Also save to Firestore as local backup
      await FirebaseFirestore.instance.collection('user_reports').add({
        'user_id': uid,
        'lat': _currentLocation!.latitude,
        'lng': _currentLocation!.longitude,
        'species_id': _selectedSpeciesId,
        'success_rating': _successRating,
        'quantity': _quantity,
        'method': _selectedMethod,
        'notes': _notesController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('شكراً! ساهمت في تحسين التنبؤات');
        Navigator.pop(context);
      }
    } on BahaarOfflineException catch (e) {
      // Even if the API is offline, still save to Firestore
      try {
        await FirebaseFirestore.instance.collection('user_reports').add({
          'user_id': uid,
          'lat': _currentLocation!.latitude,
          'lng': _currentLocation!.longitude,
          'species_id': _selectedSpeciesId,
          'success_rating': _successRating,
          'quantity': _quantity,
          'method': _selectedMethod,
          'notes': _notesController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'pending_sync': true,
        });
        if (mounted) {
          _showSnack('تم الحفظ محلياً. سيتم المزامنة عند الاتصال بالإنترنت');
          Navigator.pop(context);
        }
      } catch (_) {
        if (mounted) _showSnack(e.messageAr);
      }
    } catch (e) {
      if (mounted) _showSnack('حدث خطأ، يرجى المحاولة لاحقاً');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'تقرير صيد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0D4F54),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isSubmitting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0D4F54)),
                    SizedBox(height: 14),
                    Text('جاري الإرسال...'),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionTitle('الموقع'),
                    _buildLocationCard(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('نوع السمك'),
                    _buildSpeciesDropdown(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('الكمية'),
                    _buildQuantityField(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('تقييم النجاح'),
                    _buildStarRating(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('طريقة الصيد'),
                    _buildMethodDropdown(),
                    const SizedBox(height: 16),

                    _buildSectionTitle('ملاحظات (اختياري)'),
                    _buildNotesField(),
                    const SizedBox(height: 24),

                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Section helpers ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF0D4F54),
        ),
      ),
    );
  }

  // ── Location card ────────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: _currentLocation != null
                        ? Colors.green.shade600
                        : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentLocation != null
                        ? '${_currentLocation!.latitude.toStringAsFixed(4)}°N  '
                            '${_currentLocation!.longitude.toStringAsFixed(4)}°E'
                        : 'جاري تحديد الموقع...',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _showLocationMap = !_showLocationMap),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D4F54),
                  ),
                  child: const Text('تعديل'),
                ),
              ],
            ),
            if (_showLocationMap) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    mapController: _miniMapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ??
                          const LatLng(26.2235, 50.5876),
                      initialZoom: 11,
                      onTap: (_, latLng) =>
                          setState(() => _currentLocation = latLng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bahaar.app',
                      ),
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Species dropdown ─────────────────────────────────────────────────────────

  Widget _buildSpeciesDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpeciesId,
      decoration: _inputDecoration('اختر نوع السمك'),
      items: kAllSpecies
          .map((s) => DropdownMenuItem(
                value: s['id'] as String,
                child: Text(s['nameAr'] as String),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSpeciesId = v!),
      validator: (v) => v == null ? 'يرجى اختيار نوع السمك' : null,
    );
  }

  // ── Quantity field ───────────────────────────────────────────────────────────

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: _inputDecoration('الكمية').copyWith(
        suffixText: 'كجم',
        suffixStyle: const TextStyle(
          color: Color(0xFF0D4F54),
          fontWeight: FontWeight.bold,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'يرجى إدخال الكمية';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'يرجى إدخال رقم صحيح';
        return null;
      },
      onChanged: (v) => _quantity = double.tryParse(v),
    );
  }

  // ── Star rating ──────────────────────────────────────────────────────────────

  Widget _buildStarRating() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _successRating = star),
              child: Icon(
                star <= _successRating ? Icons.star : Icons.star_border,
                color: star <= _successRating
                    ? Colors.amber.shade600
                    : Colors.grey.shade400,
                size: 40,
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Method dropdown ──────────────────────────────────────────────────────────

  Widget _buildMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMethod,
      decoration: _inputDecoration('طريقة الصيد'),
      items: kMethodNamesAr.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedMethod = v!),
    );
  }

  // ── Notes field ──────────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: _inputDecoration('ملاحظات'),
      maxLines: 3,
      textInputAction: TextInputAction.newline,
    );
  }

  // ── Submit button ────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _submit,
      icon: const Icon(Icons.send),
      label: const Text(
        'إرسال التقرير',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D4F54),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D4F54), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
