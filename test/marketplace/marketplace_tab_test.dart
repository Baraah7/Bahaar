import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/l10n/marketplace/marketplace_localizations.dart';

// ── MarketplaceLocalizations ─────────────────────────────────────────────────

Future<MarketplaceLocalizations> _l10n(
    WidgetTester tester, String lang) async {
  MarketplaceLocalizations? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(lang),
      home: Builder(builder: (ctx) {
        result = MarketplaceLocalizations.of(ctx);
        return const SizedBox();
      }),
    ),
  );
  return result!;
}

void main() {
  // ── Localization — static string getters ────────────────────────────────────

  group('MarketplaceLocalizations — static getters', () {
    testWidgets('returns Arabic strings when locale is ar', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.marketplace, 'السوق');
      expect(ar.sellFish, 'بيع سمك');
      expect(ar.myOrders, 'طلباتي');
      expect(ar.noFishListingsFound, 'لم يتم العثور على قوائم أسماك');
      expect(ar.clearFilters, 'مسح المرشحات');
      expect(ar.listingDeleted, 'تم حذف القائمة');
    });

    testWidgets('returns English strings when locale is en', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.marketplace, 'Marketplace');
      expect(en.sellFish, 'Sell Fish');
      expect(en.myOrders, 'My Orders');
      expect(en.noFishListingsFound, 'No fish listings found');
      expect(en.clearFilters, 'Clear Filters');
      expect(en.listingDeleted, 'Listing deleted');
    });

    testWidgets('localeName reflects the active locale code', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.localeName, 'ar');
      expect(en.localeName, 'en');
    });
  });

  // ── Localization — parameterised methods ────────────────────────────────────

  group('MarketplaceLocalizations — parameterised methods', () {
    testWidgets('priceRangeFilter formats correctly in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.priceRangeFilter('5', '20'), 'Price: 5–20 BD/kg');
    });

    testWidgets('priceRangeFilter formats correctly in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.priceRangeFilter('5', '20'), 'السعر: 5–20 BD/كجم');
    });

    testWidgets('youHaveOrderedFish interpolates fish name in English',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.youHaveOrderedFish('Hamour'), 'You have ordered Hamour');
    });

    testWidgets('youHaveOrderedFish interpolates fish name in Arabic',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.youHaveOrderedFish('هامور'), 'لقد طلبت هامور');
    });

    testWidgets('sellingTab formats count in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.sellingTab(0), 'Selling (0)');
      expect(en.sellingTab(3), 'Selling (3)');
    });

    testWidgets('sellingTab formats count in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.sellingTab(2), 'البيع (2)');
    });

    testWidgets('purchasesTab formats count in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.purchasesTab(0), 'Purchases (0)');
      expect(en.purchasesTab(5), 'Purchases (5)');
    });

    testWidgets('purchasesTab formats count in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.purchasesTab(1), 'المشتريات (1)');
    });
  });

  // ── Localization — order/status strings ─────────────────────────────────────

  group('MarketplaceLocalizations — order and status strings', () {
    testWidgets('order status getters return correct Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.pending, 'في الانتظار');
      expect(ar.accepted, 'مقبول');
      expect(ar.rejected, 'مرفوض');
      expect(ar.completed, 'مكتمل');
      expect(ar.cancelled, 'ملغى');
    });

    testWidgets('order status getters return correct English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.pending, 'Pending');
      expect(en.accepted, 'Accepted');
      expect(en.rejected, 'Rejected');
      expect(en.completed, 'Completed');
      expect(en.cancelled, 'Cancelled');
    });

    testWidgets('pleaseLoginToOrder differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.pleaseLoginToOrder, isNot(en.pleaseLoginToOrder));
      expect(ar.pleaseLoginToOrder, contains('تسجيل'));
    });
  });

  // ── Localization — unit and currency labels ──────────────────────────────────

  group('MarketplaceLocalizations — unit and currency labels', () {
    testWidgets('kgUnit returns Arabic unit', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.kgUnit, 'كجم');
    });

    testWidgets('bdUnit is the same in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.bdUnit, 'BD');
      expect(en.bdUnit, 'BD');
    });

    testWidgets('bdPerKg returns locale-aware string', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.bdPerKg, 'BD/كجم');
      expect(en.bdPerKg, 'BD/kg');
    });
  });

  // ── Localization — guest / auth strings ─────────────────────────────────────

  group('MarketplaceLocalizations — guest and auth strings', () {
    testWidgets('guestAccountLoginMessage is non-empty in both locales',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.guestAccountLoginMessage, isNotEmpty);
      expect(en.guestAccountLoginMessage, isNotEmpty);
      expect(ar.guestAccountLoginMessage, isNot(en.guestAccountLoginMessage));
    });

    testWidgets('guestAccountSellMessage differs from guestAccountLoginMessage',
        (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.guestAccountSellMessage, isNot(en.guestAccountLoginMessage));
    });

    testWidgets('logIn and signIn are both non-empty Arabic strings',
        (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.logIn, isNotEmpty);
      expect(ar.signIn, isNotEmpty);
    });
  });

  // ── Localization — fish condition strings ───────────────────────────────────

  group('MarketplaceLocalizations — fish condition strings', () {
    testWidgets('all condition getters are defined in Arabic', (tester) async {
      final ar = await _l10n(tester, 'ar');
      expect(ar.fresh, 'طازج');
      expect(ar.frozen, 'مجمد');
      expect(ar.cleaned, 'منظف');
      expect(ar.filleted, 'مفلل');
    });

    testWidgets('all condition getters are defined in English', (tester) async {
      final en = await _l10n(tester, 'en');
      expect(en.fresh, 'Fresh');
      expect(en.frozen, 'Frozen');
      expect(en.cleaned, 'Cleaned');
      expect(en.filleted, 'Filleted');
    });
  });

  // ── Localization — validation messages ──────────────────────────────────────

  group('MarketplaceLocalizations — validation messages', () {
    testWidgets('phoneEightDigits is non-empty in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.phoneEightDigits, isNotEmpty);
      expect(en.phoneEightDigits, contains('8'));
    });

    testWidgets('ibanOrQrRequired differs by locale', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.ibanOrQrRequired, isNot(en.ibanOrQrRequired));
    });

    testWidgets('invalidNumber is non-empty in both locales', (tester) async {
      final ar = await _l10n(tester, 'ar');
      final en = await _l10n(tester, 'en');
      expect(ar.invalidNumber, isNotEmpty);
      expect(en.invalidNumber, isNotEmpty);
    });
  });
}
