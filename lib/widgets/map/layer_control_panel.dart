import 'package:flutter/material.dart';
import 'package:bahaar/services/map/map_layer_manager.dart';
import 'package:bahaar/widgets/map/geojson_layers.dart';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/map/map_localizations.dart';

/// Control panel widget for managing all map layers
class LayerControlPanel extends StatefulWidget {
  final MapLayerManager layerManager;
  final GeoJsonLayerBuilder? geoJsonBuilder;
  final bool maskInitialized;
  final VoidCallback onClose;
  final VoidCallback? onEnterAdminEdit;
  final VoidCallback? onEnterFeatureEdit;
  final VoidCallback? onEnterOutlineEdit;
  final VoidCallback? onOpenPrediction;

  const LayerControlPanel({
    super.key,
    required this.layerManager,
    this.geoJsonBuilder,
    required this.maskInitialized,
    required this.onClose,
    this.onEnterAdminEdit,
    this.onEnterFeatureEdit,
    this.onEnterOutlineEdit,
    this.onOpenPrediction,
  });

  @override
  State<LayerControlPanel> createState() => _LayerControlPanelState();
}

class _LayerControlPanelState extends State<LayerControlPanel> {
  @override
  void initState() {
    super.initState();
    widget.layerManager.addListener(_onLayerChange);
  }

  @override
  void dispose() {
    widget.layerManager.removeListener(_onLayerChange);
    super.dispose();
  }

  void _onLayerChange() => setState(() {});

  MapLocalizations get _l10n => MapLocalizations.of(context);

  MapLayerManager get lm => widget.layerManager;

  // ────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSection(
                    key: 'depth',
                    title: _l10n.depthVisualization,
                    icon: Icons.water_drop_outlined,
                    color: AppColors.red,
                    isActive: lm.showDepthLayer,
                    toggleValue: lm.showDepthLayer,
                    onToggle: (val) => lm.showDepthLayer = val,
                    content: _buildDepthContent(),
                  ),
                  _buildSection(
                    key: 'protected',
                    title: _l10n.protectedExclusionZones,
                    icon: Icons.shield_outlined,
                    color: AppColors.red,
                    isActive: lm.showProtectedZones || lm.showExclusionZones,
                    toggleValue: lm.showProtectedZones || lm.showExclusionZones,
                    onToggle: (val) {
                      lm.showProtectedZones = val;
                      lm.showExclusionZones = val;
                    },
                    content: _buildProtectedAndExclusionContent(),
                  ),
                  _buildSection(
                    key: 'spots',
                    title: _l10n.fishingSpotSuggestions,
                    icon: Icons.place,
                    color: AppColors.red,
                    isActive: lm.showFishingSpots,
                    toggleValue: lm.showFishingSpots,
                    onToggle: (val) => lm.showFishingSpots = val,
                    content: _buildFishingSpotsContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers, size: 17, color: AppColors.red),
          ),
          const SizedBox(width: 10),
          Text(
            _l10n.mapLayers,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, size: 17, color: Colors.grey.shade500),
            onPressed: widget.onClose,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Collapsible section wrapper
  // ────────────────────────────────────────────

  Widget _buildSection({
    required String key,
    required String title,
    required IconData icon,
    required Color color,
    required bool isActive,
    required Widget content,
    bool? toggleValue,
    ValueChanged<bool>? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                icon,
                size: 15,
                color: isActive ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isActive ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ),
            if (onToggle != null)
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: toggleValue ?? false,
                  onChanged: onToggle,
                  activeThumbColor: color,
                  activeTrackColor: color.withValues(alpha: 0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 4, top: 4, bottom: 4),
          child: content,
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  // ────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────

  // ────────────────────────────────────────────
  // Section content builders
  // ────────────────────────────────────────────

  Widget _buildDepthContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lm.showDepthLayer) ...[
          const SizedBox(height: 4),
          Text(
            _l10n.visualizationType,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: DepthVisualizationType.values.map((type) {
              final selected = lm.depthVisualizationType == type;
              return ChoiceChip(
                label: Text(
                  type.displayName,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: selected,
                onSelected: (_) => lm.depthVisualizationType = type,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                selectedColor: AppColors.red.withValues(alpha: 0.15),
                checkmarkColor: AppColors.red,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _l10n.opacityLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(lm.depthLayerOpacity * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: lm.depthLayerOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              activeColor: AppColors.red,
              inactiveColor: AppColors.red.withValues(alpha: 0.15),
              onChanged: (val) => lm.depthLayerOpacity = val,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProtectedAndExclusionContent() {
    final active = lm.showProtectedZones || lm.showExclusionZones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(AppColors.red.withValues(alpha: 0.5), _l10n.mpaRestrictedArea),
                _legendRow(Colors.orange.withValues(alpha: 0.7), _l10n.oilExclusion),
                _legendRow(AppColors.brown.withValues(alpha: 0.8), _l10n.gasExclusion),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFishingSpotsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lm.showFishingSpots) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(Colors.green.withValues(alpha: 0.6), _l10n.highConfidenceSpot),
                _legendRow(Colors.orange.withValues(alpha: 0.6), _l10n.mediumConfidenceSpot),
                _legendRow(Colors.blue.withValues(alpha: 0.25), _l10n.fishingZone),

                if (widget.onOpenPrediction != null) ...[
                    const SizedBox(height: 6),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 10),
                    _buildPredictionButton(),
                  ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPredictionButton() {
    return InkWell(
      onTap: () {
        widget.onOpenPrediction!();
        widget.onClose();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brown, AppColors.tan],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.fishingPrediction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _l10n.aiCatchProbability,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
