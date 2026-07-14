import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Premium drop-shadows and neon glow effects.
///
/// Glows are implemented as multiple stacked [BoxShadow]s (tight + wide
/// blur) which reads much closer to a real neon light than a single shadow.
abstract final class AppShadows {
  /// Soft elevation shadow for cards sitting on the dark background.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x1AFFFFFF),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  /// Elevated / pressed-forward card (leaderboard highlight, active tab).
  static const List<BoxShadow> cardElevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  /// Gold neon glow, e.g. jackpot frame, VIP badge, winning symbols.
  static List<BoxShadow> glow(Color color, {double intensity = 1.0}) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.55 * intensity),
        blurRadius: 8 * intensity,
        spreadRadius: 0.5,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.35 * intensity),
        blurRadius: 24 * intensity,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.18 * intensity),
        blurRadius: 48 * intensity,
        spreadRadius: 4,
      ),
    ];
  }

  static List<BoxShadow> get goldGlow => glow(AppColors.gold);
  static List<BoxShadow> get purpleGlow => glow(AppColors.neonPurple);
  static List<BoxShadow> get winGlow => glow(AppColors.winGlow, intensity: 1.3);
  static List<BoxShadow> get successGlow => glow(AppColors.success);
  static List<BoxShadow> get errorGlow => glow(AppColors.error);

  /// Inner-shadow-like effect for pressed/inset surfaces (bet stepper track).
  static const List<BoxShadow> inset = <BoxShadow>[
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Button drop shadow tinted to match the button's gradient color.
  static List<BoxShadow> button(Color tint) => <BoxShadow>[
        BoxShadow(
          color: tint.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
