import 'package:bahaar/constants/app_colors.dart';
import 'package:flutter/material.dart';

class MapIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final Color activeColor;

  const MapIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
    this.activeColor = AppColors.red,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onPressed == null
        ? Colors.grey.shade400
        : isActive
            ? activeColor
            : Colors.blueGrey.shade700;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }
}
