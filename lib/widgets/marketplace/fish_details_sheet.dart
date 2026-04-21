import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../app_start.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
import 'seller_card.dart';
import 'payment_option.dart';

/// Returns the right ImageProvider depending on whether the path is a
/// remote https:// URL (Firebase Storage) or a local file path.
ImageProvider _resolveImage(String path) {
  if (path.startsWith('http')) return NetworkImage(path);
  return FileImage(File(path));
}

class FishDetailsSheet extends StatefulWidget {
  final FishListing listing;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserPhone;
  final String? currentUserLocation;
  final bool isGuest;
  final Function(PaymentMethod, String, String, String?, String?) onBuy;
  final VoidCallback? onDelete;

  const FishDetailsSheet({
    super.key,
    required this.listing,
    this.currentUserId,
    this.currentUserName,
    this.currentUserPhone,
    this.currentUserLocation,
    this.isGuest = false,
    required this.onBuy,
    this.onDelete,
  });

  @override
  State<FishDetailsSheet> createState() => _FishDetailsSheetState();
}

class _FishDetailsSheetState extends State<FishDetailsSheet> {
  MarketplaceLocalizations get _l10n => MarketplaceLocalizations.of(context);

  String _n(String value) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != 'ar') return value;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  PaymentMethod? _selectedPayment;
  late TextEditingController _buyerNameController;
  late TextEditingController _buyerPhoneController;
  late TextEditingController _buyerLocationController;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  int _currentImageIndex = 0;
  String? _paymentProofImage;

  @override
  void initState() {
    super.initState();
    _buyerNameController = TextEditingController(text: widget.currentUserName ?? '');
    _buyerPhoneController = TextEditingController(text: widget.currentUserPhone ?? '');
    _buyerLocationController = TextEditingController(text: widget.currentUserLocation ?? '');
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProofImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _paymentProofImage = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Image gallery with gradient overlay
                _buildImageGallery(),
                // Fish name & condition overlay
                _buildNameConditionSection(),
                // Price highlight card
                _buildPriceCard(),
                // Details section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailsCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(_l10n.sellerInformation, Icons.store_outlined),
                      const SizedBox(height: 10),
                      _buildSellerCard(),
                      if (widget.listing.description != null) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(_l10n.description, Icons.description_outlined),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.listing.description!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (widget.currentUserId == widget.listing.sellerId) ...[
                        // ── Seller view: delete listing ──────────────────
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDeleteListing(),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text(_l10n.deleteListing),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              backgroundColor: AppColors.red.withValues(alpha: 0.1),
                              side: BorderSide(color: AppColors.red.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        // ── Buyer view ───────────────────────────────────
                        _buildSectionHeader(_l10n.yourInformation, Icons.person_outline),
                        const SizedBox(height: 10),
                        _buildBuyerForm(),
                        const SizedBox(height: 20),
                        _buildSectionHeader(_l10n.selectPaymentMethod, Icons.payments_outlined),
                        const SizedBox(height: 10),
                        ...widget.listing.acceptedPayments.map((method) {
                          return _buildPaymentOption(method);
                        }),
                        if (_selectedPayment == PaymentMethod.benefitPay) ...[
                          const SizedBox(height: 12),
                          _buildPaymentProofUpload(),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedPayment != null ? _handleBuy : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D4F54),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedPayment != null
                                      ? '${_l10n.buyNow} - ${_n(widget.listing.totalPrice.toStringAsFixed(2))} ${_l10n.bdUnit}'
                                      : _l10n.selectPaymentMethod,
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
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageGallery() {
    if (widget.listing.imageUrls.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D4F54), Color(0xFF0E7490)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phishing_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 8),
              Text(
                widget.listing.fishType.arabicName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 220,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: _resolveImage(widget.listing.imageUrls[_currentImageIndex]),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient scrim at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Image counter
              if (widget.listing.imageUrls.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_n('${_currentImageIndex + 1}')}/${_n('${widget.listing.imageUrls.length}')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.listing.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.listing.imageUrls.length,
              itemBuilder: (context, index) {
                final isActive = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF0D4F54)
                            : Colors.grey.shade300,
                        width: isActive ? 2.5 : 1,
                      ),
                      image: DecorationImage(
                        image: _resolveImage(widget.listing.imageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameConditionSection() {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final primaryName = isAr ? widget.listing.fishType.arabicName : widget.listing.displayName;
    final secondaryName = isAr ? widget.listing.displayName : widget.listing.fishType.arabicName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secondaryName,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _getConditionColor(widget.listing.condition).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getConditionColor(widget.listing.condition).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.listing.condition.localizedName(lang),
              style: TextStyle(
                color: _getConditionColor(widget.listing.condition),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D4F54), Color(0xFF0E7490)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4F54).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.totalPrice,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_n(widget.listing.totalPrice.toStringAsFixed(2))} ${_l10n.bdUnit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${_n(widget.listing.weight.toStringAsFixed(1))} ${_l10n.kgUnit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_n(widget.listing.pricePerKg.toStringAsFixed(1))} ${_l10n.bdPerKg}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.listing.catchLocation != null)
            _buildDetailRow(
              _l10n.catchLocation,
              widget.listing.catchLocation!,
              Icons.location_on_outlined,
            ),
          if (widget.listing.catchLocation != null && widget.listing.catchDate != null)
            Divider(height: 20, color: Colors.grey.shade100),
          if (widget.listing.catchDate != null)
            _buildDetailRow(
              _l10n.catchDate,
              _formatDate(widget.listing.catchDate!),
              Icons.calendar_today_outlined,
            ),
          if (widget.listing.catchLocation == null && widget.listing.catchDate == null)
            _buildDetailRow(
              _l10n.weight,
              '${_n(widget.listing.weight.toStringAsFixed(1))} ${_l10n.kgUnit}',
              Icons.scale_outlined,
            ),
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

  Widget _buildBuyerForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _buyerNameController,
            decoration: _inputDecoration(_l10n.yourName, Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return _l10n.pleaseEnterYourName;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _buyerPhoneController,
            decoration: _inputDecoration(_l10n.phoneNumber, Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return _l10n.pleaseEnterPhoneNumber;
              if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) return _l10n.phoneEightDigits;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _buyerLocationController,
            decoration: _inputDecoration(_l10n.deliveryLocationOptional, Icons.location_on_outlined),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF0E7490)),
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

  Widget _buildPaymentProofUpload() {
    final hasQr = widget.listing.benefitPayImageUrl != null;
    final hasIban = widget.listing.benefitPayIban != null &&
        widget.listing.benefitPayIban!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0E7490).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller's BenefitPay info
          if (hasQr || hasIban) ...[
            Text(
              _l10n.benefitPayQRCode,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            if (hasQr)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(
                  image: _resolveImage(widget.listing.benefitPayImageUrl!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            if (hasIban) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7490).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFF0E7490)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.listing.benefitPayIban!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0D4F54)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0E7490)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy IBAN',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.listing.benefitPayIban!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('IBAN copied'),
                            backgroundColor: const Color(0xFF0D4F54),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7490).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, size: 16, color: Color(0xFF0E7490)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.uploadPaymentProof,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _l10n.required,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _l10n.pleaseUploadPaymentScreenshot,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_paymentProofImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_paymentProofImage!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentProofImage = null),
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
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  _l10n.paymentProofUploaded,
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ] else
            GestureDetector(
              onTap: _pickPaymentProofImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7490).withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0E7490).withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 32, color: const Color(0xFF0E7490).withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Text(
                      _l10n.tapToUploadScreenshot,
                      style: TextStyle(
                        color: Color(0xFF0E7490),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
          _l10n.guestAccountLoginMessage,
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
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // close bottom sheet
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              nav.pushAndRemoveUntil(
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

  void _confirmDeleteListing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _l10n.deleteListing,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Text(
                    _l10n.confirmDeleteListing,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(_l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                          child: Text(_l10n.deleteListing, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBuy() {
    if (widget.isGuest) {
      _showLoginRequired();
      return;
    }
    if (_formKey.currentState!.validate() && _selectedPayment != null) {
      if (_selectedPayment == PaymentMethod.benefitPay && _paymentProofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.pleaseUploadPaymentProofScreenshot),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      widget.onBuy(
        _selectedPayment!,
        _buyerNameController.text,
        _buyerPhoneController.text,
        _buyerLocationController.text.isEmpty ? null : _buyerLocationController.text,
        _paymentProofImage,
      );
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0E7490)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return buildSellerCard(context, widget.listing);
  }

  Widget _buildPaymentOption(PaymentMethod method) {
    return buildPaymentOption(method, _selectedPayment, (PaymentMethod selectedMethod) {
      setState(() {
        _selectedPayment = selectedMethod;
      });
    }, context: context);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} ${_l10n.minAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${_l10n.hoursAgo}';
    } else {
      return '${difference.inDays} ${_l10n.daysAgo}';
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
