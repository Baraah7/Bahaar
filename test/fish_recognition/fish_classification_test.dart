import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/services/fishRecognition/fish_classifier_service.dart';
import 'package:bahaar/providers/fish%20recognition/fish_classification_provider.dart';

// // ── Helpers ──────────────────────────────────────────────────────────────────

FishClassification makeResult({
  String className = 'Sea Bass',
  double confidence = 0.85,
  double detectorScore = 0.01,
  FishRecognitionStatus status = FishRecognitionStatus.supportedFish,
}) =>
    FishClassification(
      className: className,
      confidence: confidence,
      detectorScore: detectorScore,
      status: status,
      timestamp: DateTime(2026, 4, 22, 10, 0),
    );

void main() {
  // ── FishClassification — status helpers ──────────────────────────────────────

  group('FishClassification.isConfident', () {
    test('returns true for supportedFish status', () {
      expect(
        makeResult(status: FishRecognitionStatus.supportedFish).isConfident,
        isTrue,
      );
    });

    test('returns false for noFish status', () {
      expect(
        makeResult(status: FishRecognitionStatus.noFish).isConfident,
        isFalse,
      );
    });

    test('returns false for unsupportedFish status', () {
      expect(
        makeResult(status: FishRecognitionStatus.unsupportedFish).isConfident,
        isFalse,
      );
    });
  });

  group('FishClassification.isUnknown', () {
    test('returns true when status is not supportedFish', () {
      expect(
        makeResult(status: FishRecognitionStatus.noFish).isUnknown,
        isTrue,
      );
      expect(
        makeResult(status: FishRecognitionStatus.unsupportedFish).isUnknown,
        isTrue,
      );
    });

    test('returns false when status is supportedFish', () {
      expect(
        makeResult(status: FishRecognitionStatus.supportedFish).isUnknown,
        isFalse,
      );
    });
  });

  group('FishClassification.isNoFish', () {
    test('returns true only for noFish status', () {
      expect(makeResult(status: FishRecognitionStatus.noFish).isNoFish, isTrue);
      expect(makeResult(status: FishRecognitionStatus.supportedFish).isNoFish, isFalse);
      expect(makeResult(status: FishRecognitionStatus.unsupportedFish).isNoFish, isFalse);
    });
  });

  group('FishClassification.isFishDetected', () {
    test('returns false only for noFish status', () {
      expect(makeResult(status: FishRecognitionStatus.noFish).isFishDetected, isFalse);
      expect(makeResult(status: FishRecognitionStatus.supportedFish).isFishDetected, isTrue);
      expect(makeResult(status: FishRecognitionStatus.unsupportedFish).isFishDetected, isTrue);
    });
  });

//   // ── FishClassification — arabicName ─────────────────────────────────────────

//   group('FishClassification.arabicName', () {
//     test('returns correct Arabic name for Gilt-Head Bream', () {
//       expect(makeResult(className: 'Gilt-Head Bream').arabicName, 'دنيس');
//     });

//     test('returns correct Arabic name for Sea Bass', () {
//       expect(makeResult(className: 'Sea Bass').arabicName, 'قاروص');
//     });

//     test('returns correct Arabic name for Shrimp', () {
//       expect(makeResult(className: 'Shrimp').arabicName, 'روبيان');
//     });

//     test('returns correct Arabic name for Hourse Mackerel (model key)', () {
//       expect(makeResult(className: 'Hourse Mackerel').arabicName, 'سكمبري');
//     });

//     test('falls back to className for unknown species', () {
//       const unknown = 'Zubaidi';
//       expect(makeResult(className: unknown).arabicName, unknown);
//     });
//   });

//   // ── FishClassification — toJson ──────────────────────────────────────────────

  group('FishClassification.toJson', () {
    test('serializes className, confidence, detectorScore, status and timestamp', () {
      final ts = DateTime(2026, 4, 22, 10, 0);
      final result = FishClassification(
        className: 'Sea Bass',
        confidence: 0.87,
        detectorScore: 0.02,
        status: FishRecognitionStatus.supportedFish,
        timestamp: ts,
      );
      final json = result.toJson();

      expect(json['className'], 'Sea Bass');
      expect(json['confidence'], closeTo(0.87, 0.0001));
      expect(json['detectorScore'], closeTo(0.02, 0.0001));
      expect(json['status'], 'supportedFish');
      expect(json['timestamp'], ts.toIso8601String());
    });

//     test('timestamp serializes as ISO 8601 string', () {
//       final result = makeResult();
//       final ts = result.toJson()['timestamp'] as String;
//       expect(() => DateTime.parse(ts), returnsNormally);
//     });
//   });

//   // ── FishClassificationState — initial state ──────────────────────────────────

//   group('FishClassificationState — initial state', () {
//     test('default state has no result, error, or loading', () {
//       const state = FishClassificationState();
//       expect(state.result, isNull);
//       expect(state.error, isNull);
//       expect(state.isLoading, isFalse);
//       expect(state.isInitialized, isFalse);
//     });
//   });

//   // ── FishClassificationState.copyWith ────────────────────────────────────────

//   group('FishClassificationState.copyWith', () {
//     test('isLoading updates independently', () {
//       const s = FishClassificationState();
//       expect(s.copyWith(isLoading: true).isLoading, isTrue);
//       expect(s.copyWith(isLoading: false).isLoading, isFalse);
//     });

//     test('isInitialized updates independently', () {
//       const s = FishClassificationState();
//       expect(s.copyWith(isInitialized: true).isInitialized, isTrue);
//     });

//     test('result updates when provided', () {
//       const s = FishClassificationState();
//       final r = makeResult();
//       expect(s.copyWith(result: r).result, same(r));
//     });

//     test('unmodified fields are preserved', () {
//       final r = makeResult();
//       final s = FishClassificationState(result: r, isInitialized: true);
//       final copy = s.copyWith(isLoading: true);
//       expect(copy.result, same(r));
//       expect(copy.isInitialized, isTrue);
//     });

//     test('error updates when provided', () {
//       const s = FishClassificationState();
//       expect(s.copyWith(error: 'oops').error, 'oops');
//     });

//     test('clearError=true removes existing error regardless of error param', () {
//       const s = FishClassificationState(error: 'previous error');
//       expect(s.copyWith(clearError: true).error, isNull);
//     });

//     test('clearError=true overrides a simultaneously provided error string', () {
//       const s = FishClassificationState(error: 'old');
//       final copy = s.copyWith(error: 'new', clearError: true);
//       expect(copy.error, isNull);
//     });

//     test('clearError=false (default) preserves existing error', () {
//       const s = FishClassificationState(error: 'kept');
//       expect(s.copyWith(isLoading: true).error, 'kept');
//     });

    test('result cannot be cleared to null via copyWith — use clearResult()', () {
      final r = makeResult();
      final s = FishClassificationState(result: r, isInitialized: true);
      final copy = s.copyWith(isLoading: false);
      expect(copy.result, same(r));
    });
  });

//   // ── FishClassificationNotifier.clearResult ───────────────────────────────────


//   group('FishClassificationNotifier.clearResult preserves isInitialized', () {
//     test('clearResult resets result and error but keeps isInitialized=true', () {
//       // Simulate the exact code path in clearResult():
//       //   state = FishClassificationState(isInitialized: state.isInitialized)
//       const initialized = true;
//       final cleared = FishClassificationState(isInitialized: initialized);
//       expect(cleared.result, isNull);
//       expect(cleared.error, isNull);
//       expect(cleared.isLoading, isFalse);
//       expect(cleared.isInitialized, isTrue);
//     test('clearResult resets to uninitialized when model was not ready', () {
//       const initialized = false;
//       final cleared = FishClassificationState(isInitialized: initialized);
//       expect(cleared.isInitialized, isFalse);
//     });
//   });

//   // ── FishClassificationNotifier — state transition simulation ────────────────

//     test('initialize success: isInitialized=true, error cleared', () {
//       const before = FishClassificationState();
//       final after = before.copyWith(isInitialized: true, clearError: true);
//       expect(after.isInitialized, isTrue);
//       expect(after.error, isNull);
//     });

//     test('initialize failure: isInitialized=false, error set', () {
//       const before = FishClassificationState();
//       final after = before.copyWith(
//         isInitialized: false,
//         error: 'Failed to load model: asset not found',
//       );
//       expect(after.isInitialized, isFalse);
//       expect(after.error, startsWith('Failed to load model'));
//     });

//     test('classifyImage start: isLoading=true, error cleared', () {
//       const initialized = FishClassificationState(isInitialized: true);
//       final loading = initialized.copyWith(isLoading: true, clearError: true);
//       expect(loading.isLoading, isTrue);
//       expect(loading.error, isNull);
//     });

//     test('classifyImage success: result set, isLoading=false', () {
//       final loading = const FishClassificationState(
//           isInitialized: true, isLoading: true);
//       final result = makeResult(className: 'Shrimp', confidence: 0.91);
//       final done = loading.copyWith(result: result, isLoading: false);
//       expect(done.isLoading, isFalse);
//       expect(done.result!.className, 'Shrimp');
//       expect(done.result!.confidence, closeTo(0.91, 0.0001));
//     });

//     test('classifyImage failure: error set, isLoading=false', () {
//       final loading = const FishClassificationState(
//           isInitialized: true, isLoading: true);
//       final failed = loading.copyWith(
//         isLoading: false,
//         error: 'Classification failed: model error',
//       );
//       expect(failed.isLoading, isFalse);
//       expect(failed.error, contains('Classification failed'));
//       expect(failed.result, isNull);
//     });

    test('classifyImage when not initialized: error set, no loading', () {
      const before = FishClassificationState(isInitialized: false);
      final guarded = before.copyWith(error: 'Model not ready');
      expect(guarded.isLoading, isFalse);
      expect(guarded.error, 'Model not ready');
    });
  }
  

