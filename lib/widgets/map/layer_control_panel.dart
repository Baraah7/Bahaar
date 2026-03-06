import 'package:flutter/material.dart';
import 'package:Bahaar/services/map/map_layer_manager.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

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
  final Set<String> _expanded = {};

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

  MapLayerManager get lm => widget.layerManager;

  bool _isExpanded(String key) => _expanded.contains(key);

  void _toggleSection(String key) {
    setState(() {
      _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key);
    });
  }

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
                    title: 'Depth Visualization',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.red,
                    isActive: lm.showDepthLayer,
                    content: _buildDepthContent(),
                  ),
                  _buildSection(
                    key: 'protected',
                    title: 'Protected Zones',
                    icon: Icons.shield_outlined,
                    color: AppColors.red,
                    isActive: lm.showProtectedZones,
                    content: _buildProtectedZonesContent(),
                  ),
                  _buildSection(
                    key: 'exclusion',
                    title: 'Oil & Gas Exclusion',
                    icon: Icons.oil_barrel,
                    color: AppColors.red,
                    isActive: lm.showExclusionZones,
                    content: _buildExclusionContent(),
                  ),
                  _buildSection(
                    key: 'spots',
                    title: 'Fishing Spot Suggestions',
                    icon: Icons.place,
                    color: AppColors.red,
                    isActive: lm.showFishingSpots,
                    content: _buildFishingSpotsContent(),
                  ),
                  _buildSection(
                    key: 'mask',
                    title: 'Navigation & Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.red,
                    isActive: lm.showMaskOverlay,
                    content: _buildNavigationMaskContent(),
                  ),
                  if (widget.onOpenPrediction != null) ...[
                    const SizedBox(height: 6),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 10),
                    _buildPredictionButton(),
                  ],
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
            child: const Icon(Icons.layers, size: 17, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          const Text(
            'Map Layers',
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
  }) {
    final expanded = _isExpanded(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleSection(key),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: expanded ? color.withValues(alpha: 0.07) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
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
                if (isActive)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 4), content],
            ),
          ),
        const SizedBox(height: 2),
      ],
    );
  }

  // ────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final active = value && onChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: active
                  ? iconColor.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 15,
              color: active ? iconColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: onChanged != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAction({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.35)
                  : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: enabled ? color : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Section content builders
  // ────────────────────────────────────────────

  Widget _buildDepthContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          icon: Icons.water_drop_outlined,
          iconColor: AppColors.red,
          label: 'Show Depth Layer',
          value: lm.showDepthLayer,
          onChanged: (val) => lm.showDepthLayer = val,
        ),
        if (lm.showDepthLayer) ...[
          const SizedBox(height: 8),
          Text(
            'Visualization Type',
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
                'Opacity',
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

  Widget _buildProtectedZonesContent() {
    final featureCount = widget.geoJsonBuilder != null
        ? widget.geoJsonBuilder!.getFeatureCount('protected_zone') +
            widget.geoJsonBuilder!.getFeatureCount('reef')
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          icon: Icons.shield_outlined,
          iconColor: AppColors.red,
          label: 'Protected Zones',
          subtitle: featureCount > 0
              ? '$featureCount features loaded'
              : 'Marine reserves & reefs',
          value: lm.showProtectedZones,
          onChanged: (val) => lm.showProtectedZones = val,
        ),
        if (lm.showProtectedZones) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendRow(AppColors.red.withValues(alpha: 0.5), 'MPA — restricted area'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExclusionContent() {
    return _buildToggleRow(
      icon: Icons.oil_barrel,
      iconColor: AppColors.red,
      label: 'Show Exclusion Zones',
      subtitle: lm.showExclusionZones
          ? '500 m UNCLOS safety buffers visible'
          : 'Safety rules still apply when hidden',
      value: lm.showExclusionZones,
      onChanged: (val) => lm.showExclusionZones = val,
    );
  }

  Widget _buildFishingSpotsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          icon: Icons.place,
          iconColor: AppColors.red,
          label: 'Show Fishing Spots',
          subtitle: 'Zones, MPAs & confirmed locations',
          value: lm.showFishingSpots,
          onChanged: (val) => lm.showFishingSpots = val,
        ),
        if (lm.showFishingSpots) ...[
          const SizedBox(height: 8),
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
                _legendRow(Colors.green.withValues(alpha: 0.6), 'High confidence spot'),
                _legendRow(Colors.orange.withValues(alpha: 0.6), 'Medium confidence spot'),
                _legendRow(Colors.blue.withValues(alpha: 0.25), 'Fishing zone'),
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

  Widget _buildNavigationMaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleRow(
          icon: Icons.map_outlined,
          iconColor: AppColors.red,
          label: 'Show Mask Boundary',
          subtitle: widget.maskInitialized
              ? 'Coverage area outline'
              : 'Loading...',
          value: lm.showMaskOverlay,
          onChanged: widget.maskInitialized
              ? (val) => lm.showMaskOverlay = val
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 13,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 5),
            Text(
              'Admin Tools',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAdminAction(
          icon: Icons.edit_outlined,
          color: AppColors.red,
          label: 'Edit Navigation Mask',
          subtitle: widget.maskInitialized
              ? 'Paint water / land cells'
              : 'Loading...',
          onTap: widget.maskInitialized && widget.onEnterAdminEdit != null
              ? () {
                  widget.onEnterAdminEdit!();
                  widget.onClose();
                }
              : null,
        ),
        _buildAdminAction(
          icon: Icons.border_style,
          color: AppColors.red,
          label: 'Edit Boundary Outline',
          subtitle: widget.maskInitialized
              ? 'Erase / restore boundary'
              : 'Loading...',
          onTap: widget.maskInitialized && widget.onEnterOutlineEdit != null
              ? () {
                  widget.onEnterOutlineEdit!();
                  widget.onClose();
                }
              : null,
        ),
        _buildAdminAction(
          icon: Icons.map_outlined,
          color: AppColors.red,
          label: 'Edit Map Features',
          subtitle: 'Add / move / delete features',
          onTap: widget.onEnterFeatureEdit != null
              ? () {
                  widget.onEnterFeatureEdit!();
                  widget.onClose();
                }
              : null,
        ),
      ],
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
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fishing Prediction',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AI-powered catch probability',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
