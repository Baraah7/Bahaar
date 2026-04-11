import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';
import '../../models/marketplace/order_model.dart';
import '../../l10n/app_localizations.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final FishListing? listing;
  final bool isSeller;
  final AppLocalizations l10n;
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

  String _n(String value, String lang) {
    if (lang != 'ar') return value;
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return value.replaceAllMapped(
        RegExp(r'[0-9]'), (m) => digits[int.parse(m.group(0)!)]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final listingName = listing == null
        ? ''
        : (isAr ? listing!.fishType.arabicName : listing!.displayName);
    final totalPrice = listing?.totalPrice ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(listingName, totalPrice, lang),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactInfo(),
                const SizedBox(height: 10),
                _buildPaymentInfo(lang),
                if (isSeller &&
                    order.paymentMethod == PaymentMethod.benefitPay &&
                    order.paymentProofImageUrl != null)
                  _buildPaymentProofSection(),
                if (!isSeller &&
                    order.status == OrderStatus.rejected &&
                    order.rejectionReason != null)
                  _buildRejectionReason(),
                if (!isSeller && order.status == OrderStatus.pending)
                  _buildPendingMessage(),
                if (!isSeller && order.status == OrderStatus.accepted)
                  _buildAcceptedMessage(),
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

  Widget _buildHeader(String listingName, double totalPrice, String lang) {
    final statusData = _getStatusData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusData.color.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusData.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_n(totalPrice.toStringAsFixed(2), lang)} ${l10n.bdUnit}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusData.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.localizedName(lang),
              style: TextStyle(
                color: statusData.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    if (isSeller) {
      return Column(
        children: [
          _buildInfoRow(Icons.person_outline, '${l10n.buyer}: ${order.buyerName}'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.phone_outlined, order.buyerPhone),
          if (order.buyerLocation != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on_outlined, order.buyerLocation!),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          _buildInfoRow(
            Icons.store_outlined,
            '${l10n.sellerLabel}: ${listing?.sellerName ?? ''}',
          ),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.phone_outlined, listing?.sellerPhone ?? 'N/A'),
        ],
      );
    }
  }

  Widget _buildPaymentInfo(String lang) {
    return _buildInfoRow(
      Icons.payments_outlined,
      '${l10n.payment}: ${order.paymentMethod.localizedName(lang)}',
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
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
                Icon(Icons.receipt_long, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  l10n.paymentProof,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: 13,
                  ),
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
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tapToViewFullImage,
              style: TextStyle(color: Colors.blue.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionReason() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l10n.rejectionReason}: ${order.rejectionReason}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMessage() {
    return _buildStatusMessage(
      icon: Icons.hourglass_empty,
      color: Colors.orange,
      message: l10n.waitingForSellerToAccept,
    );
  }

  Widget _buildAcceptedMessage() {
    return _buildStatusMessage(
      icon: Icons.check_circle_outline,
      color: Colors.green,
      message: l10n.orderAcceptedContactSeller,
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required MaterialColor color,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: Text(l10n.reject),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.accept),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: Text(l10n.cancelOrder),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.done_all, size: 18),
          label: Text(l10n.markAsCompleted),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D4F54),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  _StatusData _getStatusData() {
    switch (order.status) {
      case OrderStatus.pending:
        return _StatusData(Colors.orange, Icons.hourglass_empty);
      case OrderStatus.accepted:
        return _StatusData(Colors.green, Icons.check_circle);
      case OrderStatus.rejected:
        return _StatusData(Colors.red, Icons.cancel);
      case OrderStatus.completed:
        return _StatusData(Colors.blue, Icons.done_all);
      case OrderStatus.cancelled:
        return _StatusData(Colors.grey, Icons.block);
    }
  }
}

class _StatusData {
  final Color color;
  final IconData icon;
  const _StatusData(this.color, this.icon);
}
