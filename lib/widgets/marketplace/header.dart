import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/marketplace/marketplace_localizations.dart';
import 'package:flutter/material.dart';

class MarketplaceHeader extends StatelessWidget {
  final TabController tabController;
  final MarketplaceLocalizations l10n;

  const MarketplaceHeader({
    super.key,
    required this.tabController,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (Navigator.canPop(context))
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            else
              const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                splashBorderRadius: BorderRadius.circular(14),
                tabs: [
                  _tab(Icons.storefront_rounded, l10n.marketplace),
                  _tab(Icons.add_business_rounded, l10n.sellFish),
                  _tab(Icons.receipt_long_rounded, l10n.myOrders),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Tab _tab(IconData icon, String label) {
    return Tab(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
