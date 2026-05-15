import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
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
  static const double confidenceThreshold = 0.35;
  // When detector score >= 0.18 (non-photographic content, logos, people),
  // require higher classifier confidence — rejects non-fish that the classifier
  // mislabels with moderate confidence (0.45–0.60).
  static const double _detectorAmbiguousThreshold = 0.18;
  static const double _ambiguousZoneMinConfidence = 0.65;
  static const double _minimumTopClassMargin = 0.05;
  static const Map<String, double> _classThresholds = {
    'Gilt-Head Bream': 0.35,
    'Horse Mackerel': 0.35,
    'Red Mullet': 0.35,
    'Sea Bass': 0.35,
    'Shrimp': 0.35,
  };

  // Mapping of English class names to Arabic names
  static const Map<String, String> _arabicNames = {
    'Gilt-Head Bream': 'دنيس',
    'Horse Mackerel': 'سكمبري',
    'Hourse Mackerel': 'سكمبري',
    'Red Mullet': 'بربوني',
    'Sea Bass': 'قاروص',
    'Shrimp': 'روبيان',
  };

  FishClassification({
    required this.className,
    required this.confidence,
    required this.detectorScore,
    required this.status,
    required this.timestamp,
  });

  // Get Arabic name for the fish class
  String get arabicName => _arabicNames[className] ?? className;

  double get threshold => _classThresholds[className] ?? confidenceThreshold;
  bool get isFishDetected => status != FishRecognitionStatus.noFish;
  bool get isConfident => status == FishRecognitionStatus.supportedFish;
  bool get isUnknown => status != FishRecognitionStatus.supportedFish;
  bool get isUnsupported => status == FishRecognitionStatus.unsupportedFish;
  bool get isNoFish => status == FishRecognitionStatus.noFish;

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

/// TensorFlow Lite model service for fish classification
class FishClassifierService {
  Interpreter? _classifierInterpreter;
  Interpreter? _detectorInterpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  static const String _classifierModelPath =
      'assets/models/fish_classifier.tflite';
  static const String _detectorModelPath = 'assets/models/fish_detector.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 260;

  /// Initialize the classifier
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((label) => _normalizeModelLabel(label.trim()))
          .where((label) => label.isNotEmpty)
          .toList();

      // Load TFLite models
      _detectorInterpreter = await Interpreter.fromAsset(_detectorModelPath);
      _classifierInterpreter =
          await Interpreter.fromAsset(_classifierModelPath);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Error initializing FishClassifierService: $e');
    }
  }

  /// Check if classifier is initialized
  bool get isInitialized => _isInitialized;

  String _normalizeModelLabel(String label) {
    return switch (label) {
      'Hourse Mackerel' => 'Horse Mackerel',
      _ => label,
    };
  }

  /// Classify image from file
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

  /// Classify from image bytes (e.g., from camera)
  Future<FishClassification> classifyImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('Classifier not initialized. Call initialize() first.');
    }

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw Exception('Failed to decode image.');

      final input = _preprocessImage(decoded);
      final detectorScore = _detectFish(input);

      // Output shape: [1, numClasses]
      final numClasses = _labels!.length;
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

      _classifierInterpreter!.run(input, output);

      final scores = output[0];
      final rankedIndexes = List<int>.generate(scores.length, (index) => index)
        ..sort((a, b) => scores[b].compareTo(scores[a]));
      final bestIndex = rankedIndexes.first;
      final confidence = scores[bestIndex];
      final runnerUpConfidence =
          rankedIndexes.length > 1 ? scores[rankedIndexes[1]] : 0.0;
      final topClassMargin = confidence - runnerUpConfidence;
      final predictedClassName = _labels![bestIndex];
      final classThreshold =
          FishClassification._classThresholds[predictedClassName] ??
              FishClassification.confidenceThreshold;
      developer.log(
        'detector=$detectorScore  top=$predictedClassName  conf=${confidence.toStringAsFixed(3)}  margin=${topClassMargin.toStringAsFixed(3)}  threshold=$classThreshold',
        name: 'FishClassifier',
      );
      final effectiveConfidenceThreshold =
          detectorScore >= FishClassification._detectorAmbiguousThreshold
              ? FishClassification._ambiguousZoneMinConfidence
              : classThreshold;
      final isClearSupportedSpecies =
          confidence >= effectiveConfidenceThreshold &&
              topClassMargin >= FishClassification._minimumTopClassMargin;
      final status =
          !isClearSupportedSpecies
              ? FishRecognitionStatus.noFish
              : FishRecognitionStatus.supportedFish;
      final className = switch (status) {
        FishRecognitionStatus.supportedFish => predictedClassName,
        FishRecognitionStatus.unsupportedFish => 'Unsupported species',
        FishRecognitionStatus.noFish => 'No fish detected',
      };

      return FishClassification(
        className: className,
        confidence: confidence,
        detectorScore: detectorScore,
        status: status,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  double _detectFish(List<List<List<List<double>>>> input) {
    final output = List.generate(1, (_) => List.filled(1, 0.0));
    _detectorInterpreter!.run(input, output);
    return output[0][0];
  }

  /// Preprocess image to model input format.
  /// No normalization - model expects raw pixel values [0, 255]
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );

    // Shape: [1, 224, 224, 3]
    final input = List.generate(
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

    return input;
  }

  /// Get all class labels
  List<String> get labels => List.unmodifiable(_labels ?? []);

  /// Get model input size
  int get inputSize => _inputSize;

  /// Dispose resources
  void dispose() {
    _classifierInterpreter?.close();
    _detectorInterpreter?.close();
    _classifierInterpreter = null;
    _detectorInterpreter = null;
    _isInitialized = false;
  }
}
