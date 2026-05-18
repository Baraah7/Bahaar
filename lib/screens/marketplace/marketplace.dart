import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/marketplace/marketplace_localizations.dart';
import 'package:bahaar/models/fishing_log/trip_model.dart';
import 'package:bahaar/models/marketplace/fish_listing.dart';
import 'package:bahaar/providers/authentication/authentication_provider.dart';
import 'package:bahaar/services/fishing_log/trip_service.dart';
import 'package:bahaar/services/marketplace/fish_marketplace_service.dart';
import 'package:bahaar/widgets/marketplace/fish_details_sheet.dart';
import 'package:bahaar/widgets/marketplace/guest_locked_view.dart';
import 'package:bahaar/widgets/marketplace/header.dart';
import 'package:bahaar/widgets/marketplace/marketplace_tab.dart';
import 'package:bahaar/widgets/marketplace/order_success_dialog.dart';
import 'package:bahaar/widgets/marketplace/orders_tab.dart';
import 'package:bahaar/widgets/marketplace/sell_fish_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bahaar/services/notifications/notification_service.dart';
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

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _marketplaceService = FishMarketplaceService();
    _marketplaceService.addListener(_onMarketplaceUpdate);
    _loadRecentCatches();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeUserData());
  }

  @override
  void dispose() {
    _marketplaceService.removeListener(_onMarketplaceUpdate);
    _marketplaceService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onMarketplaceUpdate() {
    if (mounted) setState(() {});
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadRecentCatches() async {
    try {
      final uid = fb.FirebaseAuth.instance.currentUser?.uid;
      await TripService.instance.initialize(uid: uid);

      final trips = await TripService.instance.getAllTrips();
      final local = trips.expand((t) => t.catches).toList();
      final remote = await TripService.instance.fetchCatchesFromFirestore();

      final merged = <String, CatchEntry>{};
      for (final c in remote) { merged[c.id] = c; }
      for (final c in local) { merged[c.id] = c; }

      final all = merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) setState(() => _recentCatches = all.take(20).toList());
    } catch (_) {}
  }

  Future<void> _initializeUserData() async {
    final auth = ref.read(authProviderProvider);
    await auth.initializeAuthState();
    final user = auth.currentAppUser;
    if (user != null) {
      _marketplaceService.setCurrentUser(user.id);
      _marketplaceService.onNewSellerOrder = (order) {
        NotificationService.instance.showNewOrderNotification(
          buyerName: order.buyerName,
        );
      };
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = MarketplaceLocalizations.of(context);
    final auth = ref.watch(authProviderProvider);
    final user = auth.currentAppUser;
    final fullName =
        user != null ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim() : null;
    final displayName = fullName?.isNotEmpty == true ? fullName : user?.userName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            MarketplaceHeader(tabController: _tabController, l10n: l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MarketplaceTab(
                    marketplaceService: _marketplaceService,
                    onFishTap: _showFishDetails,
                  ),
                  auth.isGuest
                      ? GuestLockedView(
                          l10n: l10n,
                          onLogin: () => ref.read(authProviderProvider).logout(),
                        )
                      : Container(
                          color: Colors.grey.shade50,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: SellFishForm(
                              currentUserId: user?.id,
                              isGuest: false,
                              currentUserName: displayName,
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
                      currentUserName: displayName,
                      currentUserPhone: user?.phone,
                      currentUserLocation: user?.location,
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

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showFishDetails(FishListing listing) {
    final auth = ref.read(authProviderProvider);
    final user = auth.currentAppUser;
    final fullName =
        user != null ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FishDetailsSheet(
        listing: listing,
        currentUserId: user?.id,
        isGuest: auth.isGuest,
        currentUserName: fullName?.isNotEmpty == true ? fullName : user?.userName,
        currentUserPhone: user?.phone,
        currentUserLocation: user?.location,
        onBuy: (method, name, phone, location, proof, requestedKg) =>
            _processPurchase(listing, method, name, phone, location, proof, requestedKg),
      ),
    );
  }

  Future<void> _processPurchase(
    FishListing listing,
    PaymentMethod paymentMethod,
    String buyerName,
    String buyerPhone,
    String? buyerLocation,
    String? paymentProofImage,
    double requestedKg,
  ) async {
    final user = ref.read(authProviderProvider).currentAppUser;
    final l10n = MarketplaceLocalizations.of(context);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.pleaseLoginToOrder),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    try {
      await _marketplaceService.createOrder(
        listing: listing,
        buyerId: user.id,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        buyerLocation: buyerLocation,
        paymentMethod: paymentMethod,
        paymentProofImageUrl: paymentProofImage,
        requestedKg: requestedKg,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.unexpectedError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => OrderSuccessDialog(
          listing: listing,
          paymentMethod: paymentMethod,
          requestedKg: requestedKg,
          l10n: MarketplaceLocalizations.of(ctx),
          onDone: () {
            Navigator.pop(ctx);
            setState(() {});
          },
        ),
      );
    }
  }


  Future<void> _onListingSubmitted(
      FishListing listing, MarketplaceLocalizations l10n) async {
    await _marketplaceService.addListing(listing);
    _marketplaceService.setCurrentUser(listing.sellerId);
    setState(() {});
    _tabController.animateTo(0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
      ));
    }
  }
}
