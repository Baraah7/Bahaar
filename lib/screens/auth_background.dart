// Shared background + button widgets for auth screens (login & sign-up).
import 'dart:math' show Random;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:Bahaar/core/constants/app_colors.dart';

const kAuthTeal     = AppColors.accent;   // #4597a8
const kAuthTealDark = AppColors.primary;  // #005b74

// ── Mesh gradient full-screen background ─────────────────────────────────────

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF082028)),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: CustomPaint(
            painter: AuthBlobsPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        CustomPaint(
          painter: AuthGrainPainter(),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

class AuthBlobsPainter extends CustomPainter {
  void _blob(Canvas c, Size s, double fx, double fy, double fr, Color color) {
    final center = Offset(s.width * fx, s.height * fy);
    final radius = s.width * fr;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _blob(canvas, size, 0.10, 0.08, 0.75, const Color(0xFF4ECBD8));
    _blob(canvas, size, 0.92, 0.05, 0.70, const Color(0xFF162D5A));
    _blob(canvas, size, 0.15, 0.48, 0.65, const Color(0xFF1E8EA4));
    _blob(canvas, size, 0.88, 0.40, 0.60, const Color(0xFF17406A));
    _blob(canvas, size, 0.50, 0.80, 0.70, const Color(0xFF29B8C8));
    _blob(canvas, size, 0.90, 0.90, 0.55, const Color(0xFF0F2040));
    _blob(canvas, size, 0.38, 0.12, 0.50, const Color(0xFFAADDE6));
  }

  @override
  bool shouldRepaint(AuthBlobsPainter _) => false;
}

class AuthGrainPainter extends CustomPainter {
  static final _rand = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    for (var i = 0; i < 18000; i++) {
      final x = _rand.nextDouble() * size.width;
      final y = _rand.nextDouble() * size.height;
      paint.color =
          Colors.white.withValues(alpha: _rand.nextDouble() * 0.055);
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(AuthGrainPainter _) => false;
}

// ── Gradient CTA button ───────────────────────────────────────────────────────

class AuthGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [kAuthTeal, kAuthTealDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade800, Colors.grey.shade800]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: kAuthTeal.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0A2A30)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.primary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.accent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: kAuthTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}
