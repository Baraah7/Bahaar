import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/l10n/fishing_log/fishing_log_localizations.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Future<FishingLogLocalizations> _l10n(
    WidgetTester tester, String lang) async {
  FishingLogLocalizations? result;
  await tester.pumpWidget(
    Localizations(
      locale: Locale(lang),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Builder(builder: (ctx) {
        result = FishingLogLocalizations.of(ctx);
        return const SizedBox();
      }),
    ),
  );
  return result!;
}

void main() {
  // ── localeName ───────────────────────────────────────────────────────────

  group('FishingLogLocalizations — localeName', () {
    testWidgets('returns "ar" for Arabic locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.localeName, 'ar');
    });

    testWidgets('returns "en" for English locale', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.localeName, 'en');
    });
  });

  // ── Core UI strings — Arabic ─────────────────────────────────────────────

  group('Core UI strings — Arabic', () {
    testWidgets('exact Arabic strings for primary UI labels', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.fishingLog, 'السجل');
      expect(ar.searchTrips, 'البحث باسم الرحلة...');
      expect(ar.startTrip, 'بدء رحلة جديدة');
      expect(ar.endTrip, 'إنهاء الرحلة');
      expect(ar.resumeTrip, 'استئناف الرحلة');
      expect(ar.logCatch, 'تسجيل صيد');
      expect(ar.addCatch, 'إضافة مصيد');
      expect(ar.noTripsYet, 'لا توجد رحلات بعد');
      expect(ar.ongoing, 'جارية');
      expect(ar.tripInProgress, 'رحلة جارية');
    });
  });

  // ── Core UI strings — English ────────────────────────────────────────────

  group('Core UI strings — English', () {
    testWidgets('exact English strings for primary UI labels', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.fishingLog, 'Log');
      expect(en.searchTrips, 'Search by trip title...');
      expect(en.startTrip, 'Start New Trip');
      expect(en.endTrip, 'End Trip');
      expect(en.resumeTrip, 'Resume Trip');
      expect(en.logCatch, 'Log Catch');
      expect(en.addCatch, 'Add Catch');
      expect(en.noTripsYet, 'No trips yet');
      expect(en.ongoing, 'Ongoing');
      expect(en.tripInProgress, 'Trip in progress');
    });
  });

  // ── Quick-species chip labels ─────────────────────────────────────────────

  group('Quick-species chip labels', () {
    testWidgets('all Arabic quick-species labels are non-empty', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.quickSpeciesHamour, 'هامور');
      expect(ar.quickSpeciesSafi, 'صافي');
      expect(ar.quickSpeciesSobaity, 'صبيطي');
      expect(ar.quickSpeciesChanad, 'شعور');
      expect(ar.quickSpeciesZubaidi, 'زبيدي');
      expect(ar.quickSpeciesShrimp, 'جمبري');
      expect(ar.quickSpeciesCrab, 'سرطان البحر');
    });

    testWidgets('all English quick-species labels are non-empty', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.quickSpeciesHamour, 'Hamour');
      expect(en.quickSpeciesSafi, 'Safi');
      expect(en.quickSpeciesSobaity, 'Sobaity');
      expect(en.quickSpeciesChanad, 'Chanad');
      expect(en.quickSpeciesZubaidi, 'Zubaidi');
      expect(en.quickSpeciesShrimp, 'Shrimp');
      expect(en.quickSpeciesCrab, 'Crab');
    });
  });

  // ── Parameterised methods ─────────────────────────────────────────────────

  group('Parameterised methods', () {
    testWidgets('removeCatchConfirm interpolates species in English',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(
        en.removeCatchConfirm('Hamour'),
        'Remove "Hamour" from this trip?',
      );
    });

    testWidgets('removeCatchConfirm interpolates species in Arabic',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.removeCatchConfirm('هامور'), contains('هامور'));
    });

    testWidgets('deleteTripConfirmFinished interpolates name in English',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(
        en.deleteTripConfirmFinished('Morning Run'),
        "Delete the trip 'Morning Run'?",
      );
    });

    testWidgets('deleteTripConfirmFinished interpolates name in Arabic',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.deleteTripConfirmFinished('رحلة الصباح'), contains('رحلة الصباح'));
    });
  });

  // ── Catch and weight strings ──────────────────────────────────────────────

  group('Catch and weight strings', () {
    testWidgets('catchWord and catches are distinct in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.catchWord, isNotEmpty);
      expect(ar.catches, isNotEmpty);
      expect(ar.catchWord, isNot(ar.catches));
    });

    testWidgets('catchWord and catches are distinct in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.catchWord, 'catch');
      expect(en.catches, 'catches');
    });

    testWidgets('kgUnit returns locale-aware string', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.kgUnit, 'كجم');
      expect(en.kgUnit, 'kg');
    });

    testWidgets('weightKg label differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.weightKg, isNot(en.weightKg));
    });
  });

  // ── Location and form strings ─────────────────────────────────────────────

  group('Location and form strings', () {
    testWidgets('pinOnMap / pinnedOnMap / locationNotSet non-empty in both locales',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.pinOnMap, isNotEmpty);
      expect(en.pinOnMap, isNotEmpty);
      expect(ar.pinnedOnMap, isNotEmpty);
      expect(en.pinnedOnMap, isNotEmpty);
      expect(ar.locationNotSet, isNotEmpty);
      expect(en.locationNotSet, isNotEmpty);
    });

    testWidgets('speciesRequired validation string is locale-differentiated',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.speciesRequired, isNot(en.speciesRequired));
    });

    testWidgets('latitude / longitude labels differ by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.latitude, isNot(en.latitude));
      expect(ar.longitude, isNot(en.longitude));
    });
  });

  // ── Confirmation and action strings ──────────────────────────────────────

  group('Confirmation and action strings', () {
    testWidgets('delete and cancel are non-empty in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.delete, isNotEmpty);
      expect(en.delete, 'Delete');
      expect(ar.cancel, isNotEmpty);
      expect(en.cancel, 'Cancel');
    });

    testWidgets('endCurrentTrip confirmation string is locale-differentiated',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.endCurrentTrip, isNot(en.endCurrentTrip));
    });

    testWidgets('tripEndedAndSaved is non-empty in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.tripEndedAndSaved, isNotEmpty);
      expect(en.tripEndedAndSaved, 'Trip ended and saved');
    });

    testWidgets('tripAlreadyActive differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.tripAlreadyActive, isNot(en.tripAlreadyActive));
    });

    testWidgets('endActiveTripFirst differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.endActiveTripFirst, isNot(en.endActiveTripFirst));
    });
  });

  // ── Trip card stat labels ─────────────────────────────────────────────────

  group('Trip card stat labels', () {
    testWidgets('all trip-card labels are non-empty in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.tripActiveLabel, isNotEmpty);
      expect(ar.tripStartedLabel, isNotEmpty);
      expect(ar.tripDurationLabel, isNotEmpty);
      expect(ar.tripCatchesLabel, isNotEmpty);
    });

    testWidgets('all trip-card labels are non-empty in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.tripActiveLabel, 'Active');
      expect(en.tripStartedLabel, 'Started');
      expect(en.tripDurationLabel, 'Duration');
      expect(en.tripCatchesLabel, 'Catches');
    });
  });

  // ── Completeness: all getters non-empty ───────────────────────────────────

  group('Completeness — no empty strings', () {
    testWidgets('all Arabic getters return non-empty strings', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final strings = [
        ar.fishingLog, ar.searchTrips, ar.tripDetailTitle,
        ar.tripStart, ar.tripEnd, ar.totalWeight, ar.noCatchesLogged,
        ar.deleteCatch, ar.editCatch, ar.saveChanges, ar.speciesName,
        ar.notesOptional, ar.pinOnMap, ar.latitude, ar.longitude,
        ar.locationPinned, ar.ongoing, ar.pickCatchTime,
        ar.quickSpeciesHamour, ar.quickSpeciesSafi, ar.quickSpeciesSobaity,
        ar.quickSpeciesChanad, ar.quickSpeciesZubaidi, ar.quickSpeciesShrimp,
        ar.quickSpeciesCrab, ar.tripAlreadyActive, ar.endActiveTripFirst,
        ar.endButtonLabel, ar.editTripTitle, ar.tripNameHint,
        ar.editTitleTooltip, ar.deleteTripTooltip, ar.signInToTrack,
        ar.tripResumed, ar.endTrip, ar.endCurrentTrip, ar.tripEndedAndSaved,
        ar.deleteTrip, ar.delete, ar.deleteActiveTrip, ar.deleteTripConfirm,
        ar.tripDeleted, ar.noTripsYet, ar.tapStartTrip, ar.resumeTrip,
        ar.startTrip, ar.tripInProgress, ar.catchWord, ar.catches,
        ar.addCatch, ar.logCatchTitle, ar.catchDetails, ar.speciesNameLabel,
        ar.speciesRequired, ar.notesOptionalLabel, ar.catchLocationLabel,
        ar.pinnedOnMap, ar.gpsLocationLabel, ar.locationNotSet,
        ar.mapLabel, ar.tripActiveLabel, ar.tripStartedLabel,
        ar.tripDurationLabel, ar.tripCatchesLabel, ar.logCatch, ar.kgUnit,
        ar.cancel, ar.save, ar.weight, ar.weightKg, ar.logIn,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in Arabic locale');
      }
    });

    testWidgets('all English getters return non-empty strings', (tester) async {
      final en = await _l10n(tester, 'en');
      final strings = [
        en.fishingLog, en.searchTrips, en.tripDetailTitle,
        en.tripStart, en.tripEnd, en.totalWeight, en.noCatchesLogged,
        en.deleteCatch, en.editCatch, en.saveChanges, en.speciesName,
        en.notesOptional, en.pinOnMap, en.latitude, en.longitude,
        en.locationPinned, en.ongoing, en.pickCatchTime,
        en.quickSpeciesHamour, en.quickSpeciesSafi, en.quickSpeciesSobaity,
        en.quickSpeciesChanad, en.quickSpeciesZubaidi, en.quickSpeciesShrimp,
        en.quickSpeciesCrab, en.tripAlreadyActive, en.endActiveTripFirst,
        en.endButtonLabel, en.editTripTitle, en.tripNameHint,
        en.editTitleTooltip, en.deleteTripTooltip, en.signInToTrack,
        en.tripResumed, en.endTrip, en.endCurrentTrip, en.tripEndedAndSaved,
        en.deleteTrip, en.delete, en.deleteActiveTrip, en.deleteTripConfirm,
        en.tripDeleted, en.noTripsYet, en.tapStartTrip, en.resumeTrip,
        en.startTrip, en.tripInProgress, en.catchWord, en.catches,
        en.addCatch, en.logCatchTitle, en.catchDetails, en.speciesNameLabel,
        en.speciesRequired, en.notesOptionalLabel, en.catchLocationLabel,
        en.pinnedOnMap, en.gpsLocationLabel, en.locationNotSet,
        en.mapLabel, en.tripActiveLabel, en.tripStartedLabel,
        en.tripDurationLabel, en.tripCatchesLabel, en.logCatch, en.kgUnit,
        en.cancel, en.save, en.weight, en.weightKg, en.logIn,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'Got empty string in English locale');
      }
    });
  });
}
