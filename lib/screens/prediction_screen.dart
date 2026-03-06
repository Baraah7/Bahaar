// lib/screens/prediction_screen.dart
// Fish-probability prediction screen.
// Can be opened from the map (with pre-filled lat/lng + species) or
// standalone from the bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:Bahaar/core/constants/species_data.dart';
import 'package:Bahaar/services/bahaar_ai_service.dart';

class PredictionScreen extends StatefulWidget {
  /// Pre-filled from map tap or spot card.
  final LatLng? initialLatLng;
  final String? initialSpeciesId;

  const PredictionScreen({
    super.key,
    this.initialLatLng,
    this.initialSpeciesId,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _service = BahaarAIService();
  final _location = Location();

  LatLng? _selectedLatLng;
  String _selectedSpeciesId = 'hamour';
  bool _isLoading = false;
  String? _errorMessage;
  PredictionResult? _result;

  // Mini-map controller for location picker
  final MapController _miniMapController = MapController();
  bool _showMiniMap = false;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialLatLng;
    _selectedSpeciesId = widget.initialSpeciesId ?? 'hamour';
    if (_selectedLatLng == null) _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _fetchCurrentLocation() async {
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
          _selectedLatLng = LatLng(data.latitude!, data.longitude!);
        });
      }
    } catch (_) {}
  }

  // ── Prediction call ─────────────────────────────────────────────────────────

  Future<void> _runPrediction() async {
    if (_selectedLatLng == null) {
      _showSnack('يرجى اختيار موقع أولاً');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final r = await _service.predict(
        lat: _selectedLatLng!.latitude,
        lng: _selectedLatLng!.longitude,
        speciesId: _selectedSpeciesId,
        month: DateTime.now().month,
      );
      setState(() => _result = r);
    } on BahaarOfflineException catch (e) {
      setState(() => _errorMessage = e.messageAr);
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _probabilityLabel(double p) {
    if (p >= 75) return 'ممتاز 🎣';
    if (p >= 55) return 'جيد جداً';
    if (p >= 40) return 'متوسط';
    if (p >= 25) return 'ضعيف';
    return 'غير مناسب';
  }

  Color _probabilityColor(double p) {
    if (p >= 60) return Colors.green.shade600;
    if (p >= 30) return Colors.orange;
    return Colors.red;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'تنبؤات الصيد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0D4F54),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? _buildLoadingView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLocationCard(),
                    const SizedBox(height: 12),
                    _buildSpeciesSelector(),
                    const SizedBox(height: 16),
                    _buildPredictButton(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorView(),
                    ],
                    if (_result != null) ...[
                      const SizedBox(height: 20),
                      _buildResultsView(_result!),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF0D4F54)),
          SizedBox(height: 16),
          Text(
            'جاري التحليل...',
            style: TextStyle(fontSize: 16, color: Color(0xFF0D4F54)),
          ),
        ],
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
                const Icon(Icons.location_on, color: Color(0xFF0D4F54)),
                const SizedBox(width: 8),
                const Text(
                  'الموقع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showMiniMap = !_showMiniMap),
                  icon: Icon(
                    _showMiniMap ? Icons.map : Icons.map_outlined,
                    size: 16,
                  ),
                  label: Text(_showMiniMap ? 'إخفاء' : 'اختيار من الخريطة'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D4F54),
                  ),
                ),
              ],
            ),
            if (_selectedLatLng != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_selectedLatLng!.latitude.toStringAsFixed(4)}°N  '
                  '${_selectedLatLng!.longitude.toStringAsFixed(4)}°E',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'اضغط على الخريطة لاختيار موقع',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            if (_showMiniMap) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    mapController: _miniMapController,
                    options: MapOptions(
                      initialCenter: _selectedLatLng ??
                          const LatLng(26.2235, 50.5876),
                      initialZoom: 10,
                      onTap: (_, latLng) {
                        setState(() => _selectedLatLng = latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bahaar.app',
                      ),
                      if (_selectedLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLatLng!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 36,
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

  // ── Species selector ─────────────────────────────────────────────────────────

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'اختر النوع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // RTL
          child: Row(
            children: kAllSpecies.map((species) {
              final isSelected = species['id'] == _selectedSpeciesId;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(species['nameAr'] as String),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedSpeciesId = species['id'] as String),
                  selectedColor: const Color(0xFF0D4F54),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0D4F54)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Predict button ───────────────────────────────────────────────────────────

  Widget _buildPredictButton() {
    return ElevatedButton.icon(
      onPressed: _runPrediction,
      icon: const Icon(Icons.analytics_outlined),
      label: const Text(
        'احصل على التنبؤ',
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

  // ── Error view ───────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: _runPrediction,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────────

  Widget _buildResultsView(PredictionResult result) {
    // Pull local species advice as an offline-safe fallback.
    final speciesData = kAllSpecies.firstWhere(
      (s) => s['id'] == _selectedSpeciesId,
      orElse: () => <String, dynamic>{},
    );
    final localAdvice = speciesData['advice'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // MPA warning banner
        if (result.restrictions.isNotEmpty) _buildMpaBanner(result.restrictions),

        // Probability gauge
        _buildProbabilityGauge(result.probability),
        const SizedBox(height: 16),

        // Factor cards
        _buildFactorCards(result),
        const SizedBox(height: 16),

        // Seasonal advice (local species data)
        if (localAdvice.isNotEmpty) _buildSeasonalAdvice(localAdvice),
        const SizedBox(height: 16),

        // Nearby spots
        if (result.nearbySpots.isNotEmpty) _buildNearbySpots(result.nearbySpots),
      ],
    );
  }

  Widget _buildMpaBanner(List<MpaRestriction> restrictions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠️ أنت داخل منطقة محمية'
              '${restrictions.isNotEmpty ? " - ${restrictions.first.nameAr}" : ""}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityGauge(double probability) {
    final color = _probabilityColor(probability);
    final label = _probabilityLabel(probability);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: probability / 100,
                      strokeWidth: 14,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${probability.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorCards(PredictionResult result) {
    final f = result.factors;
    final factors = [
      {'label': 'الموسم', 'value': f.seasonal, 'icon': Icons.calendar_today},
      {'label': 'الطقس', 'value': f.weather, 'icon': Icons.wb_sunny},
      {'label': 'التقارير', 'value': f.human, 'icon': Icons.people},
      {
        'label': 'القرب',
        'value': (result.nearbySpots.isNotEmpty
            ? result.nearbySpots.first.distanceKm > 5 ? 0.8 : 1.2
            : 1.0),
        'icon': Icons.location_searching,
      },
    ];

    return Row(
      children: factors.map((f) {
        final value = f['value'] as double;
        final color = value >= 1.1
            ? Colors.green.shade600
            : value >= 0.9
                ? Colors.orange
                : Colors.red;

        return Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                children: [
                  Icon(f['icon'] as IconData, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    f['label'] as String,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (value / 2).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonalAdvice(String adviceAr) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFF0D4F54).withValues(alpha: 0.07),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF0D4F54)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                adviceAr,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySpots(List<NearbySpot> spots) {
    final shown = spots.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مواقع الصيد القريبة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...shown.map((spot) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: spot.isMpa
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    Icons.set_meal,
                    color: spot.isMpa
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
                title: Text(
                  spot.nameAr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${spot.distanceKm.toStringAsFixed(1)} كم',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PredictionScreen(
                        initialLatLng: LatLng(spot.lat, spot.lng),
                        initialSpeciesId: spot.species.isNotEmpty
                            ? spot.species.first
                            : _selectedSpeciesId,
                      ),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }
}

