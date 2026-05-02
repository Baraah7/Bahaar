import 'package:flutter_test/flutter_test.dart';
import 'package:bahaar/models/marketplace/order_model.dart';
import 'package:bahaar/models/marketplace/fish_listing.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Order makeOrder({
  String id = 'order-1',
  String listingId = 'listing-1',
  String sellerId = 'seller-1',
  String buyerId = 'buyer-1',
  String buyerName = 'Fatima',
  String buyerPhone = '33001122',
  String? buyerLocation,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  String? paymentProofImageUrl,
  DateTime? orderedAt,
  OrderStatus status = OrderStatus.pending,
  String? sellerNote,
  String? rejectionReason,
  DateTime? respondedAt,
}) {
  return Order(
    id: id,
    listingId: listingId,
    sellerId: sellerId,
    buyerId: buyerId,
    buyerName: buyerName,
    buyerPhone: buyerPhone,
    buyerLocation: buyerLocation,
    paymentMethod: paymentMethod,
    paymentProofImageUrl: paymentProofImageUrl,
    orderedAt: orderedAt ?? DateTime(2026, 4, 1, 10, 0),
    status: status,
    sellerNote: sellerNote,
    rejectionReason: rejectionReason,
    respondedAt: respondedAt,
  );
}

void main() {
  // ── Enum: OrderStatus ───────────────────────────────────────────────────────

  group('OrderStatus', () {
    test('all values have English displayName', () {
      expect(OrderStatus.pending.displayName, 'Pending');
      expect(OrderStatus.accepted.displayName, 'Accepted');
      expect(OrderStatus.rejected.displayName, 'Rejected');
      expect(OrderStatus.completed.displayName, 'Completed');
      expect(OrderStatus.cancelled.displayName, 'Cancelled');
    });

    test('all values have Arabic arabicName', () {
      expect(OrderStatus.pending.arabicName, 'قيد الانتظار');
      expect(OrderStatus.accepted.arabicName, 'مقبول');
      expect(OrderStatus.rejected.arabicName, 'مرفوض');
      expect(OrderStatus.completed.arabicName, 'مكتمل');
      expect(OrderStatus.cancelled.arabicName, 'ملغى');
    });

    test('localizedName returns Arabic for "ar"', () {
      expect(OrderStatus.pending.localizedName('ar'), 'قيد الانتظار');
      expect(OrderStatus.completed.localizedName('ar'), 'مكتمل');
    });

    test('localizedName returns English for "en"', () {
      expect(OrderStatus.pending.localizedName('en'), 'Pending');
      expect(OrderStatus.completed.localizedName('en'), 'Completed');
    });

    test('localizedName returns English for unknown language code', () {
      expect(OrderStatus.accepted.localizedName('fr'), 'Accepted');
    });

    test('index ordering is pending < accepted < rejected < completed < cancelled', () {
      expect(OrderStatus.pending.index, lessThan(OrderStatus.accepted.index));
      expect(OrderStatus.accepted.index, lessThan(OrderStatus.rejected.index));
      expect(OrderStatus.rejected.index, lessThan(OrderStatus.completed.index));
      expect(OrderStatus.completed.index, lessThan(OrderStatus.cancelled.index));
    });
  });

  // ── Order constructor ───────────────────────────────────────────────────────

  group('Order constructor', () {
    test('sets all required fields correctly', () {
      final order = makeOrder();
      expect(order.id, 'order-1');
      expect(order.listingId, 'listing-1');
      expect(order.sellerId, 'seller-1');
      expect(order.buyerId, 'buyer-1');
      expect(order.buyerName, 'Fatima');
      expect(order.buyerPhone, '33001122');
      expect(order.paymentMethod, PaymentMethod.cash);
      expect(order.status, OrderStatus.pending);
    });

    test('optional fields default to null', () {
      final order = makeOrder();
      expect(order.buyerLocation, isNull);
      expect(order.paymentProofImageUrl, isNull);
      expect(order.sellerNote, isNull);
      expect(order.rejectionReason, isNull);
      expect(order.respondedAt, isNull);
    });

    test('default status is pending', () {
      final order = Order(
        id: 'x',
        listingId: 'y',
        sellerId: 's',
        buyerId: 'b',
        buyerName: 'Test',
        buyerPhone: '11112222',
        paymentMethod: PaymentMethod.cash,
        orderedAt: DateTime.now(),
      );
      expect(order.status, OrderStatus.pending);
    });
  });

  // ── Order.toFirestore ───────────────────────────────────────────────────────

  group('Order.toFirestore', () {
    test('serializes all required fields as correct types', () {
      final order = makeOrder(
        listingId: 'listing-99',
        sellerId: 'seller-99',
        buyerId: 'buyer-99',
        buyerName: 'Noor',
        buyerPhone: '33009988',
        paymentMethod: PaymentMethod.benefitPay,
        status: OrderStatus.accepted,
      );
      final map = order.toFirestore();

      expect(map['listingId'], 'listing-99');
      expect(map['sellerId'], 'seller-99');
      expect(map['buyerId'], 'buyer-99');
      expect(map['buyerName'], 'Noor');
      expect(map['buyerPhone'], '33009988');
      expect(map['paymentMethod'], 'benefitPay');
      expect(map['status'], 'accepted');
    });

    test('serializes status as enum name string', () {
      expect(makeOrder(status: OrderStatus.pending).toFirestore()['status'], 'pending');
      expect(makeOrder(status: OrderStatus.rejected).toFirestore()['status'], 'rejected');
      expect(makeOrder(status: OrderStatus.completed).toFirestore()['status'], 'completed');
      expect(makeOrder(status: OrderStatus.cancelled).toFirestore()['status'], 'cancelled');
    });

    test('serializes paymentMethod as enum name string', () {
      expect(
        makeOrder(paymentMethod: PaymentMethod.cash).toFirestore()['paymentMethod'],
        'cash',
      );
      expect(
        makeOrder(paymentMethod: PaymentMethod.benefitPay).toFirestore()['paymentMethod'],
        'benefitPay',
      );
    });

    test('respondAt is null when respondedAt is null', () {
      final map = makeOrder(respondedAt: null).toFirestore();
      expect(map['respondAt'], isNull);
    });

    test('respondAt is a Timestamp when respondedAt is set', () {
      final map = makeOrder(
        respondedAt: DateTime(2026, 4, 2, 15, 30),
      ).toFirestore();
      expect(map['respondAt'], isNotNull);
    });

    test('optional string fields serialize as null when absent', () {
      final map = makeOrder(
        buyerLocation: null,
        paymentProofImageUrl: null,
        sellerNote: null,
        rejectionReason: null,
      ).toFirestore();
      expect(map['buyerLocation'], isNull);
      expect(map['paymentProofImageUrl'], isNull);
      expect(map['sellerNote'], isNull);
      expect(map['rejectionReason'], isNull);
    });

    test('optional string fields serialize correctly when present', () {
      final map = makeOrder(
        buyerLocation: 'Riffa',
        paymentProofImageUrl: 'https://proof.jpg',
        sellerNote: 'Ready for pickup',
        rejectionReason: 'Already sold',
      ).toFirestore();
      expect(map['buyerLocation'], 'Riffa');
      expect(map['paymentProofImageUrl'], 'https://proof.jpg');
      expect(map['sellerNote'], 'Ready for pickup');
      expect(map['rejectionReason'], 'Already sold');
    });
  });

  // ── Order.copyWith ──────────────────────────────────────────────────────────

  group('Order.copyWith', () {
    test('unmodified fields retain original values', () {
      final original = makeOrder(buyerName: 'Fatima', buyerPhone: '33001122');
      final copy = original.copyWith(buyerName: 'Sara');
      expect(copy.buyerPhone, '33001122');
      expect(copy.sellerId, original.sellerId);
      expect(copy.listingId, original.listingId);
    });

    test('status can be updated via copyWith', () {
      final original = makeOrder(status: OrderStatus.pending);
      final updated = original.copyWith(status: OrderStatus.accepted);
      expect(updated.status, OrderStatus.accepted);
      expect(original.status, OrderStatus.pending);
    });

    test('sellerNote can be updated via copyWith', () {
      final original = makeOrder(sellerNote: null);
      final updated = original.copyWith(sellerNote: 'Come by tomorrow');
      expect(updated.sellerNote, 'Come by tomorrow');
    });

    test('rejectionReason can be updated via copyWith', () {
      final original = makeOrder(status: OrderStatus.pending);
      final updated = original.copyWith(
        status: OrderStatus.rejected,
        rejectionReason: 'Already sold to another buyer',
      );
      expect(updated.status, OrderStatus.rejected);
      expect(updated.rejectionReason, 'Already sold to another buyer');
    });

    test('respondedAt can be set via copyWith', () {
      final ts = DateTime(2026, 4, 2);
      final original = makeOrder(respondedAt: null);
      final updated = original.copyWith(respondedAt: ts);
      expect(updated.respondedAt, ts);
    });

    test('copyWith with no args returns equivalent order', () {
      final original = makeOrder(buyerName: 'Ali', status: OrderStatus.completed);
      final copy = original.copyWith();
      expect(copy.buyerName, original.buyerName);
      expect(copy.status, original.status);
      expect(copy.listingId, original.listingId);
    });
  });

  // ── Order lifecycle state transitions ───────────────────────────────────────

  group('Order lifecycle transitions via copyWith', () {
    test('pending → accepted transition is valid', () {
      final order = makeOrder(status: OrderStatus.pending);
      final accepted = order.copyWith(
        status: OrderStatus.accepted,
        sellerNote: 'Ready in the morning',
        respondedAt: DateTime.now(),
      );
      expect(accepted.status, OrderStatus.accepted);
      expect(accepted.sellerNote, isNotNull);
      expect(accepted.respondedAt, isNotNull);
    });

    test('pending → rejected transition carries reason', () {
      final order = makeOrder(status: OrderStatus.pending);
      final rejected = order.copyWith(
        status: OrderStatus.rejected,
        rejectionReason: 'Fish already sold',
        respondedAt: DateTime.now(),
      );
      expect(rejected.status, OrderStatus.rejected);
      expect(rejected.rejectionReason, 'Fish already sold');
    });

    test('accepted → completed transition is valid', () {
      final accepted = makeOrder(status: OrderStatus.accepted);
      final completed = accepted.copyWith(
        status: OrderStatus.completed,
        respondedAt: DateTime.now(),
      );
      expect(completed.status, OrderStatus.completed);
    });

    test('pending → cancelled transition is valid', () {
      final order = makeOrder(status: OrderStatus.pending);
      final cancelled = order.copyWith(status: OrderStatus.cancelled);
      expect(cancelled.status, OrderStatus.cancelled);
    });
  });
}
