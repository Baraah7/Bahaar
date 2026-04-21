import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'vision_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simulation helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-baked synthetic star centroids (pixel coords for a 1920×1080 frame).
/// Positions are spread across the frame in a realistic constellation-like
/// pattern so the StarIdentifier triangle matcher can exercise real code paths.
const List<StarCentroid> _kSimStars = [
  StarCentroid( 960.0,  540.0),   // frame centre
  StarCentroid(1120.0,  380.0),
  StarCentroid( 780.0,  420.0),
  StarCentroid(1050.0,  680.0),
  StarCentroid( 650.0,  600.0),
  StarCentroid(1300.0,  490.0),
  StarCentroid( 500.0,  350.0),
  StarCentroid(1450.0,  720.0),
  StarCentroid( 400.0,  730.0),
  StarCentroid(1200.0,  250.0),
  StarCentroid( 820.0,  820.0),
  StarCentroid(1550.0,  310.0),
];

// ── Tuning constants (from blueprint) ────────────────────────────────────────
const Duration _kBurstDuration  = Duration(seconds: 1);
const Duration _kCoolDuration   = Duration(seconds: 1);
const double   _kMaxGyroDegPerSec = 0.5;   // frames with faster motion rejected
const int      _kTargetWidth    = 1920;
const int      _kTargetHeight   = 1080;

// ── Camera default focal / sensor parameters ─────────────────────────────────
// These are populated by the user during calibration (auto-calibration via
// Polaris + Ursa Major).  Defaults are typical mid-range phone values and
// will give ≈ correct results until calibration is run.
const double _kDefaultFocalMm   = 4.25;   // typical 1x camera
const double _kDefaultSensorMm  = 6.17;   // 1/2.55" sensor width

// ─────────────────────────────────────────────────────────────────────────────
// IMU frame tag — attached to every captured image
// ─────────────────────────────────────────────────────────────────────────────

class ImuTag {
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final DateTime timestamp;

  const ImuTag({
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });

