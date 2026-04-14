import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../services/marketplace/fish_marketplace_service.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
import 'fish_card.dart';

class MarketplaceTab extends StatefulWidget {
  final FishMarketplaceService marketplaceService;
  final void Function(FishListing listing) onFishTap;

  const MarketplaceTab({
    super.key,
    required this.marketplaceService,
    required this.onFishTap,
  });

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  FishType? _selectedTypeFilter;
  FishCondition? _selectedConditionFilter;
  double? _minPrice;
  double? _maxPrice;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FishListing> get _filteredListings {
    var listings = widget.marketplaceService.availableListings;

    if (_searchQuery.isNotEmpty) {
      listings = widget.marketplaceService.searchListings(_searchQuery);
    }
    if (_selectedTypeFilter != null) {
      listings = listings.where((l) => l.fishType == _selectedTypeFilter).toList();
    }
    if (_selectedConditionFilter != null) {
      listings = listings.where((l) => l.condition == _selectedConditionFilter).toList();
    }
    if (_minPrice != null) {
      listings = listings.where((l) => l.pricePerKg >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      listings = listings.where((l) => l.pricePerKg <= _maxPrice!).toList();
    }

    return listings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MarketplaceLocalizations.of(context);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          _buildSearchArea(l10n),
          _buildFilterRow(l10n),
          Expanded(
            child: _filteredListings.isEmpty
                ? _buildEmptyState(l10n)
                : RefreshIndicator(
                    color: const Color(0xFF0E7490),
                    onRefresh: widget.marketplaceService.refreshListings,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _filteredListings.length,
                      itemBuilder: (context, index) {
                        return FishCard(
                          listing: _filteredListings[index],
                          onTap: () => widget.onFishTap(_filteredListings[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea(MarketplaceLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchFishSellerLocation,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildFilterRow(MarketplaceLocalizations l10n) {
    final lang = Localizations.localeOf(context).languageCode;
    final hasFilters = _selectedTypeFilter != null ||
        _selectedConditionFilter != null ||
        _minPrice != null ||
        _maxPrice != null;

    String? priceChipValue;
    if (_minPrice != null || _maxPrice != null) {
      final min = (_minPrice ?? 0).toStringAsFixed(0);
      final max = (_maxPrice ?? 50).toStringAsFixed(0);
      priceChipValue = l10n.priceRangeFilter(min, max);
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D4F54).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_rounded, size: 13, color: const Color(0xFF0D4F54)),
                        const SizedBox(width: 4),
                        Text(
                          '${[
                            if (_selectedTypeFilter != null) 1,
                            if (_selectedConditionFilter != null) 1,
                            if (_minPrice != null || _maxPrice != null) 1,
                          ].length} ${l10n.filtersActive}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D4F54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTypeFilter = null;
                        _selectedConditionFilter = null;
                        _minPrice = null;
                        _maxPrice = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, size: 13, color: Colors.red.shade600),
                          const SizedBox(width: 3),
                          Text(
                            l10n.clearFilters,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.type,
                  value: _selectedTypeFilter?.localizedName(lang),
                  icon: Icons.phishing_rounded,
                  onTap: () => _showTypeFilterSheet(l10n),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.condition,
                  value: _selectedConditionFilter?.localizedName(lang),
                  icon: Icons.verified_rounded,
                  onTap: () => _showConditionFilterSheet(l10n),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.priceRange,
                  value: priceChipValue,
                  icon: Icons.attach_money_rounded,
                  onTap: () => _showPriceFilterSheet(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isActive = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0D4F54) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF0D4F54) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFF0D4F54).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isActive ? 8 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              isActive ? '$label: $value' : label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }

  void _showTypeFilterSheet(MarketplaceLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.filterByFishType,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  ListTile(
                    leading: Icon(Icons.all_inclusive_rounded, color: Colors.grey.shade600),
                    title: Text(l10n.allTypes, style: const TextStyle(fontWeight: FontWeight.w500)),
                    selected: _selectedTypeFilter == null,
                    selectedTileColor: const Color(0xFF0D4F54).withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      setState(() => _selectedTypeFilter = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...FishType.values.map((type) => ListTile(
                        leading: Icon(
                          type == FishType.shrimp
                              ? Icons.set_meal_rounded
                              : type == FishType.crab
                                  ? Icons.pest_control_rounded
                                  : Icons.phishing_rounded,
                          color: const Color(0xFF0E7490),
                        ),
                        title: Text(type.localizedName(Localizations.localeOf(context).languageCode), style: const TextStyle(fontWeight: FontWeight.w500)),
                        selected: _selectedTypeFilter == type,
                        selectedTileColor: const Color(0xFF0D4F54).withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _selectedTypeFilter = type);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionFilterSheet(MarketplaceLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.filterByCondition,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.all_inclusive_rounded, color: Colors.grey.shade600),
              title: Text(l10n.allConditions, style: const TextStyle(fontWeight: FontWeight.w500)),
              selected: _selectedConditionFilter == null,
              selectedTileColor: const Color(0xFF0D4F54).withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                setState(() => _selectedConditionFilter = null);
                Navigator.pop(context);
              },
            ),
            ...FishCondition.values.map((condition) => ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getConditionColor(condition).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_rounded, size: 18, color: _getConditionColor(condition)),
                  ),
                  title: Text(condition.localizedName(Localizations.localeOf(context).languageCode), style: const TextStyle(fontWeight: FontWeight.w500)),
                  selected: _selectedConditionFilter == condition,
                  selectedTileColor: const Color(0xFF0D4F54).withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _selectedConditionFilter = condition);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showPriceFilterSheet(MarketplaceLocalizations l10n) {
    double tempMin = _minPrice ?? 0;
    double tempMax = _maxPrice ?? 50;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.priceRange,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() { _minPrice = null; _maxPrice = null; });
                      Navigator.pop(context);
                    },
                    child: Text(l10n.allPrices, style: const TextStyle(color: Color(0xFF0E7490))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tempMin.toStringAsFixed(0)} ${l10n.bdPerKg}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D4F54), fontSize: 15),
                  ),
                  Text(
                    '${tempMax.toStringAsFixed(0)} ${l10n.bdPerKg}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D4F54), fontSize: 15),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(tempMin, tempMax),
                min: 0,
                max: 50,
                divisions: 50,
                activeColor: const Color(0xFF0D4F54),
                inactiveColor: const Color(0xFF0D4F54).withValues(alpha: 0.15),
                onChanged: (values) => setSheetState(() {
                  tempMin = values.start;
                  tempMax = values.end;
                }),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = tempMin > 0 ? tempMin : null;
                      _maxPrice = tempMax < 50 ? tempMax : null;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4F54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l10n.confirm, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(MarketplaceLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0D4F54).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFishListingsFound,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryAdjustingFilters,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(FishCondition condition) {
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
