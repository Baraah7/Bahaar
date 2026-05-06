import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/l10n/fish_recognition/fish_recognition_localizations.dart';

Future<FishRecognitionLocalizations> _l10n(
    WidgetTester tester, String lang) async {
  FishRecognitionLocalizations? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      home: Builder(builder: (ctx) {
        result = FishRecognitionLocalizations.of(ctx);
        return const SizedBox();
      }),
    ),
  );
  return result!;
}

void main() {
  // ── localeName ───────────────────────────────────────────────────────────────

  group('localeName', () {
    testWidgets('returns "ar" for Arabic locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.localeName, 'ar');
    });

    testWidgets('returns "en" for English locale', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.localeName, 'en');
    });
  });

  // ── Core UI strings ──────────────────────────────────────────────────────────

  group('Core UI strings — Arabic', () {
    testWidgets('all core UI strings are non-empty and in Arabic',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.fishRecognition, 'التعرف على الأسماك');
      expect(ar.loadingRecognitionModel, 'جاري تحميل نموذج التعرف...');
      expect(ar.takePhotoOfFish, 'التقط صورة للأسماك أو الجمبري');
      expect(ar.systemWillIdentify, 'سيتعرف النظام على النوع تلقائياً');
      expect(ar.camera, 'الكاميرا');
      expect(ar.gallery, 'المعرض');
      expect(ar.analyzing, 'جاري التحليل...');
      expect(ar.newImage, 'صورة جديدة');
      expect(ar.reanalyze, 'إعادة التحليل');
      expect(ar.supportedSpecies, 'الأنواع المدعومة');
    });
  });

  group('Core UI strings — English', () {
    testWidgets('all core UI strings are non-empty and in English',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.fishRecognition, 'Fish Recognition');
      expect(en.loadingRecognitionModel, 'Loading recognition model...');
      expect(en.takePhotoOfFish, 'Take a photo of fish or shrimp');
      expect(en.systemWillIdentify,
          'The system will identify the species automatically');
      expect(en.camera, 'Camera');
      expect(en.gallery, 'Gallery');
      expect(en.analyzing, 'Analyzing...');
      expect(en.newImage, 'New Image');
      expect(en.reanalyze, 'Reanalyze');
      expect(en.supportedSpecies, 'Supported Species');
    });
  });

  // ── Confidence result strings ────────────────────────────────────────────────

  group('Confidence and result strings', () {
    testWidgets('highConfidence returns correct strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.highConfidence, 'ثقة عالية');
      expect(en.highConfidence, 'High Confidence');
    });

    testWidgets('lowConfidence returns correct strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.lowConfidence, 'ثقة منخفضة');
      expect(en.lowConfidence, 'Low Confidence');
    });

    testWidgets('unknownFish returns correct strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.unknownFish, 'لا أعرف');
      expect(en.unknownFish, "I Don't Know");
    });

    testWidgets('unknownFishHint is non-empty and locale-differentiated',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.unknownFishHint, isNotEmpty);
      expect(en.unknownFishHint, isNotEmpty);
      expect(ar.unknownFishHint, isNot(en.unknownFishHint));
    });

    testWidgets('tryTakingClearerPhoto is non-empty in both locales',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.tryTakingClearerPhoto, isNotEmpty);
      expect(en.tryTakingClearerPhoto, isNotEmpty);
    });
  });

  // ── Error and model-state strings ────────────────────────────────────────────

  group('Error and model-state strings', () {
    testWidgets('failedToLoadModel differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.failedToLoadModel, 'فشل تحميل نموذج التعرف');
      expect(en.failedToLoadModel, 'Failed to load recognition model');
    });

    testWidgets('tryAgain is non-empty in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.tryAgain, 'حاول مرة أخرى');
      expect(en.tryAgain, 'Try Again');
    });

    testWidgets('classificationFailed differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.classificationFailed, 'فشل التصنيف');
      expect(en.classificationFailed, 'Classification failed');
    });

    testWidgets('modelNotReady differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.modelNotReady, 'النموذج غير جاهز');
      expect(en.modelNotReady, 'Model not ready');
    });
  });

  // ── Fish info card label strings ─────────────────────────────────────────────

  group('Fish info card label strings', () {
    testWidgets('all info labels return Arabic strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.fishInfo, 'معلومات السمكة');
      expect(ar.labelHabitat, 'الموطن');
      expect(ar.labelSize, 'الحجم');
      expect(ar.labelSeason, 'أفضل موسم');
      expect(ar.labelDiet, 'الغذاء');
      expect(ar.labelFlavor, 'المذاق');
      expect(ar.labelPopularIn, 'شائع في');
      expect(ar.labelNutrition, 'القيمة الغذائية');
    });

    testWidgets('all info labels return English strings', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.fishInfo, 'Fish Info');
      expect(en.labelHabitat, 'Habitat');
      expect(en.labelSize, 'Size');
      expect(en.labelSeason, 'Best Season');
      expect(en.labelDiet, 'Diet');
      expect(en.labelFlavor, 'Flavor');
      expect(en.labelPopularIn, 'Popular In');
      expect(en.labelNutrition, 'Nutrition');
    });

    testWidgets('all info labels differ between locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.labelHabitat, isNot(en.labelHabitat));
      expect(ar.labelSeason, isNot(en.labelSeason));
      expect(ar.labelNutrition, isNot(en.labelNutrition));
    });
  });

  // ── Prediction / catch section strings ───────────────────────────────────────

  group('Prediction section strings', () {
    testWidgets('probability level strings are locale-differentiated',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.probExcellent, 'ممتاز');
      expect(en.probExcellent, 'Excellent');
      expect(ar.probVeryGood, 'جيد جداً');
      expect(en.probVeryGood, 'Very Good');
      expect(ar.probModerate, 'معتدل');
      expect(en.probModerate, 'Moderate');
      expect(ar.probWeak, 'ضعيف');
      expect(en.probWeak, 'Weak');
      expect(ar.probNotSuitable, 'غير مناسب');
      expect(en.probNotSuitable, 'Not Suitable');
    });

    testWidgets('prediction UI strings are non-empty in both locales',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.predictionTitle, isNotEmpty);
      expect(en.predictionTitle, isNotEmpty);
      expect(ar.chooseSpecies, isNotEmpty);
      expect(en.chooseSpecies, isNotEmpty);
      expect(ar.getPrediction, isNotEmpty);
      expect(en.getPrediction, isNotEmpty);
    });

    testWidgets('nearby fishing spots string is locale-differentiated',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.nearbyFishingSpots, 'مناطق الصيد القريبة');
      expect(en.nearbyFishingSpots, 'Nearby Fishing Spots');
    });

    testWidgets('kmUnit is locale-aware', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.kmUnit, 'كم');
      expect(en.kmUnit, 'km');
    });
  });

  // ── All strings are non-empty ────────────────────────────────────────────────

  group('Completeness: no empty strings', () {
    testWidgets('all getters return non-empty strings in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final strings = [
        ar.tryAgain, ar.noDataAvailable, ar.fishRecognition,
        ar.loadingRecognitionModel, ar.takePhotoOfFish, ar.systemWillIdentify,
        ar.camera, ar.gallery, ar.analyzing, ar.newImage, ar.supportedSpecies,
        ar.confidence, ar.tryTakingClearerPhoto, ar.failedToLoadModel,
        ar.failedToOpenCamera, ar.failedToSelectImage, ar.modelNotReady,
        ar.classificationFailed, ar.highConfidence, ar.lowConfidence,
        ar.unknownFish, ar.unknownFishHint, ar.reanalyze, ar.fishInfo,
        ar.labelHabitat, ar.labelSize, ar.labelSeason, ar.labelDiet,
        ar.labelFlavor, ar.labelPopularIn, ar.labelNutrition,
        ar.probExcellent, ar.probVeryGood, ar.probModerate, ar.probWeak,
        ar.probNotSuitable, ar.predictionTitle, ar.location, ar.chooseSpecies,
        ar.getPrediction, ar.nearbyFishingSpots, ar.kmUnit,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in Arabic locale');
      }
    });

    testWidgets('all getters return non-empty strings in English',
        (tester) async {
      final en = await _l10n(tester, 'en');
      final strings = [
        en.tryAgain, en.noDataAvailable, en.fishRecognition,
        en.loadingRecognitionModel, en.takePhotoOfFish, en.systemWillIdentify,
        en.camera, en.gallery, en.analyzing, en.newImage, en.supportedSpecies,
        en.confidence, en.tryTakingClearerPhoto, en.failedToLoadModel,
        en.failedToOpenCamera, en.failedToSelectImage, en.modelNotReady,
        en.classificationFailed, en.highConfidence, en.lowConfidence,
        en.unknownFish, en.unknownFishHint, en.reanalyze, en.fishInfo,
        en.labelHabitat, en.labelSize, en.labelSeason, en.labelDiet,
        en.labelFlavor, en.labelPopularIn, en.labelNutrition,
        en.probExcellent, en.probVeryGood, en.probModerate, en.probWeak,
        en.probNotSuitable, en.predictionTitle, en.location, en.chooseSpecies,
        en.getPrediction, en.nearbyFishingSpots, en.kmUnit,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in English locale');
      }
    });
  });
}