  /// Magnitude of rotation rate in °/s.
  double get driftDegPerSec {
    final sumSq = gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ;
    return math.sqrt(sumSq) * (180.0 / math.pi);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Processed frame result (sent back to UI)
// ─────────────────────────────────────────────────────────────────────────────

class CameraFrameResult {
  final StarDetectionResult stars;
  final HorizonResult       horizon;
  final double              engineConfidence; // 0–100 from C++ engine
  final ImuTag              imuTag;
  final bool                motionBlurred;   // gyro exceeded threshold
  final int                 frameWidth;
  final int                 frameHeight;

  const CameraFrameResult({
    required this.stars,
    required this.horizon,
    required this.engineConfidence,
    required this.imuTag,
    required this.motionBlurred,
    required this.frameWidth,
    required this.frameHeight,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CameraService
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the camera stream, duty cycling, gyroscope tagging, and
/// dispatching frames to the vision engine on a background isolate.
///
/// Usage:
///   final svc = CameraService();
///   final err = await svc.initialize();
///   if (err != null) { /* show "Vision engine unavailable" */ }
///   svc.results.listen((result) { ... });
///   await svc.startCapture();
///   // ... later ...
///   await svc.stopCapture();
///   svc.dispose();
class CameraService {
  CameraService();

  // ── Public state ────────────────────────────────────────────────────────────
  bool get isAvailable    => _cameraAvailable || _simMode;
  bool get isCapturing    => _capturing;
  String? get initError   => _initError;

  /// True when running in simulation mode (no real camera or native lib).
  bool get isSimulated => _simMode;

  /// Exposes the underlying [CameraController] so the UI can show a preview.
  /// Returns `null` before [initialize] completes successfully, or in sim mode.
  CameraController? get controller => _cameraCtrl;

  final _resultsController =
      StreamController<CameraFrameResult>.broadcast();

  /// Stream of processed frames.  Listen on the UI isolate.
  Stream<CameraFrameResult> get results => _resultsController.stream;

  // ── Private ─────────────────────────────────────────────────────────────────
  CameraController?  _cameraCtrl;
  bool               _cameraAvailable = false;
  bool               _capturing       = false;
  String?            _initError;
  bool               _simMode         = false;

  // IMU — latest gyroscope reading
  ImuTag _latestImu = ImuTag(
    gyroX: 0, gyroY: 0, gyroZ: 0,
    timestamp: DateTime.now(),
  );
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Duty-cycle state
  bool   _inBurst     = false;
  Timer? _dutyTimer;
  Timer? _simTimer;

  // ── Calibration parameters ───────────────────────────────────────────────────
  double _focalMm   = _kDefaultFocalMm;
  double _sensorMm  = _kDefaultSensorMm;

  /// Update camera calibration (called after user runs auto-calibration).
  void setCalibration({required double focalMm, required double sensorMm}) {
    _focalMm  = focalMm;
    _sensorMm = sensorMm;
  }

  /// Horizontal field of view in degrees derived from current calibration.
  double get fovHDeg =>
      2.0 * math.atan(_sensorMm / (2.0 * _focalMm)) * 180.0 / math.pi;

  // ── Initialization ──────────────────────────────────────────────────────────

  /// Initialize camera + vision engine.  Call before [startCapture].
  ///
  /// Returns `null` on success, or a human-readable error string.
  /// When a non-null string is returned the service is unusable;
  /// show 'Vision engine unavailable' to the user.
  Future<String?> initialize() async {
    // 1. Load the native library
    final libErr = VisionBridge.instance.loadLibrary();
    if (libErr != null) {
      _initError = libErr;
      return libErr;
    }

    // 2. Init the engine
    final initErr = VisionBridge.instance.init(
      width:          _kTargetWidth,
      height:         _kTargetHeight,
      focalLengthMm:  _focalMm,
      sensorWidthMm:  _sensorMm,
    );
    if (initErr != null) {
      _initError = initErr;
      return initErr;
    }

    // 3. Find a usable back camera
    final cameras = await availableCameras();
    final back = cameras.where(
      (c) => c.lensDirection == CameraLensDirection.back,
    ).toList();

    if (back.isEmpty) {
      _initError = 'DS-1: No rear camera found on this device.';
      return _initError;
    }

    // Prefer the widest-angle (lowest focal equiv) — better star field
    _cameraCtrl = CameraController(
      back.first,
      ResolutionPreset.veryHigh, // 1920×1080 on most devices
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // converted to RGB in service
    );

    try {
      await _cameraCtrl!.initialize();
    } catch (e) {
      _initError = 'DS-1: Camera init failed: $e';
      return _initError;
    }

    // 4. Subscribe to gyroscope
    _gyroSub = gyroscopeEventStream().listen((event) {
      _latestImu = ImuTag(
        gyroX:     event.x,
        gyroY:     event.y,
        gyroZ:     event.z,
        timestamp: DateTime.now(),
      );
    });

    _cameraAvailable = true;
    return null;
  }

  /// Enter simulation mode — no camera or native library needed.
  ///
  /// Fires synthetic [CameraFrameResult]s on a 2-second tick so the full
  /// pipeline (SkyScannerView → StarIdentifier → ConfidenceEngine) runs
  /// exactly as in production.  Call instead of [initialize] for testing.
  ///
  /// Always returns `null` (success).
  Future<String?> initSimulation() async {
    _simMode = true;
    _cameraAvailable = false; // no real camera
    return null;
  }

  // ── Capture control ─────────────────────────────────────────────────────────

  Future<void> startCapture() async {
    if ((!_cameraAvailable && !_simMode) || _capturing) return;
    _capturing = true;
    if (_simMode) {
      _startSimulation();
    } else {
      _startBurst();
    }
  }

  Future<void> stopCapture() async {
    if (!_capturing) return;
    _capturing = false;
    _simTimer?.cancel();
    _simTimer = null;
    _dutyTimer?.cancel();
    _dutyTimer = null;
    try {
      await _cameraCtrl?.stopImageStream();
    } catch (_) {}
    _inBurst = false;
  }

  void dispose() {
    stopCapture();
    _gyroSub?.cancel();
    _cameraCtrl?.dispose();
    if (!_simMode) VisionBridge.instance.shutdown();
    _resultsController.close();
  }

  // ── Simulation tick ───────────────────────────────────────────────────────────

  void _startSimulation() {
    // Emit one frame immediately, then every 2 seconds.
    _emitSimFrame();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_capturing) _emitSimFrame();
    });
  }

  void _emitSimFrame() {
    final imu = ImuTag(
      gyroX: 0.01, gyroY: 0.01, gyroZ: 0.00,
      timestamp: DateTime.now(),
    );

    _resultsController.add(CameraFrameResult(
      stars: StarDetectionResult(
        stars: _kSimStars,
        frameRejected: false,
        reason: '',
      ),
      horizon: const HorizonResult(
        angleDeg: 0.5,
        offsetPx: 8.0,
        reason: '',
      ),
      engineConfidence: 82.0,
      imuTag: imu,
      motionBlurred: false,
      frameWidth:  _kTargetWidth,
      frameHeight: _kTargetHeight,
    ));
  }

  // ── Duty cycling ─────────────────────────────────────────────────────────────

  void _startBurst() {
    if (!_capturing) return;
    _inBurst = true;

    _cameraCtrl!.startImageStream(_onFrame);

    // After 1 s burst → 1 s cool
    _dutyTimer = Timer(_kBurstDuration, () async {
      try { await _cameraCtrl?.stopImageStream(); } catch (_) {}
      _inBurst = false;

      if (!_capturing) return;
      _dutyTimer = Timer(_kCoolDuration, _startBurst);
    });
  }

  // ── Frame handler ────────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) {
    if (!_inBurst || !_capturing) return;

    // Snapshot the IMU at frame capture time
    final imu = _latestImu;

    // Reject motion-blurred frames immediately — no vision work needed
    if (imu.driftDegPerSec > _kMaxGyroDegPerSec) {
      _resultsController.add(CameraFrameResult(
        stars:            const StarDetectionResult(stars: [], frameRejected: true, reason: 'Motion blur: gyro > 0.5 °/s'),
        horizon:          const HorizonResult(reason: 'Skipped — motion blur'),
        engineConfidence: 0.0,
        imuTag:           imu,
        motionBlurred:    true,
        frameWidth:       image.width,
        frameHeight:      image.height,
      ));
      return;
    }

    // Convert YUV420 → RGB-888 on the calling isolate (lightweight)
    // Then dispatch vision work to a compute isolate to keep UI responsive.
    final rgb = _yuv420ToRgb888(image);
    if (rgb == null) return; // conversion failed — unsupported format

    // Run vision engine synchronously on this callback isolate.
    // The camera plugin already calls this on a background thread on Android.
    final starResult = VisionBridge.instance.detectStars(
        rgb, image.width, image.height);
    final horizResult = VisionBridge.instance.detectHorizon(
        rgb, image.width, image.height);

    _resultsController.add(CameraFrameResult(
      stars:            starResult,
      horizon:          horizResult,
      engineConfidence: VisionBridge.instance.lastConfidence,
      imuTag:           imu,
      motionBlurred:    false,
      frameWidth:       image.width,
      frameHeight:      image.height,
    ));
  }

  // ── YUV420 → RGB-888 conversion ──────────────────────────────────────────────

  /// Converts a [CameraImage] in YUV420 format to an RGB-888 [Uint8List].
  /// Returns null if the format is unexpected.
  static Uint8List? _yuv420ToRgb888(CameraImage image) {
    try {
      final int w = image.width;
      final int h = image.height;
      final rgb = Uint8List(w * h * 3);

      final yPlane  = image.planes[0];
      final uPlane  = image.planes[1];
      final vPlane  = image.planes[2];

      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      final int uvRowStride  = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 2;

      int rgbIdx = 0;
      for (int row = 0; row < h; row++) {
        for (int col = 0; col < w; col++) {
          final int yIdx = row * yPlane.bytesPerRow + col;
          final int uvRow = row ~/ 2;
          final int uvCol = col ~/ 2;
          final int uvIdx = uvRow * uvRowStride + uvCol * uvPixelStride;

          final int yVal = yBytes[yIdx];
          final int uVal = uBytes[uvIdx] - 128;
          final int vVal = vBytes[uvIdx] - 128;

          final int r = (yVal + 1.402   * vVal).round().clamp(0, 255);
          final int g = (yVal - 0.34414 * uVal - 0.71414 * vVal).round().clamp(0, 255);
          final int b = (yVal + 1.772   * uVal).round().clamp(0, 255);

          rgb[rgbIdx++] = r;
          rgb[rgbIdx++] = g;
          rgb[rgbIdx++] = b;
        }
      }
      return rgb;
    } catch (e) {
      debugPrint('DS-1 YUV→RGB failed: $e');
      return null;
    }
  }
}
