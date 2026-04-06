import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// ── Return-code constants (mirror vision_engine.h) ────────────────────────────
const int kDs1Ok         =  0;
const int kDs1Rejected   = -1;
const int kDs1NoGpu      = -2;
const int kDs1NotInit    = -3;
const int kDs1BadArg     = -4;

// ── Max stars per frame ───────────────────────────────────────────────────────
const int kDs1MaxStars = 50;

// ─────────────────────────────────────────────────────────────────────────────
// Native function typedefs
// ─────────────────────────────────────────────────────────────────────────────

// int init_vision_engine(int w, int h, double focal_mm, double sensor_mm)
typedef _InitNative = Int32 Function(Int32, Int32, Double, Double);
typedef _InitDart   = int   Function(int,  int,  double, double);

// int detect_stars(uint8_t*, int, int, double*, double*)
typedef _DetectStarsNative = Int32 Function(
    Pointer<Uint8>, Int32, Int32, Pointer<Double>, Pointer<Double>);
typedef _DetectStarsDart = int Function(
    Pointer<Uint8>, int, int, Pointer<Double>, Pointer<Double>);

// int detect_horizon(uint8_t*, int, int, double*, double*)
typedef _DetectHorizonNative = Int32 Function(
    Pointer<Uint8>, Int32, Int32, Pointer<Double>, Pointer<Double>);
typedef _DetectHorizonDart = int Function(
    Pointer<Uint8>, int, int, Pointer<Double>, Pointer<Double>);

// double get_last_processing_confidence()
typedef _ConfNative = Double Function();
typedef _ConfDart   = double Function();

// void shutdown_vision_engine()
typedef _ShutdownNative = Void Function();
typedef _ShutdownDart   = void Function();

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

class StarCentroid {
  final double x;
  final double y;
  const StarCentroid(this.x, this.y);
  @override
  String toString() => 'Star(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

class StarDetectionResult {
  /// Null = engine error or frame structurally invalid.
  /// Empty list = valid frame, no stars found.
  final List<StarCentroid>? stars;

  /// True when the C++ engine explicitly rejected the frame
  /// (waves, horizon too low, overexposure).
  final bool frameRejected;

  /// Human-readable failure reason — non-empty only on error/rejection.
  final String reason;

  const StarDetectionResult({
    required this.stars,
    required this.frameRejected,
    required this.reason,
  });

  bool get hasStars => stars != null && stars!.isNotEmpty;
}

class HorizonResult {
  /// Degrees of tilt from level (0 = perfectly level horizon).
  final double? angleDeg;

  /// Signed pixel offset from frame centre (positive = horizon above centre).
  final double? offsetPx;

  /// Rejection reason when [angleDeg] is null.
  final String reason;

  const HorizonResult({this.angleDeg, this.offsetPx, this.reason = ''});
  bool get detected => angleDeg != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory pool — pre-allocated native buffers reused every frame
// ─────────────────────────────────────────────────────────────────────────────

class _FramePool {
  final int frameBytes;          // width * height * 3 (RGB-888)
  late final Pointer<Uint8>  pixels;
  late final Pointer<Double> starX;
  late final Pointer<Double> starY;
  late final Pointer<Double> scalarA; // horizon angle / generic scalar
  late final Pointer<Double> scalarB; // horizon offset / generic scalar
  bool _disposed = false;

  _FramePool(int width, int height)
      : frameBytes = width * height * 3 {
    pixels  = calloc<Uint8>(frameBytes);
    starX   = calloc<Double>(kDs1MaxStars);
    starY   = calloc<Double>(kDs1MaxStars);
    scalarA = calloc<Double>(1);
    scalarB = calloc<Double>(1);

    if (pixels == nullptr || starX == nullptr || starY == nullptr ||
        scalarA == nullptr || scalarB == nullptr) {
      _free();
      throw StateError(
          'DS-1 VisionBridge: native memory pool allocation failed '
          '(need ≈${(frameBytes / 1024 / 1024).toStringAsFixed(1)} MB).');
    }
  }

  /// Zero-copy transfer of [frame] into native pixel buffer.
  void loadFrame(Uint8List frame) {
    if (frame.length != frameBytes) {
      throw ArgumentError(
          'Frame has ${frame.length} bytes, expected $frameBytes.');
    }
    pixels.asTypedList(frameBytes).setAll(0, frame);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _free();
  }

