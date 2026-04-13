/* UNUSED FILE - commented out
﻿import 'package:flutter/material.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.4),
              ),
              const SizedBox(height: 2),
              Text(
                value?.isNotEmpty == true ? value! : '—',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
*/
