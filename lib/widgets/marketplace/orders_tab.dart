import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/fish_marketplace_service.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
import 'order_card.dart';
import 'sell_fish_form.dart';

// ── Unified list item ────────────────────────────────────────────────────────

class _TabItem {
  final DateTime date;
  final FishListing? listing;
  final Order? order;

  _TabItem.listing(FishListing l)
      : listing = l,
        order = null,
        date = l.listedAt;

  _TabItem.order(Order o)
      : listing = null,
        order = o,
        date = o.orderedAt;
}

// ── Orders tab (holds search + filter state) ─────────────────────────────────

class OrdersTab extends StatefulWidget {
  final FishMarketplaceService marketplaceService;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;

  const OrdersTab({
    super.key,
    required this.marketplaceService,
    this.currentUserId,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
  });

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  String _search = '';
  // null = all | 'listed' | OrderStatus.name
  String? _filterKey;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    widget.marketplaceService.addListener(_onServiceUpdate);
  }

  @override
  void didUpdateWidget(OrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketplaceService != widget.marketplaceService) {
      oldWidget.marketplaceService.removeListener(_onServiceUpdate);
      widget.marketplaceService.addListener(_onServiceUpdate);
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    widget.marketplaceService.removeListener(_onServiceUpdate);
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _showSearchDialog(BuildContext context, MarketplaceLocalizations l10n) {
    final controller = TextEditingController(text: _search);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.fromLTRB(20, 90, 20, 0),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchOrders,
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 22),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (_, val, __) => val.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                controller.clear();
                                setState(() => _search = '');
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => setState(() => _search = v),
                  onSubmitted: (_) => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.done,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, MarketplaceLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterByStatus,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(null, l10n.allStatuses, ctx),
                _chip('listed', 'Listed', ctx),
                _chip(OrderStatus.pending.name, l10n.pending, ctx),
                _chip(OrderStatus.accepted.name, l10n.accepted, ctx),
                _chip(OrderStatus.rejected.name, l10n.rejected, ctx),
                _chip(OrderStatus.completed.name, l10n.completed, ctx),
                _chip(OrderStatus.cancelled.name, l10n.cancelled, ctx),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String? key, String label, BuildContext sheetCtx) {
    final selected = _filterKey == key;
    return GestureDetector(
      onTap: () {
        setState(() => _filterKey = key);
        Navigator.pop(sheetCtx);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _segmentedTab({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    if (selected) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D4F54), Color(0xFF0E7490)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D4F54).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Icon(icon, size: 18, color: const Color(0xFF0D4F54)),
        ),
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: active ? AppColors.primary : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            color: active ? Colors.white : Colors.grey.shade600,
            size: 19),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MarketplaceLocalizations.of(context);

    if (widget.currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF0D4F54).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.login, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.pleaseLoginToViewOrders,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final sellerOrders = widget.marketplaceService.orders
        .where((o) => o.sellerId == widget.currentUserId)
        .toList();
    final sellerListings = widget.marketplaceService.listings
        .where((l) =>
            l.sellerId == widget.currentUserId &&
            l.status == ListingStatus.available)
        .toList();
    final buyerOrders = widget.marketplaceService.orders
        .where((o) =>
            o.buyerId == widget.currentUserId &&
            o.status != OrderStatus.cancelled)
        .toList();

    final tabIdx = _tabController.index;

    return Column(
      children: [
        // ── Single row: segmented tabs + search + filter ──────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _segmentedTab(
                        icon: Icons.sell_outlined,
                        label: l10n.sellingTab(
                            sellerOrders.length + sellerListings.length),
                        selected: tabIdx == 0,
                        onTap: () => _tabController.animateTo(0),
                      ),
                      _segmentedTab(
                        icon: Icons.shopping_bag_outlined,
                        label:
                            l10n.purchasesTab(buyerOrders.length),
                        selected: tabIdx == 1,
                        onTap: () => _tabController.animateTo(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.search_rounded,
                active: _search.isNotEmpty,
                onTap: () => _showSearchDialog(context, l10n),
              ),
              const SizedBox(width: 6),
              _iconBtn(
                icon: Icons.tune_rounded,
                active: _filterKey != null,
                onTap: () => _showFilterSheet(context, l10n),
              ),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OrdersList(
                orders: sellerOrders,
                listings: sellerListings,
                isSeller: true,
                l10n: l10n,
                marketplaceService: widget.marketplaceService,
                search: _search,
                filterKey: _filterKey,
                currentUserName: widget.currentUserName,
                currentUserPhone: widget.currentUserPhone,
                currentUserLocation: widget.currentUserLocation,
                onRefresh: widget.marketplaceService.refreshListings,
              ),
              _OrdersList(
                orders: buyerOrders,
                isSeller: false,
                l10n: l10n,
                marketplaceService: widget.marketplaceService,
                search: _search,
                filterKey: _filterKey,
                onRefresh: widget.marketplaceService.refreshListings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Orders list ──────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final List<FishListing> listings;
  final bool isSeller;
  final MarketplaceLocalizations l10n;
  final FishMarketplaceService marketplaceService;
  final String search;
  final String? filterKey;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final Future<void> Function() onRefresh;

  const _OrdersList({
    required this.orders,
    required this.isSeller,
    required this.l10n,
    required this.marketplaceService,
    required this.search,
    required this.onRefresh,
    this.listings = const [],
    this.filterKey,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
  });

  List<_TabItem> _visibleItems() {
    final items = <_TabItem>[];

    // Include listing entries if filter is 'all' or 'listed'
    if (filterKey == null || filterKey == 'listed') {
      for (final l in listings) {
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          final matches =
              l.fishType.arabicName.toLowerCase().contains(q) ||
                  l.displayName.toLowerCase().contains(q) ||
                  (l.description?.toLowerCase().contains(q) ?? false);
          if (!matches) continue;
        }
        items.add(_TabItem.listing(l));
      }
    }

    // Include orders if filter is not 'listed'
    if (filterKey != 'listed') {
      for (final o in orders) {
        if (!isSeller && o.status == OrderStatus.cancelled) continue;
        if (filterKey != null && o.status.name != filterKey) continue;
        if (search.isNotEmpty) {
          final listing = marketplaceService.getListingById(o.listingId);
          final name = (listing?.displayName ?? '').toLowerCase();
          final arName =
              (listing?.fishType.arabicName ?? '').toLowerCase();
          final party = o.buyerName.toLowerCase();
          final q = search.toLowerCase();
          if (!name.contains(q) &&
              !arName.contains(q) &&
              !party.contains(q)) { continue; }
        }
        items.add(_TabItem.order(o));
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _resellOrder(BuildContext context, Order order) async {
    await marketplaceService.resellOrder(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.listingRelistedSuccess),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // Permanently removes both listing and order from Firestore
  void _removeListing(BuildContext context, Order order) async {
    await marketplaceService.removeListing(order.listingId);
    await marketplaceService.deleteOrder(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.listingDeleted),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _acceptOrder(BuildContext context, Order order) async {
    await marketplaceService.acceptOrder(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.orderAccepted),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showRejectDialog(BuildContext context, Order order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectOrder,
            style: const TextStyle(color: AppColors.brown)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.areYouSureRejectOrder,
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.brown)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelStyle:
                      const TextStyle(color: AppColors.brown),
                  labelText: l10n.reasonOptional,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.tan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.tan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.tan, width: 2),
                  ),
                ),
                maxLines: 3,
                minLines: 2,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.brown),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.brown)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await marketplaceService.rejectOrder(order.id,
                  reason: reasonController.text.isEmpty
                      ? null
                      : reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.orderRejected,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.reject,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelOrder,
            style: const TextStyle(color: AppColors.brown)),
        content: Text(l10n.confirmCancelOrder,
            style: const TextStyle(color: AppColors.brown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.brown)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await marketplaceService.cancelOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.orderCancelled,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.cancelOrder,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _completeOrder(BuildContext context, Order order) async {
    await marketplaceService.completeOrder(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.orderCompleted,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showPaymentProofFullScreen(BuildContext context, String imagePath) {
    final ImageProvider imageProvider = imagePath.startsWith('http')
        ? NetworkImage(imagePath) as ImageProvider
        : FileImage(File(imagePath));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.paymentProof,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems();

    if (items.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0E7490),
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D4F54)
                            .withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSeller
                            ? Icons.store_outlined
                            : Icons.shopping_cart_outlined,
                        size: 56,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isSeller
                          ? l10n.noOrdersForListings
                          : l10n.noPurchasesYet,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSeller
                          ? l10n.whenSomeoneOrdersYourFish
                          : l10n.yourPurchasesWillAppear,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0E7490),
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          if (item.listing != null) {
            return _ListingCard(
              key: ValueKey('listing_${item.listing!.id}'),
              listing: item.listing!,
              marketplaceService: marketplaceService,
              l10n: l10n,
              currentUserName: currentUserName,
              currentUserPhone: currentUserPhone,
              currentUserLocation: currentUserLocation,
            );
          }

          final order = item.order!;
          final listing =
              marketplaceService.getListingById(order.listingId);
          return OrderCard(
            key: ValueKey(order.id),
            order: order,
            listing: listing,
            isSeller: isSeller,
            l10n: l10n,
            onAccept: isSeller && order.status == OrderStatus.pending
                ? () => _acceptOrder(context, order)
                : null,
            onReject: isSeller && order.status == OrderStatus.pending
                ? () => _showRejectDialog(context, order)
                : null,
            onComplete:
                isSeller && order.status == OrderStatus.accepted
                    ? () => _completeOrder(context, order)
                    : null,
            onCancel:
                !isSeller && order.status == OrderStatus.pending
                    ? () => _showCancelDialog(context, order)
                    : null,
            onResell:
                isSeller && order.status == OrderStatus.cancelled
                    ? () => _resellOrder(context, order)
                    : null,
            onRemoveListing:
                isSeller && order.status == OrderStatus.cancelled
                    ? () => _removeListing(context, order)
                    : null,
            onViewPaymentProof: (imagePath) =>
                _showPaymentProofFullScreen(context, imagePath),
          );
        },
      ),
    );
  }
}

// ── Listing card (same visual style as OrderCard) ────────────────────────────

class _ListingCard extends StatefulWidget {
  final FishListing listing;
  final FishMarketplaceService marketplaceService;
  final MarketplaceLocalizations l10n;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;

  const _ListingCard({
    super.key,
    required this.listing,
    required this.marketplaceService,
    required this.l10n,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _expanded = false;

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تعديل الإدراج',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  child: SellFishForm(
                    initialListing: widget.listing,
                    currentUserId: widget.listing.sellerId,
                    currentUserName: widget.currentUserName,
                    currentUserPhone: widget.currentUserPhone,
                    currentUserLocation: widget.currentUserLocation,
                    isGuest: false,
                    onSubmit: (newListing) async {
                      await widget.marketplaceService.updateListing(
                        newListing.copyWith(
                          id: widget.listing.id,
                          listedAt: widget.listing.listedAt,
                          fromCatchId: newListing.fromCatchId ??
                              widget.listing.fromCatchId,
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الإدراج',
            style: TextStyle(color: AppColors.brown)),
        content: const Text(
            'هل أنت متأكد من حذف هذا الإدراج؟',
            style: TextStyle(color: AppColors.brown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.l10n.cancel,
                style: const TextStyle(color: AppColors.brown)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.marketplaceService
                  .removeListing(widget.listing.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                  content: Text(widget.l10n.listingDeleted),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final listingName = isAr
        ? widget.listing.fishType.arabicName
        : widget.listing.displayName;
    final totalPrice = widget.listing.totalPrice;
    const statusColor = Color.fromARGB(255, 216, 151, 76);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Tappable header (mirrors OrderCard) ──────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.12),
                    statusColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(
                        top: Radius.circular(20))
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sell_rounded,
                        color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          listingName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} ${widget.l10n.bdUnit}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF1E293B)
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              statusColor.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Listed',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ───────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Details block
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              _infoRow(
                                Icons.scale_rounded,
                                '${widget.listing.weight} كغ',
                              ),
                              Divider(
                                  height: 16,
                                  color: Colors.grey.shade200),
                              _infoRow(
                                Icons.payments_outlined,
                                '${widget.listing.pricePerKg.toStringAsFixed(3)} د.ب / كغ',
                              ),
                              Divider(
                                  height: 16,
                                  color: Colors.grey.shade200),
                              _infoRow(
                                Icons.water_drop_outlined,
                                widget.listing.condition
                                    .arabicName,
                              ),
                              if (widget.listing.description !=
                                  null) ...[
                                Divider(
                                    height: 16,
                                    color: Colors.grey.shade200),
                                _infoRow(
                                  Icons.notes_rounded,
                                  widget.listing.description!,
                                ),
                              ],
                              if (widget.listing.catchLocation !=
                                  null) ...[
                                Divider(
                                    height: 16,
                                    color: Colors.grey.shade200),
                                _infoRow(
                                  Icons.location_on_outlined,
                                  widget.listing.catchLocation!,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Edit + Delete buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _confirmDelete(context),
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 17),
                                label: const Text('حذف'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.red
                                      .withValues(alpha: 0.8),
                                  backgroundColor: AppColors.red
                                      .withValues(alpha: 0.12),
                                  side: BorderSide(
                                      color: AppColors.red
                                          .withValues(alpha: 0.3)),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openEditSheet(context),
                                icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 17),
                                label: const Text('تعديل'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors
                                      .primary
                                      .withValues(alpha: 0.8),
                                  backgroundColor: AppColors
                                      .primary
                                      .withValues(alpha: 0.12),
                                  side: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3)),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF374151)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}