  void _free() {
    calloc.free(pixels);
    calloc.free(starX);
    calloc.free(starY);
    calloc.free(scalarA);
    calloc.free(scalarB);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VisionBridge — public API
// ─────────────────────────────────────────────────────────────────────────────

/// Dart-side wrapper around the DS-1 C++ vision engine.
///
/// Lifecycle:
///   1. Call [loadLibrary] once at app start.
///   2. Call [init] with camera parameters.
///   3. Call [detectStars] / [detectHorizon] per frame.
///   4. Call [shutdown] when the camera session ends.
///
/// All methods are safe to call from a background [Isolate].
/// [loadLibrary] and [shutdown] must be called from the same isolate as [init].
class VisionBridge {
  VisionBridge._();
  static final instance = VisionBridge._();

  bool _loaded   = false;
  bool _ready    = false;
  _FramePool? _pool;

  late final _InitDart          _init;
  late final _DetectStarsDart   _detectStars;
  late final _DetectHorizonDart _detectHorizon;
  late final _ConfDart          _getConfidence;
  late final _ShutdownDart      _shutdown;

  // ── Library loading ─────────────────────────────────────────────────────────

  /// Load the native shared library.
  ///
  /// Returns `null` on success.
  /// Returns a human-readable error string if the library cannot be loaded
  /// (e.g. missing .so, wrong ABI).  The app must degrade gracefully.
  String? loadLibrary() {
    if (_loaded) return null;
    try {
      final lib = DynamicLibrary.open(_libraryName());

      _init = lib
          .lookup<NativeFunction<_InitNative>>('init_vision_engine')
          .asFunction<_InitDart>();

      _detectStars = lib
          .lookup<NativeFunction<_DetectStarsNative>>('detect_stars')
          .asFunction<_DetectStarsDart>();

      _detectHorizon = lib
          .lookup<NativeFunction<_DetectHorizonNative>>('detect_horizon')
          .asFunction<_DetectHorizonDart>();

      _getConfidence = lib
          .lookup<NativeFunction<_ConfNative>>('get_last_processing_confidence')
          .asFunction<_ConfDart>();

      _shutdown = lib
          .lookup<NativeFunction<_ShutdownNative>>('shutdown_vision_engine')
          .asFunction<_ShutdownDart>();

      _loaded = true;
      return null;
    } catch (e) {
      return 'DS-1: Failed to load vision library: $e';
    }
  }

  // ── Init / shutdown ─────────────────────────────────────────────────────────

  /// Initialise the vision engine with camera parameters.
  ///
  /// Returns `null` on success, or a human-readable error string.
  /// Error codes:
  ///   kDs1NoGpu (-2) → GPU not available on this device.
  ///   kDs1BadArg(-4) → invalid dimensions or focal length.
  String? init({
    required int    width,
    required int    height,
    required double focalLengthMm,
    required double sensorWidthMm,
  }) {
    if (!_loaded) return 'DS-1: call loadLibrary() before init().';

    final rc = _init(width, height, focalLengthMm, sensorWidthMm);
    if (rc == kDs1NoGpu) {
      return 'DS-1: GPU (OpenCL) not available on this device. '
          'Vision engine cannot run.';
    }
    if (rc == kDs1BadArg) {
      return 'DS-1: Invalid camera parameters '
          '(${width}x$height focal=${focalLengthMm}mm sensor=${sensorWidthMm}mm).';
    }
    if (rc != kDs1Ok) {
      return 'DS-1: init returned unexpected code $rc.';
    }

    // Allocate the native memory pool now that we know the frame size
    _pool?.dispose();
    try {
      _pool = _FramePool(width, height);
    } catch (e) {
      return e.toString();
    }

    _ready = true;
    return null;
  }

  void shutdown() {
    if (!_loaded) return;
    _shutdown();
    _pool?.dispose();
    _pool = null;
    _ready = false;
  }

  // ── Per-frame API ───────────────────────────────────────────────────────────

  /// Detect star centroids in one RGB-888 frame.
  ///
  /// [frame] must be exactly `width * height * 3` bytes, RGB-888.
  ///
  /// Returns a [StarDetectionResult] — never throws.
  StarDetectionResult detectStars(Uint8List frame, int width, int height) {
    if (!_ready || _pool == null) {
      return const StarDetectionResult(
        stars: null,
        frameRejected: false,
        reason: 'Vision engine not initialised.',
      );
    }

    try {
      _pool!.loadFrame(frame);
    } catch (e) {
      return StarDetectionResult(
        stars: null,
        frameRejected: false,
        reason: 'Frame size mismatch: $e',
      );
    }

    // sentinel: C++ must overwrite (value < 0 = rejected)
    final rc = _detectStars(
      _pool!.pixels,
      width,
      height,
      _pool!.starX,
      _pool!.starY,
    );

    if (rc == kDs1Rejected) {
      return const StarDetectionResult(
        stars: [],
        frameRejected: true,
        reason: 'Frame rejected by vision engine (waves / horizon / overexposure).',
      );
    }
    if (rc < 0) {
      return StarDetectionResult(
        stars: null,
        frameRejected: false,
        reason: 'detect_stars() error code $rc.',
      );
    }

    // rc == number of stars (0..DS1_MAX_STARS)
    final stars = List<StarCentroid>.generate(
      rc,
      (i) => StarCentroid(_pool!.starX[i], _pool!.starY[i]),
      growable: false,
    );

    return StarDetectionResult(
      stars: stars,
      frameRejected: false,
      reason: '',
    );
  }

  /// Detect the horizon in one RGB-888 frame.
  HorizonResult detectHorizon(Uint8List frame, int width, int height) {
    if (!_ready || _pool == null) {
      return const HorizonResult(reason: 'Vision engine not initialised.');
    }

    try {
      _pool!.loadFrame(frame);
    } catch (e) {
      return HorizonResult(reason: 'Frame size mismatch: $e');
    }

    final rc = _detectHorizon(
      _pool!.pixels,
      width,
      height,
      _pool!.scalarA, // angle_deg
      _pool!.scalarB, // offset_px
    );

    if (rc == kDs1Rejected) {
      return const HorizonResult(
        reason: 'Horizon rejected: wave variance > 10% or in 8° forbidden zone.',
      );
    }
    if (rc < 0) {
      return HorizonResult(reason: 'detect_horizon() error code $rc.');
    }

    return HorizonResult(
      angleDeg: _pool!.scalarA.value,
      offsetPx: _pool!.scalarB.value,
    );
  }

  /// Last confidence score (0–100) computed by the C++ engine.
  double get lastConfidence => _ready ? _getConfidence() : 0.0;

  bool get isReady => _ready;

  // ── Internal ────────────────────────────────────────────────────────────────

  static String _libraryName() {
    if (Platform.isAndroid) return 'libds1_vision.so';
    if (Platform.isIOS)     return 'ds1_vision.framework/ds1_vision';
    throw UnsupportedError(
        'DS-1 vision engine is not supported on ${Platform.operatingSystem}.');
  }
}
