import 'package:flutter/material.dart';
import 'package:bahaar/core/constants/app_colors.dart';

class AppLoadingView extends StatelessWidget {
  final String message;
  final Color? color;

  const AppLoadingView({super.key, required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: color ?? AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: color ?? AppColors.primary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
