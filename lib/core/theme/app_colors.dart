import 'package:flutter/material.dart';

/// Centralized color palette for the premium casino UI.
///
/// All screens must source color from here rather than hardcoding hex
/// values, so the palette can be retuned globally (e.g. for a light theme
/// or a rebrand) from a single place.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------
  static const Color background = Color(0xFF0F081A);
  static const Color backgroundElevated = Color(0xFF160D26);
  static const Color backgroundDeep = Color(0xFF08040F);

  // ---------------------------------------------------------------------
  // Surfaces / Cards
  // ---------------------------------------------------------------------
  static const Color cardPurple = Color(0xFF1E1230);
  static const Color cardPurpleLight = Color(0xFF2A1A45);
  static const Color cardBorder = Color(0xFF3A2860);
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ---------------------------------------------------------------------
  // Accents
  // ---------------------------------------------------------------------
  static const Color gold = Color(0xFFFFC94A);
  static const Color goldLight = Color(0xFFFFE9A8);
  static const Color goldDark = Color(0xFFB8862A);

  static const Color neonPurple = Color(0xFFB14CFF);
  static const Color neonPurpleLight = Color(0xFFD68CFF);
  static const Color neonPurpleDark = Color(0xFF7B1FD9);

  static const Color orange = Color(0xFFFF8A1E);
  static const Color orangeDark = Color(0xFFE85D04);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF35D07F);
  static const Color warning = Color(0xFFFFA632);
  static const Color error = Color(0xFFFF4D5E);
  static const Color info = Color(0xFF4CC9FF);

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF7F1FF);
  static const Color textSecondary = Color(0xFFB6A6D9);
  static const Color textMuted = Color(0xFF7C6C99);
  static const Color textOnGold = Color(0xFF3A2408);

  // ---------------------------------------------------------------------
  // Slot reel / game specific
  // ---------------------------------------------------------------------
  static const Color reelFrame = Color(0xFFDDA53B);
  static const Color reelFrameLight = Color(0xFFFFE29A);
  static const Color reelBackground = Color(0xFF120A1F);
  static const Color winGlow = Color(0xFFFFD24C);
  static const Color jackpotRed = Color(0xFFB0121F);

  // ---------------------------------------------------------------------
  // VIP tiers (used for badges/frames, low -> high)
  // ---------------------------------------------------------------------
  static const List<Color> vipTierColors = <Color>[
    Color(0xFF9BA3B0), // bronze/silver base
    Color(0xFFE0A24B), // bronze
    Color(0xFFC0C6D2), // silver
    Color(0xFFFFC94A), // gold
    Color(0xFFB14CFF), // platinum / neon
  ];
}
