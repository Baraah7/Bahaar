import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/marketplace/order_model.dart';
import '../../services/marketplace/fish_marketplace_service.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
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
    final l10n = MarketplaceLocalizations.of(context);

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

  Widget _buildLoginPrompt(BuildContext context, MarketplaceLocalizations l10n) {
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

  Widget _buildOrdersTabBar(int sellerCount, int buyerCount, MarketplaceLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TabBar(
        indicator: BoxDecoration(
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
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF0D4F54),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        splashBorderRadius: BorderRadius.circular(12),
        tabs: [
          _buildTab(
            icon: Icons.sell_outlined,
            label: l10n.sellingTab(sellerCount),
            count: sellerCount,
          ),
          _buildTab(
            icon: Icons.shopping_bag_outlined,
            label: l10n.purchasesTab(buyerCount),
            count: buyerCount,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required IconData icon, required String label, required int count}) {
    return Tab(
      height: 46,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  final bool isSeller;
  final MarketplaceLocalizations l10n;
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
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectOrder, style: const TextStyle(color: AppColors.brown)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.areYouSureRejectOrder, style: const TextStyle(fontSize: 16, color: AppColors.brown)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelStyle: const TextStyle(color: AppColors.brown),
                  labelText: l10n.reasonOptional,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tan, width: 2),
                  ),
                ),
                maxLines: 3,
                minLines: 2,
                style: const TextStyle(fontSize: 14, color: AppColors.brown),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 16, color: AppColors.brown),),
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
                    content: Text(l10n.orderRejected, style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
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
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.cancelOrder, style: const TextStyle(color: AppColors.brown)),
        content: Text(l10n.confirmCancelOrder, style: const TextStyle(color: AppColors.brown)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.brown)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await marketplaceService.cancelOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.orderCancelled, style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderCompleted, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.paymentProof,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
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
}
