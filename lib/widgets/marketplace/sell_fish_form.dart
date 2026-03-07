import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/fishing/trip_model.dart';
import '../../app_start.dart';

class SellFishForm extends StatefulWidget {
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final bool isGuest;
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
    this.recentCatches = const [],
    required this.onSubmit,
  });

  @override
  State<SellFishForm> createState() => _SellFishFormState();
}

class _SellFishFormState extends State<SellFishForm> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  FishType _selectedFishType = FishType.hamour;
  FishCondition _selectedCondition = FishCondition.fresh;
  final Set<PaymentMethod> _acceptedPayments = {PaymentMethod.cash};
  final List<String> _fishImages = [];
  String? _benefitPayImage;

  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _catchLocationController = TextEditingController();
  final _customFishNameController = TextEditingController();
  late TextEditingController _sellerNameController;
  late TextEditingController _sellerPhoneController;
  late TextEditingController _sellerLocationController;

  @override
  void initState() {
    super.initState();
    _sellerNameController = TextEditingController(text: widget.currentUserName ?? '');
    _sellerPhoneController = TextEditingController(text: widget.currentUserPhone ?? '');
    _sellerLocationController = TextEditingController(text: widget.currentUserLocation ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _catchLocationController.dispose();
    _customFishNameController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickFishImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _fishImages.addAll(images.map((img) => img.path));
      });
    }
  }

  Future<void> _pickBenefitPayImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _benefitPayImage = image.path;
      });
    }
  }

  /// Pre-fill form fields from a catch log entry.
  void _applyFromCatch(CatchEntry catch_) {
    // Match species name to a FishType enum value (case-insensitive).
    FishType? matched;
    for (final t in FishType.values) {
      if (t.displayName.toLowerCase() ==
              catch_.species.toLowerCase() ||
          t.arabicName == catch_.species) {
        matched = t;
        break;
      }
    }

    setState(() {
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
      _catchLocationController.text =
          '${catch_.latitude.toStringAsFixed(5)}, '
          '${catch_.longitude.toStringAsFixed(5)}';
    });
  }

  Widget _buildRecentCatchesSuggestions() {
    if (widget.recentCatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            'From Your Fishing Log', Icons.history_rounded),
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
                'Tap a recent catch to pre-fill the form',
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final c = widget.recentCatches[i];
                    final dateStr = _fmtDate(c.timestamp);
                    return GestureDetector(
                      onTap: () => _applyFromCatch(c),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D4F54)
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0E7490)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
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
          _buildSectionHeader('Fish Photos', Icons.camera_alt_outlined),
          const SizedBox(height: 10),
          _buildCard([_buildImagePicker()]),
          const SizedBox(height: 24),
          _buildSectionHeader('Fish Details', Icons.phishing_outlined),
          const SizedBox(height: 10),
          _buildCard([
            _buildDropdown<FishType>(
              label: 'Fish Type',
              initialValue: _selectedFishType,
              items: FishType.values,
              onChanged: (value) => setState(() => _selectedFishType = value!),
              itemBuilder: (type) => '${type.displayName} (${type.arabicName})',
            ),
            if (_selectedFishType == FishType.other) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customFishNameController,
                decoration: _inputDecoration('Custom Fish Name', Icons.edit_outlined),
                validator: (value) {
                  if (_selectedFishType == FishType.other &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter the fish name';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildDropdown<FishCondition>(
              label: 'Condition',
              initialValue: _selectedCondition,
              items: FishCondition.values,
              onChanged: (value) => setState(() => _selectedCondition = value!),
              itemBuilder: (condition) => condition.displayName,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: _inputDecoration('Weight (kg)', Icons.scale_outlined),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration('Price/kg (BD)', Icons.payments_outlined),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catchLocationController,
              decoration: _inputDecoration('Catch Location (optional)', Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description (optional)', Icons.description_outlined),
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Payment Methods', Icons.payments_outlined),
          const SizedBox(height: 10),
          _buildCard([
            Text(
              'Select accepted payment methods:',
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
                              method.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0D4F54)
                                    : const Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method == PaymentMethod.cash
                                  ? 'Accept cash payment'
                                  : 'Accept Benefit Pay',
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
                  const Text(
                    'Benefit Pay QR Code / Payment Info',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBenefitPayImagePicker(),
            ],
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('Seller Information', Icons.person_outline),
          const SizedBox(height: 10),
          _buildCard([
            TextFormField(
              controller: _sellerNameController,
              decoration: _inputDecoration('Your Name', Icons.person_outline),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your name';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerPhoneController,
              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your phone number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sellerLocationController,
              decoration: _inputDecoration('Your Location (optional)', Icons.location_on_outlined),
            ),
          ]),
          const SizedBox(height: 32),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D4F54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_business_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Post Listing',
                    style: TextStyle(
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
          'Add photos of your fish (optional)',
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
                      const Text(
                        'Add Photo',
                        style: TextStyle(
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
            const Text(
              'Upload Benefit Pay QR Code',
              style: TextStyle(
                color: Color(0xFF0E7490),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              'Buyers will see this when they select Benefit Pay',
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
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF0D4F54)),
            SizedBox(width: 10),
            Text('Login Required'),
          ],
        ),
        content: const Text(
          'You need to sign in to post a listing.\nGuest accounts cannot sell fish.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D4F54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppStart()),
                (_) => false,
              );
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (widget.isGuest || widget.currentUserId == null) {
      _showLoginRequired();
      return;
    }

    if (_formKey.currentState!.validate()) {
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
        imageUrls: _fishImages,
        benefitPayImageUrl: _benefitPayImage,
        catchLocation: _catchLocationController.text.isEmpty
            ? null
            : _catchLocationController.text,
        catchDate: DateTime.now(),
        sellerId: widget.currentUserId!,
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
      setState(() {
        _selectedFishType = FishType.hamour;
        _selectedCondition = FishCondition.fresh;
        _acceptedPayments.clear();
        _acceptedPayments.add(PaymentMethod.cash);
        _fishImages.clear();
        _benefitPayImage = null;
      });
    }
  }
}
