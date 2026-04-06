import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/navigation/confidence_engine.dart';

/// A computed celestial position fix produced by the DS-1 screen.
class CelestialFix {
  final LatLng position;
  final int confidenceScore;
  final FixDecision decision;

  /// Uncertainty radius in nautical miles (1–5 NM).
  final double uncertaintyNm;
  final DateTime timestamp;

  const CelestialFix({
    required this.position,
    required this.confidenceScore,
    required this.decision,
    required this.uncertaintyNm,
    required this.timestamp,
  });
}

/// Singleton ChangeNotifier that carries the latest DS-1 fix and spoofing
/// alert state. IntegratedMap listens to this without needing Riverpod.
class CelestialFixNotifier extends ChangeNotifier {
  CelestialFixNotifier._();
  static final instance = CelestialFixNotifier._();

  CelestialFix? _fix;
  bool _spoofingAlert = false;

  CelestialFix? get fix => _fix;
  bool get spoofingAlert => _spoofingAlert;

  void setFix(CelestialFix fix, {bool spoofingAlert = false}) {
    _fix = fix;
    _spoofingAlert = spoofingAlert;
    notifyListeners();
  }

  void clearFix() {
    _fix = null;
    _spoofingAlert = false;
    notifyListeners();
  }
}
