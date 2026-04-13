// Shared background + button widgets for auth screens (login & sign-up).
import 'dart:math' show Random;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:bahaar/core/constants/app_colors.dart';

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
    _blob(canvas, size, 0.10, 0.15, 0.55, const Color(0xFF1E7A8E));
    _blob(canvas, size, 0.92, 0.05, 0.70, const Color(0xFF162D5A));
    _blob(canvas, size, 0.15, 0.48, 0.65, const Color(0xFF1E8EA4));
    _blob(canvas, size, 0.88, 0.40, 0.60, const Color(0xFF17406A));
    _blob(canvas, size, 0.50, 0.80, 0.70, const Color(0xFF29B8C8));
    _blob(canvas, size, 0.90, 0.90, 0.55, const Color(0xFF0F2040));
    _blob(canvas, size, 0.38, 0.18, 0.45, const Color(0xFF155E75));
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

// ── Gradient CTA button (pill shape) ─────────────────────────────────────────

class AuthGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthGradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(27),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF004A63), Color(0xFF002535)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade800]),
              borderRadius: BorderRadius.circular(27),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF004A63).withValues(alpha: 0.50),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
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
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
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
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
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
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.accent)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.20),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(27)),
          borderSide: BorderSide(color: kAuthTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}

// ── Social sign-in button ─────────────────────────────────────────────────────

class AuthSocialBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const AuthSocialBtn({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.tan.withValues(alpha: 0.10),
          border: Border.all(color: AppColors.tan.withValues(alpha: 0.20), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
