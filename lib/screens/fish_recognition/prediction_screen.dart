import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/constants/species_data.dart';
import 'package:bahaar/l10n/fish_recognition/fish_recognition_localizations.dart';
import 'package:bahaar/services/map/bahaar_ai_service.dart';
import 'package:bahaar/utilities/map/celestial_navigation/localization_helper.dart';
import 'package:bahaar/widgets/common/app_card.dart';
import 'package:bahaar/widgets/common/app_loading_view.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class PredictionScreen extends StatefulWidget {
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
  final MapController _miniMapController = MapController();

  LatLng? _selectedLatLng;
  String _selectedSpeciesId = 'hamour';
  bool _isLoading = false;
  String? _errorMessage;
  PredictionResult? _result;
  bool _showMiniMap = false;

  static const _teal = Color(0xFF0D4F54);

  FishRecognitionLocalizations get _l10n => FishRecognitionLocalizations.of(context);
  bool get _isAr => _l10n.localeName == 'ar';

  String _n(String value) => arabicN(value, _l10n.localeName);

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
        setState(() =>
            _selectedLatLng = LatLng(data.latitude!, data.longitude!));
      }
    } catch (_) {}
  }

  Future<void> _runPrediction() async {
    if (_selectedLatLng == null) {
      showAppSnackBar(context, _l10n.selectLocationFirst);
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
      setState(() => _errorMessage = _isAr ? e.messageAr : e.messageEn);
    } catch (_) {
      setState(() => _errorMessage = _l10n.unexpectedError);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _probabilityLabel(double p) {
    if (p >= 75) return _l10n.probExcellent;
    if (p >= 55) return _l10n.probVeryGood;
    if (p >= 40) return _l10n.probModerate;
    if (p >= 25) return _l10n.probWeak;
    return _l10n.probNotSuitable;
  }

  Color _probabilityColor(double p) {
    if (p >= 60) return const Color(0xFF059669);
    if (p >= 30) return const Color(0xFFD97706);
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.accent, AppColors.primary],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoading
                      ? AppLoadingView(message: _l10n.analyzing, color: Colors.white)
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                                _buildError(),
                              ],
                              if (_result != null) ...[
                                const SizedBox(height: 20),
                                _buildResults(_result!),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.predictionTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _l10n.aiPoweredAnalysis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.set_meal_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ── Location card ────────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.cream, size: 20),
              const SizedBox(width: 8),
              Text(_l10n.location,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.cream)),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _showMiniMap = !_showMiniMap),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showMiniMap
                        ? AppColors.white.withValues(alpha: 0.15)
                        : AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showMiniMap
                          ? AppColors.white.withValues(alpha: 0.25)
                          : AppColors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMiniMap
                            ? Icons.map
                            : Icons.map_outlined,
                        size: 14,
                        color: _showMiniMap
                            ? Colors.white
                            : AppColors.white.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showMiniMap ? _l10n.hideMap : _l10n.selectFromMap,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showMiniMap ? Colors.white : AppColors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedLatLng != null)
            Row(
              children: [
                Icon(Icons.gps_fixed,
                    color: Colors.tealAccent.withValues(alpha: 0.75), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_n(_selectedLatLng!.latitude.toStringAsFixed(4))}°N  '
                  '${_n(_selectedLatLng!.longitude.toStringAsFixed(4))}°E',
                  style: TextStyle(
                      color: Colors.tealAccent, fontSize: 13),
                ),
              ],
            )
          else
            Text(
              _l10n.tapMapToSelect,
              style:
                  TextStyle(color: Colors.tealAccent.withValues(alpha: 0.75), fontSize: 13),
            ),
          if (_showMiniMap) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  mapController: _miniMapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng ??
                        const LatLng(26.2235, 50.5876),
                    initialZoom: 10,
                    onTap: (_, latLng) =>
                        setState(() => _selectedLatLng = latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bahaar.app',
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _selectedLatLng!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: AppColors.red, size: 36),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Species selector ─────────────────────────────────────────────────────────

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 4, top: 8),
          child: Text(_l10n.chooseSpecies,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.white)),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kAllSpecies.map((species) {
          final isSelected = species['id'] == _selectedSpeciesId;
          final name = _isAr
              ? species['nameAr'] as String
              : species['nameEn'] as String;
          return SizedBox(
            width: itemWidth,
            child: GestureDetector(
              onTap: () => setState(
            () => _selectedSpeciesId = species['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
            color: isSelected
                ? _teal
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? _teal
                  : AppColors.white.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
              ? _teal.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
                ),
                child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : AppColors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
                ),
              ),
            ),
          );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Predict button ───────────────────────────────────────────────────────────

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _runPrediction,
        icon: const Icon(Icons.analytics_outlined, size: 20),
        label: Text(_l10n.getPrediction,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.red.withValues(alpha: 0.75), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(color: AppColors.red.withValues(alpha: 0.75))),
          ),
          TextButton(
            onPressed: _runPrediction,
            child: Text(_l10n.retry,
                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Results ──────────────────────────────────────────────────────────────────

  Widget _buildResults(PredictionResult result) {
    final speciesData = kAllSpecies.firstWhere(
      (s) => s['id'] == _selectedSpeciesId,
      orElse: () => <String, dynamic>{},
    );
    final localAdvice = (_isAr
            ? speciesData['advice']
            : speciesData['adviceEn'] ?? speciesData['advice'])
        as String? ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.restrictions.isNotEmpty)
          _buildMpaBanner(result.restrictions),
        _buildProbabilityGauge(result.probability),
        const SizedBox(height: 12),
        _buildFactorCards(result),
        if (localAdvice.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSeasonalAdvice(localAdvice),
        ],
        if (result.nearbySpots.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildNearbySpots(result.nearbySpots),
        ],
      ],
    );
  }

  Widget _buildMpaBanner(List<MpaRestriction> restrictions) {
    final zoneName = restrictions.isNotEmpty
        ? (_isAr
            ? restrictions.first.nameAr
            : restrictions.first.nameAr) // use nameAr as fallback (server only returns Arabic)
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_l10n.insideProtectedZone}${zoneName.isNotEmpty ? " - $zoneName" : ""}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityGauge(double probability) {
    final color = _probabilityColor(probability);
    final label = _probabilityLabel(probability);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: _teal, size: 18),
              const SizedBox(width: 8),
              Text(
                _l10n.catchProbability,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: _teal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: probability / 100,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_n(probability.toStringAsFixed(0))}%',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCards(PredictionResult result) {
    final f = result.factors;
    final factors = [
      {'label': _l10n.factorSeason, 'value': f.seasonal, 'icon': Icons.calendar_today},
      {'label': _l10n.factorWeather, 'value': f.weather, 'icon': Icons.wb_sunny_outlined},
      {'label': _l10n.factorReports, 'value': f.human, 'icon': Icons.people_outline},
      {
        'label': _l10n.factorProximity,
        'value': result.nearbySpots.isNotEmpty
            ? (result.nearbySpots.first.distanceKm > 5 ? 0.8 : 1.2)
            : 1.0,
        'icon': Icons.location_searching,
      },
    ];

    return Row(
      children: factors.map((item) {
        final value = item['value'] as double;
        final color = value >= 1.1
            ? const Color(0xFF059669)
            : value >= 0.9
                ? const Color(0xFFD97706)
                : Colors.red.shade600;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: color, size: 18),
                ),
                const SizedBox(height: 6),
                Text(item['label'] as String,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 10),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  _n(value.toStringAsFixed(2)),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (value / 2).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonalAdvice(String advice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(advice,
                style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySpots(List<NearbySpot> spots) {
    final shown = spots.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_l10n.nearbyFishingSpots,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white)),
        const SizedBox(height: 10),
        ...shown.map((spot) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                title: Text(spot.nameAr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                subtitle: Text(
                  '${_n(spot.distanceKm.toStringAsFixed(1))} ${_l10n.kmUnit}',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey.shade400),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PredictionScreen(
                      initialLatLng: LatLng(spot.lat, spot.lng),
                      initialSpeciesId: spot.species.isNotEmpty
                          ? spot.species.first
                          : _selectedSpeciesId,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

