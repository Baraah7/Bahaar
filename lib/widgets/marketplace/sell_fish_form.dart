import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/fishing/trip_model.dart';
import '../../app_start.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';

class SellFishForm extends StatefulWidget {
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final bool isGuest;
  /// Pre-populate the form for editing an existing listing.
  final FishListing? initialListing;
  /// Recent catch entries from the fishing log shown as quick-fill suggestions.
  final List<CatchEntry> recentCatches;
  final Function(FishListing) onSubmit;

  const SellFishForm({
    super.key,
    this.currentUserId,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
    this.isGuest = false,
    this.initialListing,
    this.recentCatches = const [],
    required this.onSubmit,
  });

  @override
  State<SellFishForm> createState() => _SellFishFormState();
}

class _SellFishFormState extends State<SellFishForm> {
  MarketplaceLocalizations get _l10n => MarketplaceLocalizations.of(context);
  String get _lang => Localizations.localeOf(context).languageCode;

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  FishType _selectedFishType = FishType.hamour;
  FishCondition _selectedCondition = FishCondition.fresh;
  final Set<PaymentMethod> _acceptedPayments = {PaymentMethod.cash};
  final List<String> _fishImages = [];
  String? _benefitPayImage;

  bool _isSubmitting = false;
  bool _isPicking = false;

  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _catchLocationController = TextEditingController();
  final _customFishNameController = TextEditingController();
  final _ibanController = TextEditingController();
  late TextEditingController _sellerNameController;
  late TextEditingController _sellerPhoneController;
  late TextEditingController _sellerLocationController;
  String? _selectedCatchId;

