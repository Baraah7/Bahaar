import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

enum FishRecognitionStatus {
  supportedFish,
  unsupportedFish,
  noFish,
}

class FishClassification {
  final String className;
  final double confidence;
  final double detectorScore;
  final FishRecognitionStatus status;
  final DateTime timestamp;

  // A real fish species produces a peaked distribution (low entropy).
  // Non-fish images produce flat distributions (high entropy).
  // Measured on real data: fish entropy 0.14–0.69, non-fish 0.99–1.35.
  static const double _maxFishEntropy = 0.85;
  static const double _minMargin = 0.25;
  static const double confidenceThreshold = 0.60;

  static const Map<String, double> _classThresholds = {
    'Gilt-Head Bream': 0.60,
    'Horse Mackerel':  0.60,
    'Red Mullet':      0.60,
    'Sea Bass':        0.60,
    'Shrimp':          0.60,
  };

  static const Map<String, String> _arabicNames = {
    'Gilt-Head Bream': 'شعري',
    'Horse Mackerel':  'جنيسة',
    'Hourse Mackerel': 'جنيسة',
    'Red Mullet':      'حومر',
    'Sea Bass':        'سيباس',
    'Shrimp':          'روبيان',
  };

  FishClassification({
    required this.className,
    required this.confidence,
    required this.detectorScore,
    required this.status,
    required this.timestamp,
  });

  String get arabicName => _arabicNames[className] ?? className;
  double get threshold => _classThresholds[className] ?? confidenceThreshold;
  bool get isFishDetected => status != FishRecognitionStatus.noFish;
  bool get isConfident => status == FishRecognitionStatus.supportedFish;
  bool get isUnknown => status != FishRecognitionStatus.supportedFish;
  bool get isUnsupported => status == FishRecognitionStatus.unsupportedFish;
  bool get isNoFish => status == FishRecognitionStatus.noFish;

  // Expose thresholds for use in service
  static double get maxFishEntropy => _maxFishEntropy;
  static double get minMargin => _minMargin;

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'detectorScore': detectorScore,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FishClassifierService {
  Interpreter? _classifierInterpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  static const String _classifierModelPath = 'assets/models/fish_classifier.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  // EfficientNetB0 trained at 260×260, raw [0, 255]
  static const int _inputSize = 260;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((label) => _normalizeLabel(label.trim()))
          .where((label) => label.isNotEmpty)
          .toList();

      final options = InterpreterOptions()..threads = 2;
      _classifierInterpreter = await Interpreter.fromAsset(
        _classifierModelPath,
        options: options,
      );

      developer.log(
        'Classifier loaded — ${_labels!.length} classes: $_labels',
        name: 'FishClassifier',
      );

      _isInitialized = true;
    } catch (e) {
      throw Exception('Error initializing FishClassifierService: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  String _normalizeLabel(String label) {
    return switch (label) {
      'Hourse Mackerel' => 'Horse Mackerel',
      _ => label,
    };
  }

  Future<FishClassification?> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('FishClassifierService is not initialized.');
    }
    try {
      final bytes = await imageFile.readAsBytes();
      return classifyImageBytes(bytes);
    } catch (e) {
      throw Exception('Error classifying image: $e');
    }
  }

  Future<FishClassification> classifyImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('Classifier not initialized. Call initialize() first.');
    }

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw Exception('Failed to decode image.');
      if (_classifierInterpreter == null) throw Exception('Classifier failed to load.');

      final input = _preprocess(decoded);
      final numClasses = _labels!.length;
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));
      _classifierInterpreter!.run(input, output);

      final scores = output[0];
      final ranked = List<int>.generate(scores.length, (i) => i)
        ..sort((a, b) => scores[b].compareTo(scores[a]));

      final bestIdx    = ranked.first;
      final confidence = scores[bestIdx];
      final runnerUp   = ranked.length > 1 ? scores[ranked[1]] : 0.0;
      final margin     = confidence - runnerUp;
      final predicted  = _labels![bestIdx];

      // Entropy of the softmax distribution — low for peaked (fish), high for flat (non-fish).
      final entropy = -scores.fold<double>(
        0.0,
        (sum, s) => sum + (s > 0 ? s * math.log(s) : 0.0),
      );

      developer.log(
        'top=$predicted  conf=${confidence.toStringAsFixed(3)}  '
        'margin=${margin.toStringAsFixed(3)}  entropy=${entropy.toStringAsFixed(3)}  '
        'allScores=${scores.map((s) => s.toStringAsFixed(3)).toList()}',
        name: 'FishClassifier',
      );

      // Non-fish images produce flat distributions with high entropy and low margin.
      final looksLikeNotFish = entropy > FishClassification.maxFishEntropy
          || margin < FishClassification.minMargin;

      if (looksLikeNotFish) {
        developer.log(
          'Rejected as non-fish (entropy=$entropy margin=$margin)',
          name: 'FishClassifier',
        );
        return FishClassification(
          className: 'No fish detected',
          confidence: confidence,
          detectorScore: confidence,
          status: FishRecognitionStatus.noFish,
          timestamp: DateTime.now(),
        );
      }

      final classThreshold = FishClassification._classThresholds[predicted]
          ?? FishClassification.confidenceThreshold;
      final isRecognized = confidence >= classThreshold;

      final status = isRecognized
          ? FishRecognitionStatus.supportedFish
          : FishRecognitionStatus.unsupportedFish;

      final className = switch (status) {
        FishRecognitionStatus.supportedFish   => predicted,
        FishRecognitionStatus.unsupportedFish => 'Unsupported species',
        FishRecognitionStatus.noFish          => 'No fish detected',
      };

      return FishClassification(
        className:     className,
        confidence:    confidence,
        detectorScore: confidence,
        status:        status,
        timestamp:     DateTime.now(),
      );
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  /// Resize to 260×260, raw [0, 255] to match EfficientNetB0 training.
  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
            ];
          },
        ),
      ),
    );
  }

  List<String> get labels => List.unmodifiable(_labels ?? []);
  int get inputSize => _inputSize;

  void dispose() {
    _classifierInterpreter?.close();
    _classifierInterpreter = null;
    _isInitialized = false;
  }
}
