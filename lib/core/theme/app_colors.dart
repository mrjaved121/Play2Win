import 'package:flutter/material.dart';

/// Centralized color palette for the premium casino UI.
///
/// All screens must source color from here rather than hardcoding hex
/// values, so the palette can be retuned globally (e.g. for a light theme
/// or a rebrand) from a single place.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Backgrounds — "Midnight & Gold Marquee"
  // ---------------------------------------------------------------------
  static const Color background = Color(0xFF170B26);
  static const Color backgroundElevated = Color(0xFF1F1033);
  static const Color backgroundDeep = Color(0xFF0F0619);

  // ---------------------------------------------------------------------
  // Surfaces / Cards
  // ---------------------------------------------------------------------
  static const Color cardPurple = Color(0xFF2C1244);
  static const Color cardPurpleLight = Color(0xFF3B1B5E);
  static const Color cardBorder = Color(0xFF4E2F72);
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ---------------------------------------------------------------------
  // Accents
  // ---------------------------------------------------------------------
  static const Color gold = Color(0xFFF2B94D);
  static const Color goldLight = Color(0xFFFFE29A);
  static const Color goldDark = Color(0xFFC98F2A);

  static const Color neonPurple = Color(0xFFFF3D78);
  static const Color neonPurpleLight = Color(0xFFFF7AA3);
  static const Color neonPurpleDark = Color(0xFFC41F56);

  static const Color orange = Color(0xFFFF8A3D);
  static const Color orangeDark = Color(0xFFD9601C);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF22D9A0);
  static const Color warning = Color(0xFFFFB648);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF4CD3E0);

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF7EEDD);
  static const Color textSecondary = Color(0xFFB49BC9);
  static const Color textMuted = Color(0xFF8674A3);
  static const Color textOnGold = Color(0xFF2A1400);

  // ---------------------------------------------------------------------
  // Slot reel / game specific
  // ---------------------------------------------------------------------
  static const Color reelFrame = Color(0xFFF2B94D);
  static const Color reelFrameLight = Color(0xFFFFE29A);
  static const Color reelBackground = Color(0xFF200E36);
  // A win now glows jade rather than gold, so a payout reads as a distinct
  // color event instead of a brighter version of the ambient chrome.
  static const Color winGlow = Color(0xFF22D9A0);
  static const Color jackpotRed = Color(0xFF7A1030);

  // ---------------------------------------------------------------------
  // VIP tiers (used for badges/frames, low -> high)
  // ---------------------------------------------------------------------
  static const List<Color> vipTierColors = <Color>[
    Color(0xFF9BA3B0), // bronze/silver base
    Color(0xFFE0A24B), // bronze
    Color(0xFFC0C6D2), // silver
    Color(0xFFF2B94D), // gold
    Color(0xFFFF3D78), // platinum / neon
  ];
}
