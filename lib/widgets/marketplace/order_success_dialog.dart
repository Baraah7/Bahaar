import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/marketplace/marketplace_localizations.dart';
import 'package:bahaar/models/marketplace/fish_listing.dart';
import 'package:flutter/material.dart';

class OrderSuccessDialog extends StatelessWidget {
  final FishListing listing;
  final PaymentMethod paymentMethod;
  final MarketplaceLocalizations l10n;
  final VoidCallback onDone;
  final double? requestedKg;

  const OrderSuccessDialog({
    super.key,
    required this.listing,
    required this.paymentMethod,
    required this.l10n,
    required this.onDone,
    this.requestedKg,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final fishName =
        lang == 'ar' ? listing.fishType.arabicName : listing.displayName;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GreenHeader(fishName: fishName, title: l10n.orderPlacedTitle),
          _Body(
            listing: listing,
            paymentMethod: paymentMethod,
            lang: lang,
            l10n: l10n,
            onDone: onDone,
            requestedKg: requestedKg,
          ),
        ],
      ),
    );
  }
}

class _GreenHeader extends StatelessWidget {
  final String fishName;
  final String title;

  const _GreenHeader({required this.fishName, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fishName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final FishListing listing;
  final PaymentMethod paymentMethod;
  final String lang;
  final MarketplaceLocalizations l10n;
  final VoidCallback onDone;
  final double? requestedKg;

  const _Body({
    required this.listing,
    required this.paymentMethod,
    required this.lang,
    required this.l10n,
    required this.onDone,
    this.requestedKg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _Row(
                  label: l10n.weight,
                  value: '${(requestedKg ?? listing.weight).toStringAsFixed(1)} ${l10n.kgUnit}',
                ),
                Divider(height: 16, color: Colors.grey.shade200),
                _Row(
                  label: l10n.total,
                  value: '${((requestedKg ?? listing.weight) * listing.pricePerKg).toStringAsFixed(3)} ${l10n.bdUnit}',
                ),
                Divider(height: 16, color: Colors.grey.shade200),
                _Row(
                  label: l10n.payment,
                  value: paymentMethod.localizedName(lang),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded,
                  size: 14, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.waitingForSellerToAccept,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                l10n.done,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
