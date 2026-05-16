import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../models/marketplace/fish_listing.dart';
import '../../models/marketplace/order_model.dart';

class FishMarketplaceService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<FishListing> _listings = [];
  List<Order> _orders = [];
  List<Order> _buyerOrdersList = [];
  List<Order> _sellerOrdersList = [];
  // Optimistic status changes that haven't been confirmed by Firestore yet.
  // Reapplied after every stream rebuild so stale snapshots can't undo them.
  final Map<String, OrderStatus> _pendingStatusUpdates = {};
  String? _currentUserId;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<QuerySnapshot>? _listingsSubscription;
  StreamSubscription<QuerySnapshot>? _buyerOrdersSubscription;
  StreamSubscription<QuerySnapshot>? _sellerOrdersSubscription;

  /// Called when a new pending order arrives for the current seller.
  ValueChanged<Order>? onNewSellerOrder;

  List<FishListing> get listings => List.unmodifiable(_listings);
  List<FishListing> get availableListings =>
      _listings.where((l) => l.status == ListingStatus.available).toList();
  List<Order> get orders => List.unmodifiable(_orders);

  List<Order> get sellerOrders => _orders
      .where((o) => o.sellerId == _currentUserId)
      .toList();

  List<Order> get buyerOrders => _orders
      .where((o) => o.buyerId == _currentUserId)
      .toList();

  List<Order> get pendingSellerOrders => sellerOrders
      .where((o) => o.status == OrderStatus.pending)
      .toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _startListeningToOrders();
    notifyListeners();
  }

  FishMarketplaceService() {
    _startListeningToListings();
  }

  void _startListeningToListings() {
    _listingsSubscription?.cancel();
    _listingsSubscription = _db
        .collection('listings')
        .orderBy('listedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _listings = snapshot.docs
            .map((doc) => FishListing.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load listings: $error';
        notifyListeners();
      },
    );
  }

  // Rebuilds _orders from the two stream lists. Called by both stream listeners
  // and by optimistic-update helpers so there is ONE merge path.
  void _mergeAndNotify() {
    final seen = <String>{};
    _orders = [..._buyerOrdersList, ..._sellerOrdersList]
        .where((o) => seen.add(o.id))
        .toList()
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt));

    // Re-apply optimistic updates that Firestore hasn't confirmed yet.
    // This prevents a stale stream snapshot from undoing the local change.
    final confirmed = <String>[];
    for (final entry in _pendingStatusUpdates.entries) {
      final i = _orders.indexWhere((o) => o.id == entry.key);
      if (i == -1) { continue; }
      if (_orders[i].status == entry.value) {
        confirmed.add(entry.key); // server confirmed — stop overriding
      } else {
        _orders[i] = _orders[i].copyWith(status: entry.value);
      }
    }
    for (final id in confirmed) _pendingStatusUpdates.remove(id);

    notifyListeners();
  }

  // Applies fn to every copy of the order that lives in any of our three lists.
  // This prevents a subsequent _mergeAndNotify() from reverting the optimistic change.
  void _applyToAllLists(String orderId, Order Function(Order) fn) {
    for (final list in [_buyerOrdersList, _sellerOrdersList, _orders]) {
      final i = list.indexWhere((o) => o.id == orderId);
      if (i != -1) list[i] = fn(list[i]);
    }
  }

  void _revertAllLists(String orderId, Order prev) {
    _pendingStatusUpdates.remove(orderId);
    for (final list in [_buyerOrdersList, _sellerOrdersList, _orders]) {
      final i = list.indexWhere((o) => o.id == orderId);
      if (i != -1) list[i] = prev;
    }
  }

  void _startListeningToOrders() {
    if (_currentUserId == null) return;

    _buyerOrdersSubscription?.cancel();
    _sellerOrdersSubscription?.cancel();

    // Reset stream lists so stale data doesn't survive a user switch.
    _buyerOrdersList = [];
    _sellerOrdersList = [];

    var sellerOrdersInitialized = false;
    final knownSellerOrderIds = <String>{};

    // Firestore rules require uid-filtered queries — split into buyer + seller streams
    _buyerOrdersSubscription = _db
        .collection('orders')
        .where('buyerId', isEqualTo: _currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        _buyerOrdersList =
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        _mergeAndNotify();
      },
      onError: (e) {
        _error = 'Failed to load orders: $e';
        notifyListeners();
      },
    );

    _sellerOrdersSubscription = _db
        .collection('orders')
        .where('sellerId', isEqualTo: _currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        final newList =
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        if (sellerOrdersInitialized) {
          for (final order in newList) {
            if (!knownSellerOrderIds.contains(order.id) &&
                order.status == OrderStatus.pending) {
              onNewSellerOrder?.call(order);
            }
          }
        }
        knownSellerOrderIds
          ..clear()
          ..addAll(newList.map((o) => o.id));
        sellerOrdersInitialized = true;
        _sellerOrdersList = newList;
        _mergeAndNotify();
      },
      onError: (e) {
        _error = 'Failed to load orders: $e';
        notifyListeners();
      },
    );
  }

  Future<void> refreshListings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('listings')
          .orderBy('listedAt', descending: true)
          .get();

      _listings = snapshot.docs
          .map((doc) => FishListing.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh listings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addListing(FishListing listing) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.collection('listings').add(listing.toFirestore());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add listing: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    try {
      await _db.collection('listings').doc(listingId).update({
        'status': status.name,
      });
    } catch (e) {
      _error = 'Failed to update listing status: $e';
      notifyListeners();
    }
  }

  Future<void> removeListing(String listingId) async {
    try {
      await _db.collection('listings').doc(listingId).delete();
    } catch (e) {
      _error = 'Failed to remove listing: $e';
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    _buyerOrdersList.removeWhere((o) => o.id == orderId);
    _sellerOrdersList.removeWhere((o) => o.id == orderId);
    _mergeAndNotify();
    try {
      await _db.collection('orders').doc(orderId).delete();
    } catch (e) {
      _error = 'Failed to delete order: $e';
      notifyListeners();
    }
  }

  Future<void> updateListing(FishListing listing) async {
    try {
      await _db.collection('listings').doc(listing.id).update(listing.toFirestore());
      await refreshListings();
    } catch (e) {
      _error = 'Failed to update listing: $e';
      notifyListeners();
      rethrow;
    }
  }

  List<FishListing> filterByType(FishType type) {
    return availableListings.where((l) => l.fishType == type).toList();
  }

  List<FishListing> filterByPriceRange(double minPrice, double maxPrice) {
    return availableListings
        .where((l) => l.pricePerKg >= minPrice && l.pricePerKg <= maxPrice)
        .toList();
  }

  List<FishListing> filterByCondition(FishCondition condition) {
    return availableListings.where((l) => l.condition == condition).toList();
  }

  List<FishListing> filterByPaymentMethod(PaymentMethod method) {
    return availableListings
        .where((l) => l.acceptedPayments.contains(method))
        .toList();
  }

  List<FishListing> searchListings(String query) {
    final lowerQuery = query.toLowerCase();
    return availableListings.where((l) {
      return l.displayName.toLowerCase().contains(lowerQuery) ||
          l.fishType.arabicName.contains(query) ||
          (l.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          l.sellerName.toLowerCase().contains(lowerQuery) ||
          (l.catchLocation?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  FishListing? getListingById(String id) {
    try {
      return _listings.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<FishListing?> fetchListingById(String id) async {
    try {
      final doc = await _db.collection('listings').doc(id).get();
      if (doc.exists) {
        return FishListing.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Failed to fetch listing: $e';
      return null;
    }
  }

  // Order Management
  Future<Order> createOrder({
    required FishListing listing,
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    String? buyerLocation,
    required PaymentMethod paymentMethod,
    String? paymentProofImageUrl,
    double? requestedKg,
  }) async {
    final orderData = {
      'listingId': listing.id,
      'sellerId': listing.sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerLocation': buyerLocation,
      'paymentMethod': paymentMethod.name,
      'paymentProofImageUrl': paymentProofImageUrl,
      'orderedAt': Timestamp.now(),
      'status': OrderStatus.pending.name,
      'sellerNote': null,
      'rejectionReason': null,
      'respondAt': null,
      'requestedKg': requestedKg,
    };

    final docRef = await _db.collection('orders').add(orderData);

    final effectiveKg = requestedKg ?? listing.weight;
    final isFullOrder = (listing.weight - effectiveKg).abs() < 0.001;
    if (isFullOrder) {
      await updateListingStatus(listing.id, ListingStatus.reserved);
    } else {
      // Partial purchase — subtract the requested amount, keep listing available.
      await _db.collection('listings').doc(listing.id).update({
        'weight': listing.weight - effectiveKg,
      });
    }

    final newOrder = Order(
      id: docRef.id,
      listingId: listing.id,
      sellerId: listing.sellerId,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerLocation: buyerLocation,
      paymentMethod: paymentMethod,
      paymentProofImageUrl: paymentProofImageUrl,
      orderedAt: DateTime.now(),
      requestedKg: requestedKg,
    );

    // Optimistically insert so the purchases tab shows the order immediately
    // without waiting for the Firestore stream to catch up.
    if (!_buyerOrdersList.any((o) => o.id == newOrder.id)) {
      _buyerOrdersList.insert(0, newOrder);
    }
    _mergeAndNotify();

    return newOrder;
  }

  Future<void> acceptOrder(String orderId, {String? note}) async {
    final prev = _orders.where((o) => o.id == orderId).firstOrNull;
    _pendingStatusUpdates[orderId] = OrderStatus.accepted;
    _applyToAllLists(
        orderId, (o) => o.copyWith(status: OrderStatus.accepted, sellerNote: note));
    notifyListeners();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.accepted.name,
        'sellerNote': note,
        'respondAt': Timestamp.now(),
      });
    } catch (e) {
      if (prev != null) _revertAllLists(orderId, prev);
      _error = 'Failed to accept order: $e';
      notifyListeners();
    }
  }

  Future<void> rejectOrder(String orderId, {String? reason}) async {
    final prev = _orders.where((o) => o.id == orderId).firstOrNull;
    _pendingStatusUpdates[orderId] = OrderStatus.rejected;
    _applyToAllLists(orderId,
        (o) => o.copyWith(status: OrderStatus.rejected, rejectionReason: reason));
    notifyListeners();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.rejected.name,
        'rejectionReason': reason,
        'respondAt': Timestamp.now(),
      });
      if (prev != null) {
        final listing = await fetchListingById(prev.listingId);
        if (listing != null) {
          final returnedKg = prev.requestedKg ?? listing.weight;
          final wasFullOrder = listing.status == ListingStatus.reserved;
          await _db.collection('listings').doc(prev.listingId).update({
            if (!wasFullOrder) 'weight': listing.weight + returnedKg,
            'status': ListingStatus.available.name,
          });
        }
      }
    } catch (e) {
      if (prev != null) _revertAllLists(orderId, prev);
      _error = 'Failed to reject order: $e';
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final prev = _orders.where((o) => o.id == orderId).firstOrNull;
    _pendingStatusUpdates[orderId] = OrderStatus.cancelled;
    _applyToAllLists(orderId, (o) => o.copyWith(status: OrderStatus.cancelled));
    notifyListeners();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        'respondAt': Timestamp.now(),
      });
      // Restore the purchased kg back to the listing so it becomes available again.
      if (prev != null) {
        final listing = await fetchListingById(prev.listingId);
        if (listing != null) {
          // If it was a full-order (listing was reserved), restore fully.
          // If partial, add back what the buyer had taken.
          final returnedKg = prev.requestedKg ?? listing.weight;
          final wasFullOrder = listing.status == ListingStatus.reserved;
          await _db.collection('listings').doc(prev.listingId).update({
            if (!wasFullOrder) 'weight': listing.weight + returnedKg,
            'status': ListingStatus.available.name,
          });
        }
      }
    } catch (e) {
      if (prev != null) _revertAllLists(orderId, prev);
      _error = 'Failed to cancel order: $e';
      notifyListeners();
    }
  }

  Future<void> resellOrder(String orderId) async {
    final listingId =
        _orders.where((o) => o.id == orderId).firstOrNull?.listingId;
    try {
      if (listingId != null) {
        await updateListingStatus(listingId, ListingStatus.available);
      }
    } catch (e) {
      _error = 'Failed to relist: $e';
      notifyListeners();
    }
  }

  Future<void> completeOrder(String orderId) async {
    final prev = _orders.where((o) => o.id == orderId).firstOrNull;
    _pendingStatusUpdates[orderId] = OrderStatus.completed;
    _applyToAllLists(orderId, (o) => o.copyWith(status: OrderStatus.completed));
    notifyListeners();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': OrderStatus.completed.name,
        'respondAt': Timestamp.now(),
      });
      if (prev != null) {
        // requestedKg is set only for partial orders (buyer chose less than full weight).
        // Full orders have requestedKg == null and the listing was marked reserved.
        // Partial orders keep the listing available with remaining weight — don't mark sold.
        final isPartialOrder = prev.requestedKg != null;
        if (!isPartialOrder) {
          await updateListingStatus(prev.listingId, ListingStatus.sold);
        }
        if (_currentUserId == prev.sellerId) {
          await _db.collection('users').doc(prev.sellerId).update({
            'total_sales': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      if (prev != null) _revertAllLists(orderId, prev);
      _error = 'Failed to complete order: $e';
      notifyListeners();
    }
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersForListing(String listingId) {
    return _orders.where((o) => o.listingId == listingId).toList();
  }

  List<FishListing> getSellerListings(String sellerId) {
    return _listings.where((l) => l.sellerId == sellerId).toList();
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    _buyerOrdersSubscription?.cancel();
    _sellerOrdersSubscription?.cancel();
    super.dispose();
  }
}
