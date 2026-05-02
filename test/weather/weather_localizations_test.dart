import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/l10n/weather/weather_localizations.dart';

/// Pumps a minimal MaterialApp with the given locale and returns the
/// WeatherLocalizations instance resolved from that context.
Future<WeatherLocalizations> _l10n(WidgetTester tester, String lang) async {
  WeatherLocalizations? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      home: Builder(builder: (ctx) {
        result = WeatherLocalizations.of(ctx);
        return const SizedBox();
      }),
    ),
  );
  return result!;
}

void main() {
  // ── Arabic digit conversion ──────────────────────────────────────────────────

  group('n() — Arabic digit conversion', () {
    testWidgets('converts single digits to Arabic-Indic in Arabic locale',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.n(0), '٠');
      expect(ar.n(1), '١');
      expect(ar.n(9), '٩');
    });

    testWidgets('converts multi-digit numbers correctly', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.n(28), '٢٨');
      expect(ar.n(100), '١٠٠');
    });

    testWidgets('returns unmodified string in English locale', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.n(28), '28');
      expect(en.n(0), '0');
    });
  });

  // ── UV level thresholds ──────────────────────────────────────────────────────

  group('uvLevel() — threshold bands', () {
    testWidgets('uv <= 2 returns low label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.uvLevel(0), 'Low');
      expect(en.uvLevel(2), 'Low');
    });

    testWidgets('uv 3–5 returns moderate label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.uvLevel(3), 'Moderate');
      expect(en.uvLevel(5), 'Moderate');
    });

    testWidgets('uv 6–7 returns high label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.uvLevel(6), 'High');
      expect(en.uvLevel(7), 'High');
    });

    testWidgets('uv 8–10 returns very high label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.uvLevel(8), 'Very High');
      expect(en.uvLevel(10), 'Very High');
    });

    testWidgets('uv > 10 returns extreme label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.uvLevel(11), 'Extreme');
      expect(en.uvLevel(15), 'Extreme');
    });

    testWidgets('returns Arabic labels in Arabic locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.uvLevel(0), 'منخفض');
      expect(ar.uvLevel(3), 'معتدل');
      expect(ar.uvLevel(11), 'شديد');
    });
  });

  // ── Feels-like description ───────────────────────────────────────────────────

  group('feelsLikeDescription()', () {
    testWidgets('difference < 2 degrees returns similar label', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.feelsLikeDescription(28.0, 27.5), 'Similar to actual');
      expect(en.feelsLikeDescription(28.0, 28.0), 'Similar to actual');
    });

    testWidgets('feels warmer by >= 2 degrees', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.feelsLikeDescription(30.0, 27.0), 'Feels warmer');
    });

    testWidgets('feels cooler by >= 2 degrees', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.feelsLikeDescription(25.0, 28.0), 'Feels cooler');
    });

    testWidgets('boundary: exactly 2 degrees warmer returns warmer',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.feelsLikeDescription(30.0, 28.0), 'Feels warmer');
    });
  });

  // ── Visibility description ───────────────────────────────────────────────────

  group('visibilityDescription()', () {
    testWidgets('vis >= 10 km returns clear', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.visibilityDescription(10.0), 'Clear');
      expect(en.visibilityDescription(15.0), 'Clear');
    });

    testWidgets('vis 5–9 km returns good', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.visibilityDescription(5.0), 'Good');
      expect(en.visibilityDescription(9.0), 'Good');
    });

    testWidgets('vis < 2 km returns low', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.visibilityDescription(1.0), 'Low');
      expect(en.visibilityDescription(0.0), 'Low');
    });
  });

  // ── Condition text translation ───────────────────────────────────────────────

  group('conditionText()', () {
    testWidgets('translates known conditions to Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.conditionText('Sunny'), 'مشمس');
      expect(ar.conditionText('Cloudy'), 'غائم');
      expect(ar.conditionText('Fog'), 'ضباب');
    });

    testWidgets('lookup is case-insensitive', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.conditionText('SUNNY'), 'مشمس');
      expect(ar.conditionText('sunny'), 'مشمس');
    });

    testWidgets('returns original text for unknown condition', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.conditionText('Unknown Condition'), 'Unknown Condition');
    });

    testWidgets('returns original text unchanged in English locale',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.conditionText('Sunny'), 'Sunny');
    });
  });

  // ── City name translation ────────────────────────────────────────────────────

  group('cityName()', () {
    testWidgets('translates known Bahraini cities to Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.cityName('Manama'), 'المنامة');
      expect(ar.cityName('Muharraq'), 'المحرق');
      expect(ar.cityName('Riffa'), 'الرفاع');
    });

    testWidgets('lookup is case-insensitive', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.cityName('MANAMA'), 'المنامة');
      expect(ar.cityName('manama'), 'المنامة');
    });

    testWidgets('returns original name for unknown city', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.cityName('Unknown City'), 'Unknown City');
    });

    testWidgets('returns name unchanged in English locale', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.cityName('Manama'), 'Manama');
    });
  });

  // ── Day names ────────────────────────────────────────────────────────────────

  group('dayName()', () {
    testWidgets('returns correct English day names by weekday index',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.dayName(1), 'Mon');
      expect(en.dayName(5), 'Fri');
      expect(en.dayName(7), 'Sun');
    });

    testWidgets('returns correct Arabic day names', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.dayName(5), 'الجمعة');
      expect(ar.dayName(7), 'الأحد');
    });
  });

  // ── Time formatting ──────────────────────────────────────────────────────────

  group('formatTime()', () {
    testWidgets('converts AM suffix to Arabic ص', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.formatTime('06:10 AM'), contains('ص'));
    });

    testWidgets('converts PM suffix to Arabic م', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.formatTime('05:50 PM'), contains('م'));
    });

    testWidgets('converts time digits to Arabic-Indic numerals', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.formatTime('06:10 AM'), contains('٠٦'));
    });

    testWidgets('returns original string unchanged in English locale',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.formatTime('06:10 AM'), '06:10 AM');
    });
  });
}
