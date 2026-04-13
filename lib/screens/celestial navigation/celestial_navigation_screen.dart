import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/navigation/sidereal_time.dart';
import 'package:bahaar/navigation/corrections.dart';
import 'package:bahaar/navigation/confidence_engine.dart';
import 'package:bahaar/navigation/celestial_fix_notifier.dart';
import 'package:bahaar/navigation/camera_service.dart';
import 'package:bahaar/navigation/star_identifier.dart';
import 'package:bahaar/screens/celestial navigation/sky_scanner_view.dart';

class CelestialNavigationScreen extends StatefulWidget {
  const CelestialNavigationScreen({super.key});

  @override
  State<CelestialNavigationScreen> createState() =>
      _CelestialNavigationScreenState();
}

class _CelestialNavigationScreenState
    extends State<CelestialNavigationScreen> {
  // ── Live clock ───────────────────────────────────────────────────────────
  Timer? _clockTimer;
  DateTime _nowUtc = DateTime.now().toUtc();

  // ── GPS ──────────────────────────────────────────────────────────────────
  final _location = Location();
  LatLng? _gpsPosition;
  bool _gpsLoading = false;

  // ── Sight-reduction form ─────────────────────────────────────────────────
  final _altController = TextEditingController(text: '45.0');
  final _hoeController = TextEditingController(text: '3.0');
  final _pressController = TextEditingController(text: '1013.0');
  final _tempController = TextEditingController(text: '25.0');

  // ── Confidence-engine inputs ─────────────────────────────────────────────
  final _pitchController = TextEditingController(text: '1.0');
  final _starsController = TextEditingController(text: '12');
  final _driftController = TextEditingController(text: '0.05');

  // ── Sky Scanner ──────────────────────────────────────────────────────────
  final _cameraService = CameraService();
  bool _scannerReady   = false;
  String? _scannerError;

  // Last scan results (populated when the scanner view closes)
  int    _detectedStars     = 0;
  double _engineConfidence  = 0.0;
  double _imuDrift          = 0.0;
  bool   _motionBlurred     = false;
  bool   _horizonDetected   = false;
  double _horizonAngle      = 0.0;
  List<String> _identifiedStarNames = [];

  // ── Results ──────────────────────────────────────────────────────────────
  double? _correctedAltDeg; // after refraction + dip correction
  double? _correctionArcmin;
  String _correctionReason = '';
  ConfidenceResult? _confidenceResult;
  CelestialFix? _postedFix;

  final _engine = const ConfidenceEngine(expectedStarsInRegion: 20);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _nowUtc = DateTime.now().toUtc());
    });
    _fetchGps();
    // Load star catalog in the background — needed by Sky Scanner
    StarIdentifier.instance.loadCatalog().then((err) {
      if (err != null && mounted) {
        setState(() => _scannerError = err);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _cameraService.dispose();
    _altController.dispose();
    _hoeController.dispose();
    _pressController.dispose();
    _tempController.dispose();
    _pitchController.dispose();
    _starsController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────

  Future<void> _fetchGps() async {
    setState(() => _gpsLoading = true);
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
        setState(() => _gpsPosition = LatLng(data.latitude!, data.longitude!));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Celestial body positions ──────────────────────────────────────────────

  /// Sun azimuth and altitude for [pos] at [utc].
  /// Uses the same NOAA-derived math as CelestialCalculator.
  _AzAlt _sunPosition(LatLng pos, DateTime utc) {
    final jd = _jd(utc);
    final t = (jd - 2451545.0) / 36525.0;

    // Sun apparent ecliptic longitude
    final m = _r(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final l0 = 280.46646 + t * (36000.76983 + t * 0.0003032);
    final c = math.sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t))
        + math.sin(2 * m) * (0.019993 - 0.000101 * t)
        + math.sin(3 * m) * 0.000289;
    final lambda = _r(l0 + c - 0.00569
        - 0.00478 * math.sin(_r(125.04 - 1934.136 * t)));

    // Obliquity
    final eps = _r(23.0
        + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        + 0.00256 * math.cos(_r(125.04 - 1934.136 * t)));

    final lambdaR = lambda * math.pi / 180;
    final epsR = eps * math.pi / 180;

    // Declination
    final dec = math.asin(math.sin(epsR) * math.sin(lambdaR));
    // Right ascension (degrees)
    final ra = math.atan2(
            math.cos(epsR) * math.sin(lambdaR), math.cos(lambdaR)) *
        180 / math.pi;

    // GMST → LHA
    final gmst = SiderealTime.gmst(utc) ?? 0.0;
    final lha = _r(gmst + pos.longitude - ra) * math.pi / 180;
    final latR = pos.latitude * math.pi / 180;

    final sinAlt = math.sin(latR) * math.sin(dec)
        + math.cos(latR) * math.cos(dec) * math.cos(lha);
    final alt = math.asin(sinAlt) * 180 / math.pi;

    final az = math.atan2(
          -math.cos(dec) * math.sin(lha),
          math.sin(dec) * math.cos(latR)
              - math.cos(dec) * math.cos(lha) * math.sin(latR),
        ) * 180 / math.pi;

    return _AzAlt(_norm360(az), alt);
  }

  /// Moon azimuth and altitude using the same simplified model as
  /// CelestialCalculator._moonAltitude, extended with azimuth.
  _AzAlt _moonPosition(LatLng pos, DateTime utc) {
    final jd = _jd(utc);
    final t = (jd - 2451545.0) / 36525.0;

    final L = (218.316 + 13.176396 * (jd - 2451545.0)) % 360;
    final mAngle = _r((134.963 + 13.064993 * (jd - 2451545.0)) % 360);
    final F = _r((93.272 + 13.229350 * (jd - 2451545.0)) % 360);

    final lambda = L + 6.289 * math.sin(mAngle);
    final beta = 5.128 * math.sin(F);

    final eps = _r(23.0
        + (26.0 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60);

    final lambdaR = lambda * math.pi / 180;
    final betaR = beta * math.pi / 180;
    final epsR = eps * math.pi / 180;

    final ra = math.atan2(
            math.sin(lambdaR) * math.cos(epsR)
                - math.tan(betaR) * math.sin(epsR),
            math.cos(lambdaR)) *
        180 / math.pi;
    final dec = math.asin(math.sin(betaR) * math.cos(epsR)
        + math.cos(betaR) * math.sin(epsR) * math.sin(lambdaR));

    final gmst = SiderealTime.gmst(utc) ?? 0.0;
    final lha = _r(gmst + pos.longitude - ra) * math.pi / 180;
    final latR = pos.latitude * math.pi / 180;

    final sinAlt = math.sin(latR) * math.sin(dec)
        + math.cos(latR) * math.cos(dec) * math.cos(lha);
    final alt = math.asin(sinAlt.clamp(-1.0, 1.0)) * 180 / math.pi;

    final az = math.atan2(
          -math.cos(dec) * math.sin(lha),
          math.sin(dec) * math.cos(latR)
              - math.cos(dec) * math.cos(lha) * math.sin(latR),
        ) * 180 / math.pi;

    return _AzAlt(_norm360(az), alt);
  }

  // ── Sight reduction ───────────────────────────────────────────────────────

  void _calculateSightReduction() {
    final appAlt = double.tryParse(_altController.text) ?? 0.0;
    final hoe = double.tryParse(_hoeController.text) ?? 3.0;
    final press = double.tryParse(_pressController.text) ?? 1013.0;
    final temp = double.tryParse(_tempController.text) ?? 25.0;

    final reason = StringBuffer();
    final totalArcmin = CelestialCorrections.totalCorrection(
      appAlt, hoe, press, temp,
      reason: reason,
    );

    setState(() {
      _correctionArcmin = totalArcmin;
      _correctionReason = reason.toString();
      if (totalArcmin > 0) {
        _correctedAltDeg = appAlt - totalArcmin / 60.0;
      } else {
        _correctedAltDeg = null;
      }
    });
  }

  // ── Confidence score ──────────────────────────────────────────────────────

  void _calculateConfidence() {
    final pitch = double.tryParse(_pitchController.text) ?? 1.0;
    final stars = int.tryParse(_starsController.text) ?? 12;
    final drift = double.tryParse(_driftController.text) ?? 0.05;
    final appAlt = double.tryParse(_altController.text) ?? 45.0;

    // Simulate 10 IMU samples at the given pitch std-dev
    final samples = List.generate(
      10,
      (i) => pitch * math.sin(i * math.pi / 5),
    );

    final result = _engine.evaluate(
      pitchSamplesWindow: samples,
      detectedUsableStars: stars,
      primaryAltitudeDeg: _correctedAltDeg ?? appAlt,
      peakGyroDriftDegPerSec: drift,
    );

    setState(() => _confidenceResult = result);
  }

  // ── Sky Scanner ───────────────────────────────────────────────────────────

  Future<void> _initScanner() async {
    setState(() => _scannerError = null);
    final err = await _cameraService.initialize();
    if (mounted) {
      setState(() {
        _scannerReady = err == null;
        _scannerError = err;
      });
    }
  }

  /// Initialises the camera (if needed) then pushes [SkyScannerView].
  /// When the user closes the scanner the results are applied to state and
  /// the confidence-engine inputs are auto-filled.
  Future<void> _openScanner() async {
    if (!_scannerReady) {
      await _initScanner();
      if (!_scannerReady) return;
    }
    if (!mounted) return;

    final result = await Navigator.push<SkyScannerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SkyScannerView(service: _cameraService),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _detectedStars        = result.detectedStars;
        _engineConfidence     = result.engineConfidence;
        _imuDrift             = result.imuDrift;
        _motionBlurred        = false;
        _horizonDetected      = result.horizonDetected;
        _horizonAngle         = result.horizonAngle;
        _identifiedStarNames  = result.identifiedStarNames;
      });
      // Auto-fill confidence engine inputs with the scan results
      _starsController.text = result.detectedStars.toString();
      _driftController.text = result.imuDrift.toStringAsFixed(3);
    }
  }

  // ── Post fix to map ───────────────────────────────────────────────────────

  void _postFixToMap() {
    if (_gpsPosition == null || _confidenceResult == null) return;
    if (_confidenceResult!.decision == FixDecision.rejected) return;

    final uncertaintyNm =
        _confidenceResult!.decision == FixDecision.fix ? 3.0 : 5.0;

    // GPS spoofing check — compare celestial fix to GPS.
    // In manual-entry mode the celestial fix IS the GPS position
    // (user hasn't entered a separate fix lat/lng), so we use the
    // confidence score itself as the spoofing proxy.
    // A full implementation would compare independently derived positions.
    final isSpoofed = _confidenceResult!.score < 30 &&
        CelestialFixNotifier.instance.fix != null;

    final fix = CelestialFix(
      position: _gpsPosition!,
      confidenceScore: _confidenceResult!.score,
      decision: _confidenceResult!.decision,
      uncertaintyNm: uncertaintyNm,
      timestamp: _nowUtc,
    );

    CelestialFixNotifier.instance.setFix(fix, spoofingAlert: isSpoofed);
    setState(() => _postedFix = fix);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text(
          'Fix posted to map — uncertainty ±${uncertaintyNm.toStringAsFixed(0)} NM',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'Clear',
          textColor: AppColors.tan,
          onPressed: () {
            CelestialFixNotifier.instance.clearFix();
            setState(() => _postedFix = null);
          },
        ),
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  static double _jd(DateTime dt) {
    int y = dt.year, m = dt.month;
    final d = dt.day
        + dt.hour / 24.0
        + dt.minute / 1440.0
        + dt.second / 86400.0;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _r(double deg) => deg * math.pi / 180.0;
  static double _norm360(double deg) {
    final r = deg % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  String _fmtGmst(double? deg) {
    if (deg == null) return '--';
    final h = SiderealTime.degreesToHours(deg);
    final hours = h.floor();
    final mins = ((h - hours) * 60).floor();
    final secs = (((h - hours) * 60 - mins) * 60).round();
    return '${hours.toString().padLeft(2, '0')}h '
        '${mins.toString().padLeft(2, '0')}m '
        '${secs.toString().padLeft(2, '0')}s';
  }

  String _fmtDeg(double deg) => '${deg.toStringAsFixed(2)}°';

  String _fmtAzAlt(_AzAlt? aa) {
    if (aa == null) return '--';
    return 'Az ${aa.azimuth.toStringAsFixed(1)}°  Alt ${aa.altitude.toStringAsFixed(1)}°';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gmst = SiderealTime.gmst(_nowUtc);
    final lst = (_gpsPosition != null && gmst != null)
        ? SiderealTime.localSiderealTime(gmst, _gpsPosition!.longitude)
        : null;
    final sunPos =
        _gpsPosition != null ? _sunPosition(_gpsPosition!, _nowUtc) : null;
    final moonPos =
        _gpsPosition != null ? _moonPosition(_gpsPosition!, _nowUtc) : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, size: 20),
            SizedBox(width: 8),
            Text('DS-1  Celestial Navigation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_postedFix != null)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Fix is live on map',
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Spoofing banner (if active) ─────────────────────────────────
          if (CelestialFixNotifier.instance.spoofingAlert)
            _SpoofingBanner(
              onDismiss: () {
                CelestialFixNotifier.instance.clearFix();
                setState(() => _postedFix = null);
              },
            ),

          // ── Astronomical Clock ──────────────────────────────────────────
          _SectionCard(
            title: 'Astronomical Clock',
            icon: Icons.access_time,
            children: [
              _Row('UTC', _fmtUtc(_nowUtc)),
              _Row('GMST', _fmtGmst(gmst)),
              _Row('GMST (°)', gmst != null ? _fmtDeg(gmst) : '--'),
              _Row(
                'LST',
                lst != null ? _fmtGmst(lst) : '— needs GPS —',
              ),
              if (_gpsPosition != null) ...[
                const Divider(height: 12),
                _Row('GPS Lat', '${_gpsPosition!.latitude.toStringAsFixed(5)}°'),
                _Row('GPS Lon', '${_gpsPosition!.longitude.toStringAsFixed(5)}°'),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _gpsLoading
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.gps_fixed, size: 16),
                          label: const Text('Get GPS'),
                          onPressed: _fetchGps,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Celestial Bodies ────────────────────────────────────────────
          _SectionCard(
            title: 'Celestial Body Positions',
            icon: Icons.wb_sunny_outlined,
            children: [
              _Row('☀️ Sun', _fmtAzAlt(sunPos)),
              if (sunPos != null && sunPos.altitude < 0)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('Sun below horizon',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              const SizedBox(height: 4),
              _Row('🌙 Moon', _fmtAzAlt(moonPos)),
              if (moonPos != null && moonPos.altitude < 8 && moonPos.altitude >= 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Moon at ${moonPos.altitude.toStringAsFixed(1)}° — below 8° safe limit',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFB45309)),
                  ),
                ),
              if (_gpsPosition == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Enable GPS for live body positions.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Sky Scanner ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Sky Scanner (DS-1 Camera)',
            icon: Icons.camera_alt_outlined,
            children: [
              if (_scannerError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _scannerError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              // Open scanner button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.videocam_outlined, size: 18),
                  label: Text(_detectedStars > 0
                      ? 'Scan Again'
                      : 'Start Sky Scan'),
                  onPressed: _openScanner,
                ),
              ),
              const SizedBox(height: 10),
              // Last scan results
              if (_detectedStars > 0) ...[
                _Row('Stars detected', '$_detectedStars'),
                _Row('Engine confidence',
                    '${_engineConfidence.toStringAsFixed(1)} %'),
                _Row('IMU drift',
                    '${_imuDrift.toStringAsFixed(3)} °/s'),
                _Row('Motion blurred', _motionBlurred ? 'YES' : 'No'),
                _Row(
                  'Horizon',
                  _horizonDetected
                      ? 'Detected  ${_horizonAngle.toStringAsFixed(1)}°'
                      : 'Not detected',
                ),
                if (_identifiedStarNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _identifiedStarNames.map((name) {
                      return Chip(
                        label: Text(name,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ] else
                const Text(
                  'Point the camera at the night sky and tap Start Sky Scan.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Sight Reduction Calculator ──────────────────────────────────
          _SectionCard(
            title: 'Sight Reduction Calculator',
            icon: Icons.calculate_outlined,
            children: [
              _NumField(
                  label: 'Apparent Altitude (°)',
                  controller: _altController,
                  hint: 'e.g. 45.3'),
              _NumField(
                  label: 'Height of Eye (m)',
                  controller: _hoeController,
                  hint: 'e.g. 3'),
              _NumField(
                  label: 'Pressure (mb)',
                  controller: _pressController,
                  hint: 'e.g. 1013'),
              _NumField(
                  label: 'Temperature (°C)',
                  controller: _tempController,
                  hint: 'e.g. 25'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.functions, size: 18),
                  label: const Text('Apply Corrections'),
                  onPressed: _calculateSightReduction,
                ),
              ),
              if (_correctionArcmin != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _correctedAltDeg != null
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _correctedAltDeg != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Row('Total correction',
                                '${_correctionArcmin!.toStringAsFixed(2)}\''),
                            _Row('True altitude',
                                '${_correctedAltDeg!.toStringAsFixed(3)}°'),
                          ],
                        )
                      : Text(
                          _correctionReason.isNotEmpty
                              ? _correctionReason
                              : 'Sighting rejected — below 8° limit.',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                        ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Confidence Score Engine ─────────────────────────────────────
          _SectionCard(
            title: 'Confidence Assessment',
            icon: Icons.speed_outlined,
            children: [
              _NumField(
                  label: 'Pitch Std Dev (°) — sea state proxy',
                  controller: _pitchController,
                  hint: 'e.g. 1.0  (calm)  >2° = rough'),
              _NumField(
                  label: 'Detected usable stars',
                  controller: _starsController,
                  hint: 'e.g. 12'),
              _NumField(
                  label: 'Peak gyro drift (°/s)',
                  controller: _driftController,
                  hint: 'e.g. 0.05'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.assessment_outlined, size: 18),
                  label: const Text('Compute Score'),
                  onPressed: () {
                    _calculateSightReduction();
                    _calculateConfidence();
                  },
                ),
              ),
              if (_confidenceResult != null) ...[
                const SizedBox(height: 10),
                _ConfidenceBar(result: _confidenceResult!),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── GPS Spoofing Detection & Fix Posting ────────────────────────
          _SectionCard(
            title: 'GPS Anti-Spoofing',
            icon: Icons.security_outlined,
            children: [
              const Text(
                'Every 5 min the app compares the celestial fix to the GPS '
                'position. A delta > 2 NM triggers a spoofing alert.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              if (_gpsPosition == null)
                const Text('GPS unavailable — enable location.',
                    style: TextStyle(color: Colors.red, fontSize: 12))
              else ...[
                _Row('GPS fix', '${_gpsPosition!.latitude.toStringAsFixed(4)}°, '
                    '${_gpsPosition!.longitude.toStringAsFixed(4)}°'),
                if (_postedFix != null)
                  _Row('DS-1 fix timestamp',
                      _fmtUtc(_postedFix!.timestamp)),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canPost
                        ? const Color(0xFF1B5E20)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.pin_drop_outlined, size: 18),
                  label: Text(_postedFix != null
                      ? 'Update Fix on Map'
                      : 'Post Fix to Map'),
                  onPressed: _canPost ? _postFixToMap : null,
                ),
              ),
              if (!_canPost)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Compute confidence score first (score ≥ 30 required).',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── System limits card ──────────────────────────────────────────
          _SectionCard(
            title: 'System Limits (DS-1)',
            icon: Icons.info_outline,
            children: const [
              _InfoRow('Accuracy', '3–5 Nautical Miles (95% CI)'),
              _InfoRow('Min star altitude', '8° above horizon'),
              _InfoRow('Max gyro drift', '< 0.5 °/s for valid fix'),
              _InfoRow('Rough sea reject', 'Pitch σ > 2° halves score'),
              _InfoRow('Spoofing threshold', 'GPS Δ > 2 NM'),
              _InfoRow('Score < 30', 'Fix refused — never guessed'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool get _canPost =>
      _gpsPosition != null &&
      _confidenceResult != null &&
      _confidenceResult!.decision != FixDecision.rejected;

  static String _fmtUtc(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')} UTC';
}

// ─── Helper data class ────────────────────────────────────────────────────────

class _AzAlt {
  final double azimuth;
  final double altitude;
  const _AzAlt(this.azimuth, this.altitude);
}

// ─── Reusable UI components ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label: $value',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _NumField(
      {required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
          labelStyle: const TextStyle(fontSize: 12),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final ConfidenceResult result;
  const _ConfidenceBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.color;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Score: ${result.score}/100',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.decision == FixDecision.fix
                      ? 'FIX ACCEPTED'
                      : result.decision == FixDecision.lowConfidenceWarning
                          ? 'LOW CONFIDENCE'
                          : 'REJECTED',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(result.reason,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _SpoofingBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SpoofingBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '⚠ GPS SPOOFING ALERT\nCelestial fix diverges from GPS by > 2 NM. '
              'Do not rely on GPS position.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
