import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/app_localizations.dart';
import 'package:bahaar/models/fishing/trip_model.dart';
import 'package:bahaar/models/marketplace/fish_listing.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/services/fishing%20log/trip_service.dart';
import 'package:bahaar/services/marketplace/fish_marketplace_service.dart';
import 'package:bahaar/widgets/marketplace/fish_details_sheet.dart';
import 'package:bahaar/widgets/marketplace/marketplace_tab.dart';
import 'package:bahaar/widgets/marketplace/orders_tab.dart';
import 'package:bahaar/widgets/marketplace/sell_fish_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

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

  List<CatchEntry> get _filteredCatches {
    final usedIds = _marketplaceService.listings
        .where((l) => l.fromCatchId != null)
        .map((l) => l.fromCatchId!)
        .toSet();
    return _recentCatches.where((c) => !usedIds.contains(c.id)).toList();
  }

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
      // Ensure TripService is scoped to the current Firebase user
      final uid = fb.FirebaseAuth.instance.currentUser?.uid;
      await TripService.instance.initialize(uid: uid);

      // Load from local SQLite
      final trips = await TripService.instance.getAllTrips();
      final local = trips.expand((t) => t.catches).toList();

      // Load from Firestore (account-based, works across devices)
      final remote = await TripService.instance.fetchCatchesFromFirestore();

      // Merge: deduplicate by ID, local takes precedence
      final merged = <String, CatchEntry>{};
      for (final c in remote) {
        merged[c.id] = c;
      }
      for (final c in local) {
        merged[c.id] = c;
      }

      final all = merged.values.toList()
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
                  authProvider.isGuest
                      ? _buildGuestLocked(l10n)
                      : Container(
                          color: Colors.grey.shade50,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: SellFishForm(
                              currentUserId: user?.id,
                              isGuest: false,
                              currentUserName: fullName?.isNotEmpty == true
                                  ? fullName
                                  : user?.userName,
                              currentUserPhone: user?.phone,
                              currentUserLocation: user?.location,
                              recentCatches: _filteredCatches,
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

  Widget _buildGuestLocked(AppLocalizations l10n) {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.signInToSell,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(authProviderProvider).logout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    l10n.logIn,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
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
            const SizedBox(height: 12),
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
        isGuest: authProvider.isGuest,
        currentUserName:
            fullName?.isNotEmpty == true ? fullName : user?.userName,
        currentUserPhone: user?.phone,
        currentUserLocation: user?.location,
        onBuy: (paymentMethod, buyerName, buyerPhone, buyerLocation,
                paymentProofImage) =>
            _processPurchase(listing, paymentMethod, buyerName, buyerPhone,
                buyerLocation, paymentProofImage),
        onDelete: () => _deleteListing(listing),
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
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginToOrder),
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
      final fishName = lang == 'ar' ? listing.fishType.arabicName : listing.displayName;
      showDialog(
        context: context,
        builder: (ctx) {
          final dl10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
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
                Text(dl10n.orderPlacedTitle, style: const TextStyle(fontSize: 20)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dl10n.youHaveOrderedFish(fishName),
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
                      _buildDialogRow(dl10n.weight, '${listing.weight.toStringAsFixed(1)} ${dl10n.kgUnit}'),
                      const Divider(height: 16),
                      _buildDialogRow(dl10n.total, '${listing.totalPrice.toStringAsFixed(2)} ${dl10n.bdUnit}'),
                      const Divider(height: 16),
                      _buildDialogRow(dl10n.payment, paymentMethod.localizedName(Localizations.localeOf(ctx).languageCode)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dl10n.waitingForSellerToAccept,
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
                    Navigator.pop(ctx);
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
                  child: Text(dl10n.done, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
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

  Future<void> _deleteListing(FishListing listing) async {
    await _marketplaceService.removeListing(listing.id);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.listingDeleted),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {});
    }
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
