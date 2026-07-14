import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Compact "Win Streak" teaser card for the Home screen — pulses gently
/// while a streak is active to draw the eye without being obnoxious.
class WinStreakCard extends StatelessWidget {
  const WinStreakCard({
    required this.streak,
    required this.streakBonusCoins,
    super.key,
  });

  final int streak;
  final int streakBonusCoins;

  @override
  Widget build(BuildContext context) {
    final Widget card = PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: streak > 0 ? AppColors.orange : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Win Streak', style: AppTextStyles.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text('$streak', style: AppTextStyles.displaySmall.copyWith(color: AppColors.orange)),
              const SizedBox(width: AppSpacing.xs),
              Text('STREAK', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 4),
              Text('$streakBonusCoins', style: AppTextStyles.titleSmall),
            ],
          ),
        ],
      ),
    );

    if (streak <= 0) return card;

    return card
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .scaleXY(end: 1.015, duration: 1200.ms, curve: Curves.easeInOut);
  }
}
