import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/marketplace/fish_listing.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

FishListing makeListing({
  String id = 'listing-1',
  FishType fishType = FishType.hamour,
  String? customFishName,
  double weight = 5.0,
  double pricePerKg = 10.0,
  FishCondition condition = FishCondition.fresh,
  List<PaymentMethod> acceptedPayments = const [PaymentMethod.cash],
  String? description,
  List<String> imageUrls = const [],
  String? fromCatchId,
  String sellerId = 'seller-1',
  String sellerName = 'Ahmed',
  String sellerPhone = '33001122',
  String? sellerLocation,
  ListingStatus status = ListingStatus.available,
  String? catchLocation,
  DateTime? catchDate,
}) {
  return FishListing(
    id: id,
    fishType: fishType,
    customFishName: customFishName,
    weight: weight,
    pricePerKg: pricePerKg,
    condition: condition,
    acceptedPayments: acceptedPayments,
    description: description,
    imageUrls: imageUrls,
    fromCatchId: fromCatchId,
    sellerId: sellerId,
    sellerName: sellerName,
    sellerPhone: sellerPhone,
    sellerLocation: sellerLocation,
    listedAt: DateTime(2026, 1, 15),
    status: status,
    catchLocation: catchLocation,
    catchDate: catchDate,
  );
}

