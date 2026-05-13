import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FishClassification {
  final String className;
  final double confidence;
  final DateTime timestamp;
  static const double confidenceThreshold = 0.70;
  final double threshold = confidenceThreshold;
  static const double _unknownThreshold = confidenceThreshold;

  // Mapping of English class names to Arabic names
  static const Map<String, String> _arabicNames = {
    'Gilt Head Bream': 'دنيس',
    'Horse Mackerel': 'سكمبري',
    'Red Mullet': 'بربوني',
    'Sea Bass': 'قاروص',
    'Shrimp': 'روبيان',
  };

  FishClassification({
    required this.className,
    required this.confidence,
    required this.timestamp,
  });

  // Get Arabic name for the fish class
  String get arabicName => _arabicNames[className] ?? className;

  bool get isConfident => confidence >= threshold;
  bool get isUnknown => confidence < _unknownThreshold;

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// TensorFlow Lite model service for fish classification
class FishClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  static const String _modelPath = 'assets/models/fish_classifier.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;

  /// Initialize the classifier
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Error initializing FishClassifierService: $e');
    }
  }

  /// Check if classifier is initialized
  bool get isInitialized => _isInitialized;

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

      // Output shape: [1, numClasses]
      final numClasses = _labels!.length;
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

      _interpreter!.run(input, output);

      final scores = output[0];
      final bestIndex = scores.indexOf(scores.reduce(max));
      final confidence = scores[bestIndex];
      final className = confidence < FishClassification.confidenceThreshold
          ? 'Unknown / Not a fish'
          : _labels![bestIndex];

      return FishClassification(
        className: className,
        confidence: confidence,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  /// Preprocess image to model input format.
  /// Normalization: (pixel / 127.5) - 1.0  →  range [-1, 1]
  /// Must match the training preprocessing used in the notebook.
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
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
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
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}