  @override
  void initState() {
    super.initState();
    _sellerNameController = TextEditingController(text: widget.currentUserName ?? '');
    _sellerPhoneController = TextEditingController(text: widget.currentUserPhone ?? '');
    _sellerLocationController = TextEditingController(text: widget.currentUserLocation ?? '');

    final l = widget.initialListing;
    if (l != null) {
      _selectedFishType = l.fishType;
      _selectedCondition = l.condition;
      _acceptedPayments
        ..clear()
        ..addAll(l.acceptedPayments);
      _weightController.text = l.weight.toStringAsFixed(1);
      _priceController.text = l.pricePerKg.toStringAsFixed(3);
      _descriptionController.text = l.description ?? '';
      _catchLocationController.text = l.catchLocation ?? '';
      _customFishNameController.text = l.customFishName ?? '';
      _ibanController.text = l.benefitPayIban ?? '';
      _fishImages.addAll(l.imageUrls);
      if (l.benefitPayImageUrl != null) _benefitPayImage = l.benefitPayImageUrl;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _catchLocationController.dispose();
    _customFishNameController.dispose();
    _ibanController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickFishImages() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;
      setState(() {
        for (final img in images) {
          _fishImages.add(img.path);
        }
      });
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _pickBenefitPayImage() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() => _benefitPayImage = image.path);
    } finally {
      _isPicking = false;
    }
  }

  Future<String> _uploadFile(String localPath, String storagePath) async {
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(File(localPath));
    return ref.getDownloadURL();
  }

  /// Pre-fill form fields from a catch log entry.
  void _applyFromCatch(CatchEntry catch_) {
    // Match species name to a FishType enum value.
    // Handles: enum name ("hamour"), full displayName ("Hamour (Grouper)"),
    // displayName prefix ("Hamour"), and Arabic name ("هامور").
    FishType? matched;
    final speciesLower = catch_.species.toLowerCase().trim();
    for (final t in FishType.values) {
      if (t == FishType.other) continue;
      if (t.name == speciesLower ||
          t.displayName.toLowerCase() == speciesLower ||
          t.displayName.toLowerCase().startsWith(speciesLower) ||
          speciesLower.startsWith(t.name) ||
          t.arabicName.trim() == catch_.species.trim()) {
        matched = t;
        break;
      }
    }

    setState(() {
      _selectedCatchId = catch_.id;
      if (matched != null) {
        _selectedFishType = matched;
        _customFishNameController.clear();
      } else {
        _selectedFishType = FishType.other;
        _customFishNameController.text = catch_.species;
      }
      if (catch_.weightKg != null) {
        _weightController.text =
            catch_.weightKg!.toStringAsFixed(2);
      }
      if (catch_.notes != null && catch_.notes!.isNotEmpty) {
        _descriptionController.text = catch_.notes!;
      }
      // Pre-fill catch location from the logged GPS position
      if (catch_.location != null) {
        _catchLocationController.text =
            '${catch_.latitude!.toStringAsFixed(5)}, '
            '${catch_.longitude!.toStringAsFixed(5)}';
      }
    });
  }

  Widget _buildRecentCatchesSuggestions() {
    if (widget.recentCatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            _l10n.fromYourFishingLog, Icons.history_rounded),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.tapRecentCatchToFill,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.recentCatches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final c = widget.recentCatches[i];
                    final dateStr = _fmtDate(c.timestamp);
                    return GestureDetector(
                      onTap: () => _applyFromCatch(c),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D4F54).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0E7490).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.species,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF0D4F54),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (c.weightKg != null)
                              Text(
                                '${c.weightKg!.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
                              ),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 10,
                                    color: Colors.grey.shade400),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    dateStr,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color:
                                            Colors.grey.shade400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return _l10n.today;
    if (diff.inDays == 1) return _l10n.yesterday;
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent catches suggestion strip (from fishing log)
          _buildRecentCatchesSuggestions(),
          _buildSectionHeader(_l10n.fishPhotos, Icons.camera_alt_outlined),
          const SizedBox(height: 10),
          _buildCard([_buildImagePicker()]),
          const SizedBox(height: 24),
          _buildSectionHeader(_l10n.fishDetails, Icons.phishing_outlined),
          const SizedBox(height: 10),
          _buildCard([
            _buildDropdown<FishType>(
              label: _l10n.fishType,
              initialValue: _selectedFishType,
              items: FishType.values,
              onChanged: (value) => setState(() => _selectedFishType = value!),
              itemBuilder: (type) => type.localizedName(_lang),
            ),
            if (_selectedFishType == FishType.other) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customFishNameController,
                decoration: _inputDecoration(_l10n.customFishName, Icons.edit_outlined),
                validator: (value) {
                  if (_selectedFishType == FishType.other &&
                      (value == null || value.isEmpty)) {
                    return _l10n.pleaseEnterFishName;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildDropdown<FishCondition>(
              label: _l10n.condition,
              initialValue: _selectedCondition,
              items: FishCondition.values,
              onChanged: (value) => setState(() => _selectedCondition = value!),
              itemBuilder: (condition) => condition.localizedName(_lang),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: _inputDecoration(_l10n.weightKg, Icons.scale_outlined),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return _l10n.required;
                      final n = double.tryParse(value);
                      if (n == null || n <= 0) return _l10n.invalidNumber;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration(_l10n.pricePerKgBD, Icons.payments_outlined),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return _l10n.required;
                      final n = double.tryParse(value);
                      if (n == null || n <= 0) return _l10n.invalidNumber;
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catchLocationController,
              decoration: _inputDecoration(_l10n.catchLocationOptional, Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(_l10n.descriptionOptional, Icons.description_outlined),
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader(_l10n.paymentMethods, Icons.payments_outlined),
          const SizedBox(height: 10),
          _buildCard([
            Text(
              _l10n.selectAcceptedPaymentMethods,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...PaymentMethod.values.map((method) {
              final isSelected = _acceptedPayments.contains(method);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected && _acceptedPayments.length > 1) {
                      _acceptedPayments.remove(method);
                      if (method == PaymentMethod.benefitPay) {
                        _benefitPayImage = null;
                        _ibanController.clear();
                      }
                    } else {
                      _acceptedPayments.add(method);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0D4F54).withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D4F54).withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0E7490).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          method == PaymentMethod.cash
                              ? Icons.money_rounded
                              : Icons.account_balance_wallet_rounded,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFF0E7490)
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.localizedName(_lang),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0D4F54)
                                    : const Color(0xFF1E293B),
                                fontSize: _lang == 'ar' ? 16 : 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method == PaymentMethod.cash
                                  ? _l10n.acceptCashPayment
                                  : _l10n.acceptBenefitPay,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D4F54) : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D4F54)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_acceptedPayments.contains(PaymentMethod.benefitPay)) ...[
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF0E7490)),
                  const SizedBox(width: 8),
                  Text(
                    _l10n.benefitPayQRCode,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBenefitPayImagePicker(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(_l10n.or, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ibanController,
                decoration: _inputDecoration(_l10n.ibanOptional, Icons.account_balance_outlined),
              ),
              const SizedBox(height: 6),
              Text(
                _l10n.sellerBenefitNote,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader(_l10n.sellerInformation, Icons.person_outline),
          const SizedBox(height: 10),
          _buildCard([
            TextFormField(
              controller: _sellerNameController,
              decoration: _inputDecoration(_l10n.yourName, Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) return _l10n.pleaseEnterYourName;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerPhoneController,
              decoration: _inputDecoration(_l10n.phoneNumber, Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              maxLength: 8,
              validator: (value) {
                if (value == null || value.isEmpty) return _l10n.pleaseEnterPhoneNumber;
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length != 8) return _l10n.phoneEightDigits;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerLocationController,
              decoration: _inputDecoration(_l10n.yourLocation, Icons.location_on_outlined),
            ),
          ]),
          const SizedBox(height: 32),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D4F54),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0D4F54).withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_business_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _l10n.postListing,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D4F54).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0E7490)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n.addPhotosOfFish,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              ..._fishImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(
                          image: FileImage(File(entry.value)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 14,
                      child: GestureDetector(
                        onTap: () => setState(() => _fishImages.removeAt(entry.key)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              GestureDetector(
                onTap: _pickFishImages,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D4F54).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0E7490).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 28,
                        color: const Color(0xFF0E7490).withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _l10n.addPhoto,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0E7490),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitPayImagePicker() {
    if (_benefitPayImage != null) {
      return Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: FileImage(File(_benefitPayImage!)),
                fit: BoxFit.contain,
              ),
              color: Colors.grey.shade50,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _benefitPayImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickBenefitPayImage,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0E7490).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0E7490).withValues(alpha: 0.2)),
        ),
        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_rounded, size: 28, color: const Color(0xFF0E7490).withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    _l10n.uploadBenefitPayQRCode,
                    style: TextStyle(
                      color: Color(0xFF0E7490),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _l10n.buyersWillSeeThis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T initialValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: _inputDecoration(label, null),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF0E7490)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0D4F54), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF0D4F54)),
            const SizedBox(width: 10),
            Text(_l10n.loginRequired),
          ],
        ),
        content: Text(
          _l10n.guestAccountSellMessage,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D4F54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppStart()),
                (_) => false,
              );
            },
            child: Text(_l10n.signIn),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (widget.isGuest || widget.currentUserId == null) {
      _showLoginRequired();
      return;
    }

    // BenefitPay requires at least QR image or IBAN
    if (_acceptedPayments.contains(PaymentMethod.benefitPay) &&
        _benefitPayImage == null &&
        _ibanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.ibanOrQrRequired),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final uid = widget.currentUserId!;
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Upload fish images to Firebase Storage (skip already-uploaded URLs)
      final uploadedImageUrls = <String>[];
      for (var i = 0; i < _fishImages.length; i++) {
        final path = _fishImages[i];
        if (path.startsWith('http')) {
          uploadedImageUrls.add(path);
          continue;
        }
        final ext = path.split('.').last;
        final url = await _uploadFile(path, 'marketplace/listings/$uid/${ts}_$i.$ext');
        uploadedImageUrls.add(url);
      }

      // Upload BenefitPay QR image (skip already-uploaded URL)
      String? benefitPayUrl;
      if (_benefitPayImage != null) {
        if (_benefitPayImage!.startsWith('http')) {
          benefitPayUrl = _benefitPayImage;
        } else {
          final ext = _benefitPayImage!.split('.').last;
          benefitPayUrl = await _uploadFile(_benefitPayImage!, 'marketplace/benefitpay/$uid/$ts.$ext');
        }
      }

      final listing = FishListing(
        id: '',
        fishType: _selectedFishType,
        customFishName: _selectedFishType == FishType.other
            ? _customFishNameController.text
            : null,
        weight: double.parse(_weightController.text),
        pricePerKg: double.parse(_priceController.text),
        condition: _selectedCondition,
        acceptedPayments: _acceptedPayments.toList(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        imageUrls: uploadedImageUrls,
        benefitPayImageUrl: _acceptedPayments.contains(PaymentMethod.benefitPay)
            ? benefitPayUrl
            : null,
        benefitPayIban: _acceptedPayments.contains(PaymentMethod.benefitPay) &&
                _ibanController.text.trim().isNotEmpty
            ? _ibanController.text.trim()
            : null,
        fromCatchId: _selectedCatchId,
        catchLocation: _catchLocationController.text.isEmpty
            ? null
            : _catchLocationController.text,
        catchDate: DateTime.now(),
        sellerId: uid,
        sellerName: _sellerNameController.text,
        sellerPhone: _sellerPhoneController.text,
        sellerLocation: _sellerLocationController.text.isEmpty
            ? null
            : _sellerLocationController.text,
        listedAt: DateTime.now(),
      );

      widget.onSubmit(listing);

      _formKey.currentState!.reset();
      _weightController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _catchLocationController.clear();
      _customFishNameController.clear();
      _ibanController.clear();
      if (mounted) {
        setState(() {
          _selectedFishType = FishType.hamour;
          _selectedCondition = FishCondition.fresh;
          _acceptedPayments.clear();
          _acceptedPayments.add(PaymentMethod.cash);
          _fishImages.clear();
          _benefitPayImage = null;
          _selectedCatchId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.failedToUploadImage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
