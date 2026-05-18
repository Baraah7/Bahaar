import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:bahaar/screens/fishing_log/location_picker_screen.dart';
import 'package:bahaar/services/map/navigation_mask.dart';
import 'package:bahaar/constants/app_colors.dart';
import 'package:bahaar/l10n/fishing_log/fishing_log_localizations.dart';
import 'package:bahaar/widgets/common/app_card.dart';
import 'package:bahaar/widgets/common/section_label.dart';
import 'package:bahaar/widgets/common/card_divider.dart';

class CatchForm extends StatefulWidget {
  const CatchForm({super.key});

  static Future<CatchFormResult?> show(BuildContext context) {
    return showModalBottomSheet<CatchFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CatchForm(),
    );
  }

  @override
  State<CatchForm> createState() => _CatchFormState();
}

class _CatchFormState extends State<CatchForm> {
  final _formKey = GlobalKey<FormState>();
  final _speciesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _speciesFocus = FocusNode();

  bool _locating = false;
  LatLng? _location;
  bool _mapPinned = false;
  bool _isOtherSelected = false;
  String? _locationError;

  final NavigationMask _mask = NavigationMask();
  bool _maskReady = false;

  static const _teal = Color(0xFF0D4F54);
  static const _tealLight = Color(0xFF0E7490);

  // (Arabic name, English name) pairs
  static const _quickSpecies = [
    ('هامور', 'Hamour'),
    ('صافي', 'Safi'),
    ('صبيطي', 'Subaity'),
    ('كنعد', 'Chanad'),
    ('زبيدي', 'Zubaidi'),
    ('ربيان', 'Shrimp'),
    ('قبقب', 'Crab'),
    ('سبيطي', 'Subaity'),
  ];

  FishingLogLocalizations get _l10n => FishingLogLocalizations.of(context);
  bool get _isAr => _l10n.localeName == 'ar';

  @override
  void initState() {
    super.initState();
    _mask.initialize().then((_) {
      if (mounted) setState(() => _maskReady = true);
    }).catchError((_) {
      if (mounted) setState(() => _maskReady = true);
    });
    _fetchLocation();
  }

  @override
  void dispose() {
    _speciesCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _speciesFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() { _locating = true; _locationError = null; });
    try {
      final results = await Future.wait([
        Location().getLocation(),
        _maskReady ? Future.value(null) : _mask.initialize(),
      ]);
      if (!mounted) return;
      if (!_maskReady) setState(() => _maskReady = true);

      final data = results[0] as LocationData;
      if (data.latitude == null || data.longitude == null) {
        setState(() => _locationError = _l10n.locationGpsError);
        return;
      }
      final point = LatLng(data.latitude!, data.longitude!);
      if (_mask.isInitialized && !_mask.isPointNavigable(point)) {
        setState(() => _locationError = _l10n.locationOnLandError);
        return;
      }
      setState(() {
        _location = point;
        _mapPinned = false;
        _locationError = null;
      });
    } catch (_) {
      if (mounted) setState(() => _locationError = _l10n.locationGpsError);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickOnMap() async {
    final picked =
        await LocationPickerScreen.open(context, initial: _location);
    if (picked != null && mounted) {
      setState(() {
        _location = picked;
        _mapPinned = true;
      });
    }
  }

  Widget _chip(String label, bool isSelected, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.tryParse(_weightCtrl.text.trim());
    Navigator.of(context).pop(CatchFormResult(
      species: _speciesCtrl.text.trim(),
      weightKg: weight,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      location: _location,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.set_meal_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _l10n.logCatchTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick-pick chips
                    SectionLabel(_l10n.chooseSpecies),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ..._quickSpecies.map((s) {
                            final name = _isAr ? s.$1 : s.$2;
                            final isSelected = !_isOtherSelected && _speciesCtrl.text == name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _speciesCtrl.text = name;
                                  _isOtherSelected = false;
                                }),
                                child: _chip(name, isSelected, _teal),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          // Others chip
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOtherSelected = true;
                                _speciesCtrl.text = '';
                              });
                              Future.delayed(const Duration(milliseconds: 50),
                                  () => _speciesFocus.requestFocus());
                            },
                            child: _chip(
                              _isAr ? 'أخرى' : 'Others',
                              _isOtherSelected,
                              AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Species + Weight in a white card
                    SectionLabel(_l10n.catchDetails),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Column(
                        children: [
                          _CardField(
                            controller: _speciesCtrl,
                            focusNode: _speciesFocus,
                            icon: Icons.set_meal_outlined,
                            iconColor: _isOtherSelected ? AppColors.accent : _tealLight,
                            label: _isOtherSelected
                                ? (_isAr ? 'اسم السمكة' : 'Fish name')
                                : _l10n.speciesNameLabel,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? _l10n.speciesRequired
                                    : null,
                          ),
                          const CardDivider(),
                          _CardField(
                            controller: _weightCtrl,
                            icon: Icons.scale_outlined,
                            iconColor: AppColors.accent,
                            label: _l10n.weightKg,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'))
                            ],
                          ),
                          const CardDivider(),
                          _CardField(
                            controller: _notesCtrl,
                            icon: Icons.notes_outlined,
                            iconColor: Colors.grey,
                            label: _l10n.notesOptionalLabel,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location card
                    SectionLabel(_l10n.catchLocationLabel),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.10),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.red,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _location != null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                _mapPinned
                                                    ? Icons
                                                        .push_pin_rounded
                                                    : Icons
                                                        .gps_fixed_rounded,
                                                size: 13,
                                                color: AppColors.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _mapPinned
                                                    ? _l10n.pinnedOnMap
                                                    : _l10n
                                                        .gpsLocationLabel,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.red,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_location!.latitude.toStringAsFixed(5)}, '
                                            '${_location!.longitude.toStringAsFixed(5)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors
                                                    .grey.shade600),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _l10n.locationNotSet,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.grey.shade400),
                                      ),
                              ),
                              if (_locating)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.red),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _LocationButton(
                                  icon: Icons.my_location_rounded,
                                  label: _l10n.currectLocation,
                                  onTap: _fetchLocation,
                                  color: _tealLight,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _LocationButton(
                                  icon: Icons.map_outlined,
                                  label: _l10n.mapLabel,
                                  onTap: _pickOnMap,
                                  color: _tealLight,
                                ),
                              ),
                            ],
                          ),
                          if (_locationError != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 15, color: Colors.red.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _locationError!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(_l10n.logCatch,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Card field ────────────────────────────────────────────────────────────────

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _CardField({
    required this.controller,
    this.focusNode,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              maxLines: maxLines,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                errorStyle: const TextStyle(
                    color: Colors.redAccent, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location button ───────────────────────────────────────────────────────────

class _LocationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _LocationButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Result ────────────────────────────────────────────────────────────────────

class CatchFormResult {
  final String species;
  final double? weightKg;
  final String? notes;
  final LatLng? location;

  const CatchFormResult({
    required this.species,
    this.weightKg,
    this.notes,
    this.location,
  });
}
