import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/navigation/corrections.dart';
import 'package:bahaar/navigation/confidence_engine.dart';
import 'package:bahaar/navigation/celestial_fix_notifier.dart';
import 'package:bahaar/navigation/camera_service.dart';
import 'package:bahaar/navigation/dead_reckoning.dart';
import 'package:bahaar/navigation/star_identifier.dart';
import 'package:bahaar/screens/celestial navigation/sky_scanner_view.dart';
import 'package:bahaar/l10n/celestial_navigation/celestial_navigation_localizations.dart';

class CelestialNavigationScreen extends StatefulWidget {
  /// Optional controller used to switch to the map tab when the user taps
  /// "Fix is live on map". If null the button is hidden.
  final PageController? pageController;

  const CelestialNavigationScreen({super.key, this.pageController});

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

    // GPS spoofing check — compare the new celestial fix position to the
    // current GPS reading.  If the two positions diverge by more than
    // (uncertaintyNm + 2 NM guard band) the GPS signal is likely spoofed.
    bool isSpoofed = false;
    if (_gpsPosition != null) {
      final prevFix = CelestialFixNotifier.instance.fix;
      if (prevFix != null) {
        final deltaNm = DeadReckoning.distanceNm(
          _gpsPosition!,
          prevFix.position,
        );
        // Alert if GPS position and last celestial fix are > uncertaintyNm + 2 NM apart
        isSpoofed = deltaNm > (uncertaintyNm + 2.0);
      }
    }

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


  // ── Steps card ────────────────────────────────────────────────────────────

  Widget _buildStepsCard(CelestialNavigationLocalizations l10n) {
    final steps = l10n.steps;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white.withValues(alpha: 0.12),
            AppColors.white.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_outlined, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                l10n.howToUse,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step[0],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(step[1],
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = CelestialNavigationLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context, l10n)),

          // ── Content ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Spoofing banner
                if (CelestialFixNotifier.instance.spoofingAlert) ...[
                  _SpoofingBanner(
                    onDismiss: () {
                      CelestialFixNotifier.instance.clearFix();
                      setState(() => _postedFix = null);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // How-to steps
                _buildStepsCard(l10n),
                const SizedBox(height: 16),

                // Sky scanner
                _buildScannerCard(l10n),
                const SizedBox(height: 16),

                // Scan results (when available)
                if (_detectedStars > 0) _buildResultsCard(l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CelestialNavigationLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF0A0F1E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row
              Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Spacer(),
                  if (_postedFix != null && widget.pageController != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: Text(l10n.viewOnMap,
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => widget.pageController!.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Icon + title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.explore_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.celestialNavigation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.starBasedPositionFixing,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // GPS status pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _StatusPill(
                      icon: Icons.gps_fixed_rounded,
                      label: _gpsLoading
                          ? l10n.gettingGps
                          : _gpsPosition != null
                              ? '${_gpsPosition!.latitude.toStringAsFixed(3)}°, '
                                  '${_gpsPosition!.longitude.toStringAsFixed(3)}°'
                              : l10n.gpsUnavailable,
                      active: _gpsPosition != null && !_gpsLoading,
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      icon: Icons.star_rounded,
                      label: _detectedStars > 0
                          ? l10n.starsDetectedCount(_detectedStars)
                          : l10n.noScanYet,
                      active: _detectedStars > 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerCard(CelestialNavigationLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white.withValues(alpha: 0.12),
            AppColors.white.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColors.white.withValues(alpha: 0.1),
        //     blurRadius: 20,
        //     offset: const Offset(0, 8),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                l10n.skyScanner,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_detectedStars > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.confidencePct(_engineConfidence.toStringAsFixed(0)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.scannerDescription,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
          ),
          if (_scannerError != null) ...[
            const SizedBox(height: 8),
            Text(_scannerError!,
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.45),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.videocam_rounded, size: 20),
              label: Text(
                _detectedStars > 0 ? l10n.scanAgain : l10n.startSkyScan,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: _openScanner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(CelestialNavigationLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.scanResults,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DarkRow(l10n.starsDetected, '$_detectedStars'),
          _DarkRow(l10n.confidence, '${_engineConfidence.toStringAsFixed(1)}%'),
          _DarkRow(l10n.imuDrift, '${_imuDrift.toStringAsFixed(3)} °/s'),
          _DarkRow(
            l10n.horizon,
            _horizonDetected
                ? l10n.horizonDetectedAngle(_horizonAngle.toStringAsFixed(1))
                : l10n.notDetected,
          ),
          if (_identifiedStarNames.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(l10n.identifiedStars,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _identifiedStarNames.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 10),
                      const SizedBox(width: 4),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
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

// ─── Reusable UI components ───────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _StatusPill({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? Colors.greenAccent.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: active ? Colors.greenAccent : Colors.white38),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.greenAccent : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkRow extends StatelessWidget {
  final String label;
  final String value;
  const _DarkRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
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
          Expanded(
            child: Text(
              CelestialNavigationLocalizations.of(context).spoofingAlert,
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
