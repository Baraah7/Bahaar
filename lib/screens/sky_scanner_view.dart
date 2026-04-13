import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:Bahaar/core/constants/app_colors.dart';
import 'package:Bahaar/navigation/camera_service.dart';
import 'package:Bahaar/navigation/star_identifier.dart';

/// Result handed back to the caller when the scanner is closed.
class SkyScannerResult {
  final int    detectedStars;
  final double engineConfidence;
  final double imuDrift;
  final bool   horizonDetected;
  final double horizonAngle;
  final List<String> identifiedStarNames;

  const SkyScannerResult({
    required this.detectedStars,
    required this.engineConfidence,
    required this.imuDrift,
    required this.horizonDetected,
    required this.horizonAngle,
    required this.identifiedStarNames,
  });
}

/// Full-screen camera preview for DS-1 sky scanning.
///
/// Starts capture on entry, stops on exit, and returns a [SkyScannerResult]
/// so the caller can auto-fill the confidence engine inputs.
class SkyScannerView extends StatefulWidget {
  final CameraService service;

  const SkyScannerView({super.key, required this.service});

  @override
  State<SkyScannerView> createState() => _SkyScannerViewState();
}

class _SkyScannerViewState extends State<SkyScannerView> {
  StreamSubscription<CameraFrameResult>? _sub;

  // Live data updated from frame stream
  int    _stars       = 0;
  double _confidence  = 0.0;
  double _imuDrift    = 0.0;
  bool   _blurred     = false;
  bool   _horizon     = false;
  double _horizonAngle = 0.0;
  List<String> _names = [];
  bool _processing    = false;

  @override
  void initState() {
    super.initState();
    _startCapture();
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.service.stopCapture();
    super.dispose();
  }

  Future<void> _startCapture() async {
    await widget.service.startCapture();
    _sub = widget.service.results.listen(_onFrame);
  }

  void _onFrame(CameraFrameResult frame) {
    if (!mounted) return;

    final names = <String>[];
    if (frame.stars.hasStars) {
      final match = StarIdentifier.instance.identify(
        centroids:   frame.stars.stars!,
        imageWidth:  1920,
        imageHeight: 1080,
        fovHDeg:     widget.service.fovHDeg,
      );
      if (match != null) {
        for (final s in match.catalogTriplet) {
          if (s.name.isNotEmpty) names.add(s.name);
        }
      }
    }

    setState(() {
      _stars       = frame.stars.stars?.length ?? 0;
      _confidence  = frame.engineConfidence;
      _imuDrift    = frame.imuTag.driftDegPerSec;
      _blurred     = frame.motionBlurred;
      _horizon     = frame.horizon.detected;
      _horizonAngle = frame.horizon.angleDeg ?? 0.0;
      _processing  = true;
      if (names.isNotEmpty) _names = names;
    });
  }

  void _close() {
    Navigator.of(context).pop(SkyScannerResult(
      detectedStars:       _stars,
      engineConfidence:    _confidence,
      imuDrift:            _imuDrift,
      horizonDetected:     _horizon,
      horizonAngle:        _horizonAngle,
      identifiedStarNames: _names,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.service.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──────────────────────────────────────────────
          if (ctrl != null && ctrl.value.isInitialized)
            CameraPreview(ctrl)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Top bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'DS-1  Sky Scanner',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    if (_processing)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _blurred ? Colors.orange : Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom stats panel ──────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Star count + confidence row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(
                          icon: Icons.star,
                          label: 'Stars',
                          value: '$_stars',
                          color: _stars >= 3 ? Colors.greenAccent : Colors.white70,
                        ),
                        _Stat(
                          icon: Icons.speed,
                          label: 'Engine',
                          value: '${_confidence.toStringAsFixed(0)}%',
                          color: _confidence >= 60
                              ? Colors.greenAccent
                              : _confidence >= 30
                                  ? Colors.amberAccent
                                  : Colors.white70,
                        ),
                        _Stat(
                          icon: Icons.rotate_right,
                          label: 'Drift',
                          value: '${_imuDrift.toStringAsFixed(2)}°/s',
                          color: _imuDrift < 0.5 ? Colors.greenAccent : Colors.redAccent,
                        ),
                        _Stat(
                          icon: Icons.linear_scale,
                          label: 'Horizon',
                          value: _horizon
                              ? '${_horizonAngle.toStringAsFixed(1)}°'
                              : '—',
                          color: _horizon ? Colors.greenAccent : Colors.white54,
                        ),
                      ],
                    ),

                    // Motion blur warning
                    if (_blurred) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orangeAccent, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Motion blur — hold steady',
                            style: TextStyle(
                                color: Colors.orangeAccent, fontSize: 12),
                          ),
                        ],
                      ),
                    ],

                    // Identified star chips
                    if (_names.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _names.map((n) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              n,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Done — Return to DS-1'),
                        onPressed: _close,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small stat tile used in the overlay ─────────────────────────────────────

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
