import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../l10n/app_localizations.dart';
import 'package:Bahaar/utilities/cn/localization_helper.dart';

ImageProvider _resolveImage(String path) {
  if (path.startsWith('http')) return NetworkImage(path);
  return FileImage(File(path));
}

class FishCard extends StatelessWidget {
  final FishListing listing;
  final VoidCallback onTap;

  const FishCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(context),
            Expanded(child: _buildInfoSection(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return Stack(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: listing.primaryImageUrl != null
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF0D4F54), Color(0xFF0E7490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            image: listing.primaryImageUrl != null
                ? DecorationImage(
                    image: _resolveImage(listing.primaryImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: listing.primaryImageUrl == null
              ? Center(
                  child: Icon(
                    _getFishIcon(listing.fishType),
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              : null,
        ),
        if (listing.primaryImageUrl != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
        // Condition badge — Arabic-aware
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getConditionColor(listing.condition).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              listing.condition.localizedName(lang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        // Price tag — localized currency
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${_n(listing.totalPrice.toStringAsFixed(2), lang)} ${l10n.bdUnit}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF0D4F54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _n(String value, String lang) => arabicN(value, lang);

  Widget _buildInfoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    final primaryName = isAr ? listing.fishType.arabicName : listing.displayName;

    final weightStr = _n(listing.weight.toStringAsFixed(1), lang);
    final priceStr = _n(listing.pricePerKg.toStringAsFixed(1), lang);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              _buildBadge(
                '$weightStr ${l10n.kgUnit}',
                Icons.scale_rounded,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildBadge(
                  '$priceStr ${l10n.bdPerKg}',
                  Icons.sell_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D4F54).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0E7490)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0D4F54),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getFishIcon(FishType type) {
    switch (type) {
      case FishType.shrimp:
        return Icons.set_meal;
      case FishType.crab:
        return Icons.pest_control;
      default:
        return Icons.phishing;
    }
  }

  static Color _getConditionColor(FishCondition condition) {
    switch (condition) {
      case FishCondition.fresh:
        return const Color(0xFF059669);
      case FishCondition.frozen:
        return const Color(0xFF2563EB);
      case FishCondition.cleaned:
        return const Color(0xFF0D9488);
      case FishCondition.filleted:
        return const Color(0xFFD97706);
    }
  }
}
