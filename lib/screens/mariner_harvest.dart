import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace/fish_listing.dart';
import '../models/fishing/trip_model.dart';
import '../services/marketplace/fish_marketplace_service.dart';
import '../services/fishing/trip_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/marketplace/marketplace_tab.dart';
import '../widgets/marketplace/sell_fish_form.dart';
import '../widgets/marketplace/fish_details_sheet.dart';
import '../widgets/marketplace/orders_tab.dart';
import '../providers/authentication_provider.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

class MarinerHarvestPage extends ConsumerStatefulWidget {
  const MarinerHarvestPage({super.key});

  @override
  ConsumerState<MarinerHarvestPage> createState() => _MarinerHarvestPageState();
}

class _MarinerHarvestPageState extends ConsumerState<MarinerHarvestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FishMarketplaceService _marketplaceService;
  List<CatchEntry> _recentCatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _marketplaceService = FishMarketplaceService();
    _marketplaceService.addListener(_onMarketplaceUpdate);
    _loadRecentCatches();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  Future<void> _loadRecentCatches() async {
    try {
      final trips = await TripService.instance.getAllTrips();
      // Flatten all catches, sort newest first, keep last 20
      final all = trips
          .expand((t) => t.catches)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted) {
        setState(() => _recentCatches = all.take(20).toList());
      }
    } catch (_) {}
  }

  void _onMarketplaceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeUserData() async {
    final authProvider = ref.read(authProviderProvider);
    await authProvider.initializeAuthState();
    final user = authProvider.currentAppUser;
    if (user != null) {
      _marketplaceService.setCurrentUser(user.id);
    }
  }

  @override
  void dispose() {
    _marketplaceService.removeListener(_onMarketplaceUpdate);
    _marketplaceService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = ref.watch(authProviderProvider);
    final user = authProvider.currentAppUser;
    final fullName = user != null
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            _buildGradientHeader(l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MarketplaceTab(
                    marketplaceService: _marketplaceService,
                    onFishTap: (listing) => _showFishDetails(listing),
                  ),
                  Container(
                    color: Colors.grey.shade50,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: SellFishForm(
                        currentUserId: user?.id,
                        currentUserName: fullName?.isNotEmpty == true
                            ? fullName
                            : user?.userName,
                        currentUserPhone: user?.phone,
                        currentUserLocation: user?.location,
                        recentCatches: _recentCatches,
                        onSubmit: (listing) =>
                            _onListingSubmitted(listing, l10n),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey.shade50,
                    child: OrdersTab(
                      marketplaceService: _marketplaceService,
                      currentUserId: user?.id,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sailing_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.marinerHarvest,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                splashBorderRadius: BorderRadius.circular(14),
                tabs: [
                  Tab(
                    height: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(l10n.marketplace),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_business_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(l10n.sellFish),
                      ],
                    ),
                  ),
                  Tab(
                    height: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(l10n.myOrders),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showFishDetails(FishListing listing) {
    final authProvider = ref.read(authProviderProvider);
    final user = authProvider.currentAppUser;
    final fullName = user != null
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FishDetailsSheet(
        listing: listing,
        currentUserId: user?.id,
        currentUserName:
            fullName?.isNotEmpty == true ? fullName : user?.userName,
        currentUserPhone: user?.phone,
        currentUserLocation: user?.location,
        onBuy: (paymentMethod, buyerName, buyerPhone, buyerLocation,
                paymentProofImage) =>
            _processPurchase(listing, paymentMethod, buyerName, buyerPhone,
                buyerLocation, paymentProofImage),
      ),
    );
  }

  void _processPurchase(
    FishListing listing,
    PaymentMethod paymentMethod,
    String buyerName,
    String buyerPhone,
    String? buyerLocation,
    String? paymentProofImage,
  ) async {
    final authProvider = ref.read(authProviderProvider);
    final user = authProvider.currentAppUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login to place an order'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.pop(context);

    await _marketplaceService.createOrder(
      listing: listing,
      buyerId: user.id,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerLocation: buyerLocation,
      paymentMethod: paymentMethod,
      paymentProofImageUrl: paymentProofImage,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Order Placed!', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have ordered ${listing.displayName}',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Weight', '${listing.weight.toStringAsFixed(1)} kg'),
                    const Divider(height: 16),
                    _buildDialogRow('Total', '${listing.totalPrice.toStringAsFixed(2)} BD'),
                    const Divider(height: 16),
                    _buildDialogRow('Payment', paymentMethod.displayName),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Waiting for seller to accept your order.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Future<void> _onListingSubmitted(
      FishListing listing, AppLocalizations l10n) async {
    await _marketplaceService.addListing(listing);
    _marketplaceService.setCurrentUser(listing.sellerId);
    setState(() {});
    _tabController.animateTo(0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(l10n.yourFishListingPosted),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
