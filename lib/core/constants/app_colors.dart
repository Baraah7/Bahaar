import 'package:flutter/material.dart';

/// Bahaar brand palette
abstract final class AppColors {
  /// Deep crimson — danger / restricted zones / warnings
  static const red        = Color(0xFF6B0911);

  /// Deep ocean teal — primary brand, app bars, nav
  static const primary    = Color(0xFF005B74);

  /// Medium sea teal — accents, icons, links, focus borders
  static const accent     = Color(0xFF4597A8);

  /// Driftwood brown — warm secondary elements
  static const brown      = Color(0xFF8E7355);

  /// Sandy tan — selected nav items, chips, subtle highlights
  static const tan        = Color(0xFFD5B693);

  /// Pearl cream — scaffold backgrounds, cards
  static const cream      = Color(0xFFFAF7E8);

  // ── Convenience aliases ──────────────────────────────────────────────────
  static const white      = Colors.white;
  static const transparent = Colors.transparent;
}