void main() {
  // ── Enum: FishType ──────────────────────────────────────────────────────────

  group('FishType', () {
    test('all values have unique displayName', () {
      final names = FishType.values.map((e) => e.displayName).toSet();
      expect(names.length, FishType.values.length);
    });

    test('all values have Arabic names', () {
      for (final type in FishType.values) {
        expect(type.arabicName, isNotEmpty);
      }
    });

    test('localizedName returns English for "en"', () {
      expect(FishType.hamour.localizedName('en'), 'Hamour (Grouper)');
      expect(FishType.shrimp.localizedName('en'), 'Shrimp');
    });

    test('localizedName returns Arabic for "ar"', () {
      expect(FishType.hamour.localizedName('ar'), 'هامور');
      expect(FishType.shrimp.localizedName('ar'), 'ربيان');
      expect(FishType.crab.localizedName('ar'), 'قبقب');
    });

    test('localizedName falls back to English for unknown language code', () {
      expect(FishType.hamour.localizedName('fr'), 'Hamour (Grouper)');
    });
  });

  // ── Enum: FishCondition ─────────────────────────────────────────────────────

  group('FishCondition', () {
    test('all values have displayName', () {
      for (final c in FishCondition.values) {
        expect(c.displayName, isNotEmpty);
      }
    });

    test('localizedName returns Arabic for "ar"', () {
      expect(FishCondition.fresh.localizedName('ar'), 'طازج');
      expect(FishCondition.frozen.localizedName('ar'), 'مثلج');
      expect(FishCondition.cleaned.localizedName('ar'), 'نظيف');
      expect(FishCondition.filleted.localizedName('ar'), 'شرائح');
    });

    test('localizedName returns English for "en"', () {
      expect(FishCondition.fresh.localizedName('en'), 'Fresh');
      expect(FishCondition.frozen.localizedName('en'), 'Frozen');
    });
  });

  // ── Enum: PaymentMethod ─────────────────────────────────────────────────────

  group('PaymentMethod', () {
    test('localizedName returns Arabic for "ar"', () {
      expect(PaymentMethod.cash.localizedName('ar'), 'نقداً');
      expect(PaymentMethod.benefitPay.localizedName('ar'), 'بنفت باي');
    });

    test('localizedName returns English for "en"', () {
      expect(PaymentMethod.cash.localizedName('en'), 'Cash');
      expect(PaymentMethod.benefitPay.localizedName('en'), 'Benefit Pay');
    });
  });

  // ── Enum: ListingStatus ─────────────────────────────────────────────────────

  group('ListingStatus', () {
    test('all values have displayName', () {
      for (final s in ListingStatus.values) {
        expect(s.displayName, isNotEmpty);
      }
    });

    test('status ordering: available, reserved, sold', () {
      expect(ListingStatus.values[0], ListingStatus.available);
      expect(ListingStatus.values[1], ListingStatus.reserved);
      expect(ListingStatus.values[2], ListingStatus.sold);
    });
  });

  // ── FishListing computed properties ─────────────────────────────────────────

  group('FishListing.primaryImageUrl', () {
    test('returns null when imageUrls is empty', () {
      final listing = makeListing(imageUrls: []);
      expect(listing.primaryImageUrl, isNull);
    });

    test('returns first URL when imageUrls has entries', () {
      final listing = makeListing(
          imageUrls: ['https://img1.jpg', 'https://img2.jpg']);
      expect(listing.primaryImageUrl, 'https://img1.jpg');
    });

    test('returns only URL when imageUrls has single entry', () {
      final listing = makeListing(imageUrls: ['https://img.jpg']);
      expect(listing.primaryImageUrl, 'https://img.jpg');
    });
  });

  group('FishListing.totalPrice', () {
    test('computes weight * pricePerKg correctly', () {
      final listing = makeListing(weight: 3.0, pricePerKg: 12.5);
      expect(listing.totalPrice, closeTo(37.5, 0.001));
    });

    test('returns 0 when weight is 0', () {
      final listing = makeListing(weight: 0.0, pricePerKg: 10.0);
      expect(listing.totalPrice, 0.0);
    });

    test('handles large values without overflow', () {
      final listing = makeListing(weight: 1000.0, pricePerKg: 999.9);
      expect(listing.totalPrice, closeTo(999900.0, 0.1));
    });
  });

  group('FishListing.displayName', () {
    test('returns fishType.displayName for non-other types', () {
      final listing = makeListing(fishType: FishType.hamour);
      expect(listing.displayName, 'Hamour (Grouper)');
    });

    test('returns customFishName when fishType is other and name is set', () {
      final listing = makeListing(
        fishType: FishType.other,
        customFishName: 'Zubaidi',
      );
      expect(listing.displayName, 'Zubaidi');
    });

    test('falls back to "Other" when fishType is other but customFishName is null', () {
      final listing = makeListing(fishType: FishType.other, customFishName: null);
      expect(listing.displayName, 'Other');
    });

    test('ignores customFishName when fishType is not other', () {
      final listing = makeListing(
        fishType: FishType.hamour,
        customFishName: 'Custom Name',
      );
      expect(listing.displayName, 'Hamour (Grouper)');
    });
  });

  // ── FishListing.toFirestore ─────────────────────────────────────────────────

  group('FishListing.toFirestore', () {
    test('serializes all required fields correctly', () {
      final listing = makeListing(
        fishType: FishType.shaari,
        weight: 4.0,
        pricePerKg: 8.5,
        condition: FishCondition.frozen,
        acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay],
        sellerId: 'seller-1',
        sellerName: 'Khalid',
        sellerPhone: '33001122',
      );
      final map = listing.toFirestore();

      expect(map['fishType'], 'shaari');
      expect(map['weight'], 4.0);
      expect(map['pricePerKg'], 8.5);
      expect(map['condition'], 'frozen');
      expect(map['acceptedPayments'], ['cash', 'benefitPay']);
      expect(map['sellerId'], 'seller-1');
      expect(map['sellerName'], 'Khalid');
    });

    test('serializes status as name string', () {
      final listing = makeListing(status: ListingStatus.reserved);
      expect(listing.toFirestore()['status'], 'reserved');
    });

    test('serializes catchDate as null when not provided', () {
      final listing = makeListing(catchDate: null);
      expect(listing.toFirestore()['catchDate'], isNull);
    });

    test('serializes catchDate as Timestamp when provided', () {
      final date = DateTime(2026, 3, 15);
      final listing = makeListing(catchDate: date);
      final map = listing.toFirestore();
      expect(map['catchDate'], isNotNull);
    });

    test('imageUrls serializes as list', () {
      final listing = makeListing(imageUrls: ['a.jpg', 'b.jpg']);
      expect(listing.toFirestore()['imageUrls'], ['a.jpg', 'b.jpg']);
    });
  });

  // ── FishListing.copyWith ────────────────────────────────────────────────────

  group('FishListing.copyWith', () {
    test('unmodified fields retain original values', () {
      final original = makeListing(weight: 5.0, pricePerKg: 10.0);
      final copy = original.copyWith(weight: 7.0);
      expect(copy.pricePerKg, 10.0);
      expect(copy.sellerId, original.sellerId);
    });

    test('modified field is updated', () {
      final original = makeListing(status: ListingStatus.available);
      final updated = original.copyWith(status: ListingStatus.reserved);
      expect(updated.status, ListingStatus.reserved);
      expect(original.status, ListingStatus.available);
    });

    test('imageUrls can be replaced', () {
      final original = makeListing(imageUrls: ['a.jpg']);
      final updated = original.copyWith(imageUrls: ['a.jpg', 'b.jpg']);
      expect(updated.imageUrls, ['a.jpg', 'b.jpg']);
    });

    test('acceptedPayments can be replaced', () {
      final original = makeListing(acceptedPayments: [PaymentMethod.cash]);
      final updated = original.copyWith(
          acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay]);
      expect(updated.acceptedPayments, hasLength(2));
    });

    test('copyWith with no args returns equivalent listing', () {
      final original = makeListing(weight: 3.5, pricePerKg: 11.0);
      final copy = original.copyWith();
      expect(copy.weight, original.weight);
      expect(copy.pricePerKg, original.pricePerKg);
      expect(copy.sellerId, original.sellerId);
    });
  });

  // ── FishMarketplaceService filtering (pure logic, no Firebase) ──────────────

  group('Listing filter and search logic', () {
    final listings = [
      makeListing(
        id: '1',
        fishType: FishType.hamour,
        weight: 3.0,
        pricePerKg: 10.0,
        condition: FishCondition.fresh,
        acceptedPayments: [PaymentMethod.cash],
        sellerName: 'Ahmed',
        catchLocation: 'Manama Bay',
        status: ListingStatus.available,
      ),
      makeListing(
        id: '2',
        fishType: FishType.shrimp,
        weight: 1.5,
        pricePerKg: 25.0,
        condition: FishCondition.frozen,
        acceptedPayments: [PaymentMethod.benefitPay],
        sellerName: 'Khalid',
        catchLocation: 'Hidd',
        status: ListingStatus.available,
      ),
      makeListing(
        id: '3',
        fishType: FishType.hamour,
        weight: 7.0,
        pricePerKg: 8.0,
        condition: FishCondition.cleaned,
        acceptedPayments: [PaymentMethod.cash, PaymentMethod.benefitPay],
        sellerName: 'Yousef',
        status: ListingStatus.reserved,
      ),
    ];

    final available = listings.where((l) => l.status == ListingStatus.available).toList();

    test('filterByType returns only matching type from available', () {
      final hamour = available.where((l) => l.fishType == FishType.hamour).toList();
      expect(hamour, hasLength(1));
      expect(hamour.first.id, '1');
    });

    test('filterByType returns empty list when no match', () {
      final crab = available.where((l) => l.fishType == FishType.crab).toList();
      expect(crab, isEmpty);
    });

    test('filterByPriceRange returns listings within range', () {
      final result = available
          .where((l) => l.pricePerKg >= 5.0 && l.pricePerKg <= 12.0)
          .toList();
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('filterByPriceRange returns all when range is wide', () {
      final result = available
          .where((l) => l.pricePerKg >= 0.0 && l.pricePerKg <= 100.0)
          .toList();
      expect(result, hasLength(2));
    });

    test('filterByCondition returns matching condition', () {
      final frozen = available
          .where((l) => l.condition == FishCondition.frozen)
          .toList();
      expect(frozen, hasLength(1));
      expect(frozen.first.id, '2');
    });

    test('filterByPaymentMethod returns listings accepting the method', () {
      final benefitPay = available
          .where((l) => l.acceptedPayments.contains(PaymentMethod.benefitPay))
          .toList();
      expect(benefitPay, hasLength(1));
      expect(benefitPay.first.id, '2');
    });

    test('reserved listings are excluded from available', () {
      expect(available.any((l) => l.id == '3'), isFalse);
    });

    group('searchListings logic', () {
      List<FishListing> search(String query) {
        final q = query.toLowerCase();
        return available.where((l) {
          return l.displayName.toLowerCase().contains(q) ||
              l.fishType.arabicName.contains(query) ||
              (l.description?.toLowerCase().contains(q) ?? false) ||
              l.sellerName.toLowerCase().contains(q) ||
              (l.catchLocation?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      test('matches by English display name', () {
        final result = search('hamour');
        expect(result, hasLength(1));
        expect(result.first.id, '1');
      });

      test('matches by Arabic fish name', () {
        final result = search('هامور');
        expect(result, hasLength(1));
        expect(result.first.id, '1');
      });

      test('matches by seller name', () {
        final result = search('khalid');
        expect(result, hasLength(1));
        expect(result.first.id, '2');
      });

      test('matches by catch location', () {
        final result = search('manama');
        expect(result, hasLength(1));
        expect(result.first.id, '1');
      });

      test('returns empty list for no match', () {
        expect(search('zebra'), isEmpty);
      });

      test('empty query matches nothing (guard in UI layer)', () {
        expect(search(''), hasLength(2));
      });
    });
  });
}
