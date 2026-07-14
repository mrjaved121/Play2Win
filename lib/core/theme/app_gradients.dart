import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable gradients that give the app its "premium casino" feel.
///
/// Prefer these over ad-hoc [LinearGradient] instances so lighting and
/// brand feel stay consistent across every screen.
abstract final class AppGradients {
  /// Full-screen backdrop: deep purple/black with a subtle radial glow.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF1A0F2E),
      AppColors.background,
      AppColors.backgroundDeep,
    ],
    stops: <double>[0.0, 0.45, 1.0],
  );

  /// Dark purple card surface with a faint highlight at the top edge.
  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.cardPurpleLight, AppColors.cardPurple],
  );

  /// Glassmorphism fill — pair with a blur filter + [AppColors.glassBorder].
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x33FFFFFF), Color(0x0DFFFFFF)],
  );

  /// Primary call-to-action gradient (SPIN button, primary CTAs).
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.orange, AppColors.orangeDark],
  );

  /// Gold gradient for jackpot / premium accents.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.goldLight, AppColors.gold, AppColors.goldDark],
  );

  /// Neon purple gradient for secondary CTAs (Auto Spin, Double).
  static const LinearGradient neonPurple = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.neonPurpleLight, AppColors.neonPurpleDark],
  );

  /// Success gradient (claim / positive confirmation buttons).
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF4EE39A), AppColors.success],
  );

  /// Metallic gold border gradient for the slot machine reel frame.
  static const LinearGradient metallicGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.goldLight,
      AppColors.gold,
      AppColors.goldDark,
      AppColors.gold,
      AppColors.goldLight,
    ],
    stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Jackpot marquee gradient (deep red -> gold), used behind jackpot text.
  static const LinearGradient jackpot = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.jackpotRed, Color(0xFF5C0913)],
  );

  /// Shimmer sweep used for loading placeholders.
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: <Color>[
      Color(0x00FFFFFF),
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: <double>[0.35, 0.5, 0.65],
  );

  /// Radial glow used behind the jackpot/hero elements.
  static RadialGradient radialGlow(Color color, {double opacity = 0.35}) {
    return RadialGradient(
      colors: <Color>[color.withValues(alpha: opacity), color.withValues(alpha: 0.0)],
    );
  }
}
