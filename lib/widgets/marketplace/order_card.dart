import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/marketplace/order_model.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final FishListing? listing;
  final bool isSeller;
  final MarketplaceLocalizations l10n;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onRemoveFromPurchases;
  final void Function(String imagePath)? onViewPaymentProof;

  const OrderCard({
    super.key,
    required this.order,
    required this.listing,
    required this.isSeller,
    required this.l10n,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onRemoveFromPurchases,
    this.onViewPaymentProof,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;

  String _n(String value, String lang) => arabicN(value, lang);

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final listingName = widget.listing == null
        ? ''
        : (isAr ? widget.listing!.fishType.arabicName : widget.listing!.displayName);
    final effectiveKg = widget.order.requestedKg ?? widget.listing?.weight ?? 0.0;
    final totalPrice = effectiveKg * (widget.listing?.pricePerKg ?? 0.0);
    final statusData = _getStatusData();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Tappable header ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusData.color.withValues(alpha: 0.12),
                    statusData.color.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusData.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(statusData.icon, color: statusData.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listingName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${_n(totalPrice.toStringAsFixed(2), lang)} ${widget.l10n.bdUnit}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ' ${_n(effectiveKg.toStringAsFixed(1), lang)} ${widget.l10n.kgUnit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusData.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusData.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.order.status.localizedName(lang),
                      style: TextStyle(
                        color: statusData.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: statusData.color,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ──────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactInfo(),
                        const SizedBox(height: 10),
                        _buildPaymentRow(lang),
                        if (widget.isSeller &&
                            widget.order.paymentMethod == PaymentMethod.benefitPay &&
                            widget.order.paymentProofImageUrl != null)
                          _buildPaymentProofSection(),
                        if (!widget.isSeller &&
                            widget.order.status == OrderStatus.rejected &&
                            widget.order.rejectionReason != null)
                          _buildRejectionReason(),
                        if (!widget.isSeller && widget.order.status == OrderStatus.pending)
                          _buildStatusBanner(
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.brown,
                            message: widget.l10n.waitingForSeller,
                          ),
                        if (!widget.isSeller && widget.order.status == OrderStatus.accepted)
                          _buildStatusBanner(
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.green,
                            message: widget.l10n.orderAcceptedContactSeller,
                          ),
                        if (widget.isSeller && widget.order.status == OrderStatus.pending)
                          _buildSellerActions(),
                        if (widget.isSeller && widget.order.status == OrderStatus.accepted)
                          _buildCompleteButton(),
                        if (!widget.isSeller && widget.order.status == OrderStatus.pending)
                          _buildCancelButton(),
                        if (!widget.isSeller)
                          _buildRemoveFromPurchasesButton(),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final rows = widget.isSeller
        ? [
            _InfoItem(Icons.person_outline_rounded,
                '${widget.l10n.buyer}: ${widget.order.buyerName}'),
            _InfoItem(Icons.phone_outlined, widget.order.buyerPhone),
            if (widget.order.buyerLocation != null)
              _InfoItem(Icons.location_on_outlined, widget.order.buyerLocation!),
          ]
        : [
            _InfoItem(Icons.store_outlined,
                '${widget.l10n.sellerLabel}: ${widget.listing?.sellerName ?? ''}'),
            _InfoItem(Icons.phone_outlined, widget.listing?.sellerPhone ?? 'N/A'),
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: rows
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    if (e.key > 0) Divider(height: 20, color: Colors.grey.shade200),
                    _buildInfoRow(e.value.icon, e.value.text),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPaymentRow(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '${widget.l10n.payment}: ${widget.order.paymentMethod.localizedName(lang)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF374151)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProofSection() {
    final url = widget.order.paymentProofImageUrl!;
    final ImageProvider imageProvider =
        url.startsWith('http') ? NetworkImage(url) : FileImage(File(url)) as ImageProvider;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brown.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brown.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.brown),
                const SizedBox(width: 6),
                Text(
                  widget.l10n.paymentProof,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.brown, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => widget.onViewPaymentProof?.call(url),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 36, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.l10n.tapToViewFullImage,
                style: TextStyle(color: AppColors.brown, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionReason() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.l10n.rejectionReason}: ${widget.order.rejectionReason}',
                style: TextStyle(color: AppColors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
      {required IconData icon, required Color color, required String message}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onReject,
              icon: const Icon(Icons.close_rounded, size: 17),
              label: Text(widget.l10n.reject),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red.withValues(alpha: 0.8),
                backgroundColor: AppColors.red.withValues(alpha: 0.12),
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onAccept,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: Text(widget.l10n.accept),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green.withValues(alpha: 0.8),
                backgroundColor: AppColors.green.withValues(alpha: 0.12),
                side: BorderSide(color: AppColors.green.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D4F54), Color(0xFF0E7490)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onComplete,
            icon: const Icon(Icons.done_all_rounded, size: 17),
            label: Text(widget.l10n.markAsCompleted),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveFromPurchasesButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onRemoveFromPurchases,
          icon: const Icon(Icons.delete_outline_rounded, size: 17),
          label: Text(widget.l10n.removeFromPurchases),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            backgroundColor: Colors.grey.withValues(alpha: 0.08),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.cancel_outlined, size: 17),
          label: Text(widget.l10n.cancelOrder),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red.withValues(alpha: 0.8),
            backgroundColor: AppColors.red.withValues(alpha: 0.12),
            side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  _StatusData _getStatusData() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return _StatusData(AppColors.brown, Icons.hourglass_top_rounded);
      case OrderStatus.accepted:
        return _StatusData(AppColors.green, Icons.check_circle_rounded);
      case OrderStatus.rejected:
        return _StatusData(AppColors.red, Icons.cancel_rounded);
      case OrderStatus.completed:
        return _StatusData(AppColors.primary, Icons.done_all_rounded);
      case OrderStatus.cancelled:
        return _StatusData(Colors.grey, Icons.block_rounded);
    }
  }
}

class _StatusData {
  final Color color;
  final IconData icon;
  const _StatusData(this.color, this.icon);
}

class _InfoItem {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);
}
