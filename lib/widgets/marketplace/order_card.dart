import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/marketplace/order_model.dart';
import '../../l10n/marketplace/marketplace_localizations.dart';
import 'package:bahaar/utilities/cn/localization_helper.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final FishListing? listing;
  final bool isSeller;
  final MarketplaceLocalizations l10n;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
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
    this.onViewPaymentProof,
  });

  String _n(String value, String lang) => arabicN(value, lang);

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final listingName = listing == null
        ? ''
        : (isAr ? listing!.fishType.arabicName : listing!.displayName);
    final totalPrice = listing?.totalPrice ?? 0.0;
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
          // ── Gradient header ──────────────────────────────────
          Container(
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      Text(
                        '${_n(totalPrice.toStringAsFixed(2), lang)} ${l10n.bdUnit}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF0D4F54).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusData.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusData.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.status.localizedName(lang),
                    style: TextStyle(
                      color: statusData.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactInfo(),
                const SizedBox(height: 10),
                _buildPaymentRow(lang),
                if (isSeller &&
                    order.paymentMethod == PaymentMethod.benefitPay &&
                    order.paymentProofImageUrl != null)
                  _buildPaymentProofSection(),
                if (!isSeller &&
                    order.status == OrderStatus.rejected &&
                    order.rejectionReason != null)
                  _buildRejectionReason(),
                if (!isSeller && order.status == OrderStatus.pending)
                  _buildStatusBanner(
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.brown,
                    message: l10n.waitingForSeller,
                  ),
                if (!isSeller && order.status == OrderStatus.accepted)
                  _buildStatusBanner(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                    message: l10n.orderAcceptedContactSeller,
                  ),
                if (isSeller && order.status == OrderStatus.pending)
                  _buildSellerActions(),
                if (isSeller && order.status == OrderStatus.accepted)
                  _buildCompleteButton(),
                if (!isSeller && order.status == OrderStatus.pending)
                  _buildCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final rows = isSeller
        ? [
            _InfoItem(Icons.person_outline_rounded, '${l10n.buyer}: ${order.buyerName}'),
            _InfoItem(Icons.phone_outlined, order.buyerPhone),
            if (order.buyerLocation != null)
              _InfoItem(Icons.location_on_outlined, order.buyerLocation!),
          ]
        : [
            _InfoItem(Icons.store_outlined, '${l10n.sellerLabel}: ${listing?.sellerName ?? ''}'),
            _InfoItem(Icons.phone_outlined, listing?.sellerPhone ?? 'N/A'),
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
                    if (e.key > 0) Divider(height: 10, color: Colors.grey.shade200),
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
            '${l10n.payment}: ${order.paymentMethod.localizedName(lang)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0E7490)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 15, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  l10n.paymentProof,
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onViewPaymentProof?.call(order.paymentProofImageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(order.paymentProofImageUrl!),
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.tapToViewFullImage, style: TextStyle(color: Colors.blue.shade400, fontSize: 11)),
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
                '${l10n.rejectionReason}: ${order.rejectionReason}',
                style: TextStyle(color: AppColors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner({required IconData icon, required Color color, required String message}) {
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
              child: Text(message, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13)),
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
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded, size: 17),
              label: Text(l10n.reject),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red.withValues(alpha: 0.8),
                side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF34D399)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded, size: 17),
                label: Text(l10n.accept),
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
            onPressed: onComplete,
            icon: const Icon(Icons.done_all_rounded, size: 17),
            label: Text(l10n.markAsCompleted),
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

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined, size: 17),
          label: Text(l10n.cancelOrder),
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
    switch (order.status) {
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
