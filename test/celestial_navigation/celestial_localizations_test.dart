import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/l10n/celestial_navigation/celestial_navigation_localizations.dart';

// ── Helper ────────────────────────────────────────────────────────────────────
//
// Use a bare `Localizations` widget to force the locale directly.
// `MaterialApp.locale` falls back to 'en' when 'ar' is not in supportedLocales,
// and adding 'ar' to supportedLocales triggers missing-delegate warnings.
// `Localizations` sets the locale independently of delegate language support,
// so `Localizations.localeOf(ctx)` returns the exact locale we specify.

Future<CelestialNavigationLocalizations> _l10n(
    WidgetTester tester, String lang) async {
  CelestialNavigationLocalizations? result;
  await tester.pumpWidget(
    Localizations(
      locale: Locale(lang),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Builder(builder: (ctx) {
        result = CelestialNavigationLocalizations.of(ctx);
        return const SizedBox();
      }),
    ),
  );
  return result!;
}

void main() {
  // ── locale differentiation ───────────────────────────────────────────────

  group('CelestialNavigationLocalizations — locale differentiation', () {
    testWidgets('Arabic and English instances produce different strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.celestialNavigation, isNot(en.celestialNavigation));
    });

    testWidgets('Arabic instance returns Arabic script', (tester) async {
      final ar = await _l10n(tester, 'ar');
      // Arabic script contains characters in the Unicode Arabic block
      final hasArabic = ar.celestialNavigation.codeUnits.any((c) => c >= 0x0600 && c <= 0x06FF);
      expect(hasArabic, isTrue);
    });

    testWidgets('English instance returns Latin script', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.celestialNavigation, 'Celestial Navigation');
    });
  });

  // ── Header strings ────────────────────────────────────────────────────────

  group('Header strings — Arabic', () {
    testWidgets('exact Arabic strings for primary header labels', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.celestialNavigation, 'الملاحة الفلكية');
      expect(ar.starBasedPositionFixing, 'تحديد الموقع عبر النجوم');
      expect(ar.gettingGps, 'جارٍ تحديد الموقع...');
      expect(ar.gpsUnavailable, 'GPS غير متوفر');
      expect(ar.noScanYet, 'لم يتم المسح بعد');
      expect(ar.viewOnMap, 'عرض على الخريطة');
    });
  });

  group('Header strings — English', () {
    testWidgets('exact English strings for primary header labels', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.celestialNavigation, 'Celestial Navigation');
      expect(en.starBasedPositionFixing, 'Star-based position fixing');
      expect(en.gettingGps, 'Getting GPS...');
      expect(en.gpsUnavailable, 'GPS unavailable');
      expect(en.noScanYet, 'No scan yet');
      expect(en.viewOnMap, 'View on Map');
    });
  });

  // ── Parameterised methods ─────────────────────────────────────────────────

  group('Parameterised methods', () {
    testWidgets('starsDetectedCount in English formats count correctly', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.starsDetectedCount(12), '12 stars');
      expect(en.starsDetectedCount(0), '0 stars');
      expect(en.starsDetectedCount(1), '1 stars'); // no singular/plural
    });

    testWidgets('starsDetectedCount in Arabic includes count', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.starsDetectedCount(7), contains('7'));
    });

    testWidgets('confidencePct in English formats correctly', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.confidencePct('75'), '75% confidence');
      expect(en.confidencePct('100'), '100% confidence');
    });

    testWidgets('confidencePct in Arabic includes percentage string', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.confidencePct('75'), contains('75'));
      expect(ar.confidencePct('75'), contains('دقة'));
    });

    testWidgets('horizonDetectedAngle in English formats correctly', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.horizonDetectedAngle('3.5'), 'Detected (3.5°)');
    });

    testWidgets('horizonDetectedAngle in Arabic includes angle', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.horizonDetectedAngle('3.5'), contains('3.5'));
    });
  });

  // ── Scanner card strings ──────────────────────────────────────────────────

  group('Scanner card strings', () {
    testWidgets('Arabic scanner strings are non-empty and correct', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.skyScanner, 'ماسح السماء');
      expect(ar.scanAgain, 'مسح مجددًا');
      expect(ar.startSkyScan, 'بدء مسح السماء');
      expect(ar.scannerDescription, isNotEmpty);
    });

    testWidgets('English scanner strings are non-empty and correct', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.skyScanner, 'Sky Scanner');
      expect(en.scanAgain, 'Scan Again');
      expect(en.startSkyScan, 'Start Sky Scan');
      expect(en.scannerDescription, isNotEmpty);
    });
  });

  // ── Results card strings ──────────────────────────────────────────────────

  group('Results card strings', () {
    testWidgets('all result labels are non-empty in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.scanResults, 'نتائج المسح');
      expect(ar.starsDetected, 'النجوم المكتشفة');
      expect(ar.confidence, 'الدقة');
      expect(ar.imuDrift, 'انجراف IMU');
      expect(ar.horizon, 'الأفق');
      expect(ar.notDetected, 'غير مكتشف');
      expect(ar.identifiedStars, 'النجوم المحددة');
    });

    testWidgets('all result labels are non-empty in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.scanResults, 'Scan Results');
      expect(en.starsDetected, 'Stars detected');
      expect(en.confidence, 'Confidence');
      expect(en.imuDrift, 'IMU drift');
      expect(en.horizon, 'Horizon');
      expect(en.notDetected, 'Not detected');
      expect(en.identifiedStars, 'Identified Stars');
    });
  });

  // ── How-to steps structure ────────────────────────────────────────────────

  group('steps list structure', () {
    testWidgets('English steps has exactly 5 steps', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.steps.length, 5);
    });

    testWidgets('Arabic steps has exactly 5 steps', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.steps.length, 5);
    });

    testWidgets('each English step has exactly 2 strings', (tester) async {
      final en = await _l10n(tester, 'en');
      for (final step in en.steps) {
        expect(step.length, 2, reason: 'Step should have [title, description]');
      }
    });

    testWidgets('each Arabic step has exactly 2 strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      for (final step in ar.steps) {
        expect(step.length, 2, reason: 'Step should have [title, description]');
      }
    });

    testWidgets('all English step titles and descriptions are non-empty',
        (tester) async {
      final en = await _l10n(tester, 'en');
      for (int i = 0; i < en.steps.length; i++) {
        expect(en.steps[i][0], isNotEmpty, reason: 'Step $i title is empty');
        expect(en.steps[i][1], isNotEmpty, reason: 'Step $i description is empty');
      }
    });

    testWidgets('all Arabic step titles and descriptions are non-empty',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      for (int i = 0; i < ar.steps.length; i++) {
        expect(ar.steps[i][0], isNotEmpty, reason: 'Step $i title is empty');
        expect(ar.steps[i][1], isNotEmpty, reason: 'Step $i description is empty');
      }
    });

    testWidgets('step titles differ between Arabic and English', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      // At least the first step title should differ
      expect(ar.steps[0][0], isNot(en.steps[0][0]));
    });
  });

  // ── Spoofing alert ────────────────────────────────────────────────────────

  group('spoofingAlert', () {
    testWidgets('English alert contains GPS SPOOFING keyword', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.spoofingAlert, contains('SPOOFING'));
      expect(en.spoofingAlert, contains('2 NM'));
    });

    testWidgets('Arabic alert is non-empty and contains 2 NM reference', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.spoofingAlert, isNotEmpty);
      expect(ar.spoofingAlert, contains('2'));
    });

    testWidgets('spoofing alerts differ by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.spoofingAlert, isNot(en.spoofingAlert));
    });
  });

  // ── Legacy strings ────────────────────────────────────────────────────────

  group('Legacy strings', () {
    testWidgets('celestialAlmanac and solarNoon are non-empty in both locales',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.celestialAlmanac, 'التقويم الفلكي');
      expect(en.celestialAlmanac, 'Celestial Almanac');
      expect(ar.solarNoon, 'الذروة الشمسية');
      expect(en.solarNoon, 'Solar Noon');
    });
  });

  // ── howToUse label ────────────────────────────────────────────────────────

  group('howToUse label', () {
    testWidgets('howToUse differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(en.howToUse, 'How to Use');
      expect(ar.howToUse, 'كيفية الاستخدام');
    });
  });

  // ── Completeness — all getters non-empty ─────────────────────────────────

  group('Completeness — all getters non-empty', () {
    testWidgets('all Arabic string getters return non-empty strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final strings = [
        ar.celestialNavigation, ar.starBasedPositionFixing, ar.gettingGps,
        ar.gpsUnavailable, ar.noScanYet, ar.viewOnMap, ar.howToUse,
        ar.skyScanner, ar.scannerDescription, ar.scanAgain, ar.startSkyScan,
        ar.scanResults, ar.starsDetected, ar.confidence, ar.imuDrift,
        ar.horizon, ar.notDetected, ar.identifiedStars, ar.spoofingAlert,
        ar.celestialAlmanac, ar.solarNoon,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in Arabic locale');
      }
    });

    testWidgets('all English string getters return non-empty strings', (tester) async {
      final en = await _l10n(tester, 'en');
      final strings = [
        en.celestialNavigation, en.starBasedPositionFixing, en.gettingGps,
        en.gpsUnavailable, en.noScanYet, en.viewOnMap, en.howToUse,
        en.skyScanner, en.scannerDescription, en.scanAgain, en.startSkyScan,
        en.scanResults, en.starsDetected, en.confidence, en.imuDrift,
        en.horizon, en.notDetected, en.identifiedStars, en.spoofingAlert,
        en.celestialAlmanac, en.solarNoon,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in English locale');
      }
    });
  });
}
