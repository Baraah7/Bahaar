import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/fish_marketplace_service.dart';
import '../../l10n/app_localizations.dart';
import 'order_card.dart';

class OrdersTab extends StatelessWidget {
  final FishMarketplaceService marketplaceService;
  final String? currentUserId;

  const OrdersTab({
    super.key,
    required this.marketplaceService,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (currentUserId == null) {
      return _buildLoginPrompt(context, l10n);
    }

    final sellerOrders = marketplaceService.orders
        .where((o) => o.sellerId == currentUserId)
        .toList();
    final buyerOrders = marketplaceService.orders
        .where((o) => o.buyerId == currentUserId)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildOrdersTabBar(sellerOrders.length, buyerOrders.length, l10n),
          Expanded(
            child: TabBarView(
              children: [
                _OrdersList(
                  orders: sellerOrders,
                  isSeller: true,
                  l10n: l10n,
                  marketplaceService: marketplaceService,
                ),
                _OrdersList(
                  orders: buyerOrders,
                  isSeller: false,
                  l10n: l10n,
                  marketplaceService: marketplaceService,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4F54).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.login, size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.pleaseLoginToViewOrders,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTabBar(int sellerCount, int buyerCount, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: const Color(0xFF0D4F54),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sell_outlined, size: 18),
                const SizedBox(width: 6),
                Text(l10n.sellingTab(sellerCount)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 18),
                const SizedBox(width: 6),
                Text(l10n.purchasesTab(buyerCount)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final bool isSeller;
  final AppLocalizations l10n;
  final FishMarketplaceService marketplaceService;

  const _OrdersList({
    required this.orders,
    required this.isSeller,
    required this.l10n,
    required this.marketplaceService,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return _buildEmptyOrders();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final listing = marketplaceService.getListingById(order.listingId);
        return OrderCard(
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
          onComplete: isSeller && order.status == OrderStatus.accepted
              ? () => _completeOrder(context, order)
              : null,
          onCancel: !isSeller && order.status == OrderStatus.pending
              ? () => _showCancelDialog(context, order)
              : null,
          onViewPaymentProof: (imagePath) =>
              _showPaymentProofFullScreen(context, imagePath),
        );
      },
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4F54).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSeller ? Icons.store_outlined : Icons.shopping_cart_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSeller ? l10n.noOrdersForListings : l10n.noPurchasesYet,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSeller
                ? l10n.whenSomeoneOrdersYourFish
                : l10n.yourPurchasesWillAppear,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _acceptOrder(BuildContext context, Order order) async {
    await marketplaceService.acceptOrder(order.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderAccepted),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showRejectDialog(BuildContext context, Order order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.areYouSureRejectOrder),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.reasonOptional,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await marketplaceService.rejectOrder(
                order.id,
                reason: reasonController.text.isEmpty
                    ? null
                    : reasonController.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.orderRejected),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.reject, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelOrder),
        content: Text(l10n.confirmCancelOrder),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await marketplaceService.cancelOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.orderCancelled),
                    backgroundColor: Colors.grey.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderCompleted),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showPaymentProofFullScreen(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.paymentProof,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
