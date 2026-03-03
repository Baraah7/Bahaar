import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing.dart';

Widget buildPaymentOption(PaymentMethod method, PaymentMethod? selectedPayment, Function(PaymentMethod) onChanged) {
  final isSelected = selectedPayment == method;
  return GestureDetector(
    onTap: () => onChanged(method),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0D4F54).withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D4F54).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF0D4F54).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0E7490).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              method == PaymentMethod.cash
                  ? Icons.money_rounded
                  : Icons.account_balance_wallet_rounded,
              size: 22,
              color: isSelected
                  ? const Color(0xFF0E7490)
                  : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isSelected
                        ? const Color(0xFF0D4F54)
                        : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method == PaymentMethod.cash
                      ? 'Pay with cash on delivery'
                      : 'Pay instantly via Benefit Pay',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D4F54) : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0D4F54)
                    : Colors.grey.shade300,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ],
      ),
    ),
  );
}
