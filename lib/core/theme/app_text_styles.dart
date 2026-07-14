import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography.
///
/// [display] (Baloo 2) is a chunky, rounded display face used for the
/// jackpot ticker, big-win banners and hero numbers — it's what gives the
/// UI its "casino marquee" character. [body] (Plus Jakarta Sans) is a
/// clean geometric sans used for everything else so the UI stays legible
/// at small sizes.
///
/// Both are bundled as local assets (`assets/fonts/`, declared in
/// `pubspec.yaml`) rather than fetched at runtime via `google_fonts` —
/// that package blocks first paint on a network call to fonts.gstatic.com
/// per weight, which both fails outright when offline and works against
/// the "Offline Support" / performance goals for this app.
abstract final class AppTextStyles {
  static TextStyle get _displayBase => const TextStyle(
        fontFamily: 'Baloo2',
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.0,
      );

  static TextStyle get _bodyBase => const TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ---------------------------------------------------------------------
  // Display — jackpot / hero numbers / big win banners
  // ---------------------------------------------------------------------
  static TextStyle get displayJackpot => _displayBase.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppColors.gold,
      );

  static TextStyle get displayLarge => _displayBase.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get displayMedium => _displayBase.copyWith(fontSize: 26);

  static TextStyle get displaySmall => _displayBase.copyWith(fontSize: 22);

  // ---------------------------------------------------------------------
  // Headline / Title
  // ---------------------------------------------------------------------
  static TextStyle get headlineLarge => _bodyBase.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get headlineMedium => _bodyBase.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleLarge => _bodyBase.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => _bodyBase.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleSmall => _bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------
  static TextStyle get bodyLarge => _bodyBase.copyWith(fontSize: 16);

  static TextStyle get bodyMedium => _bodyBase.copyWith(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _bodyBase.copyWith(
        fontSize: 12,
        color: AppColors.textMuted,
      );

  // ---------------------------------------------------------------------
  // Labels / buttons / numeric counters
  // ---------------------------------------------------------------------
  static TextStyle get buttonLarge => _bodyBase.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.textPrimary,
      );

  static TextStyle get buttonMedium => _bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );

  static TextStyle get label => _bodyBase.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );

  /// Tabular figures for balance / bet / counters so digits don't jitter
  /// horizontally as they animate/count up.
  static TextStyle get counter => _displayBase.copyWith(
        fontSize: 20,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
}
