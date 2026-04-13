/* UNUSED FILE - commented out
import 'package:flutter/material.dart';

/// Symmetric wave clipper — both edges at the same y so the wave appears
/// seamless when pages slide horizontally in a PageView.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.cubicTo(
      size.width * 0.25, size.height + 18,
      size.width * 0.75, size.height - 52,
      size.width, size.height - 24,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}
*/
