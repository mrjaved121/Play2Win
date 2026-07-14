import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/achievements_providers.dart';

/// A single achievement tile: glowing gold badge when unlocked, muted
/// and padlocked when not.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({required this.achievement, super.key});

  final AchievementView achievement;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = achievement.unlocked;

    Widget badge = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: unlocked ? AppGradients.gold : null,
        color: unlocked ? null : AppColors.cardPurple,
        shape: BoxShape.circle,
        border: Border.all(color: unlocked ? AppColors.goldLight : AppColors.cardBorder),
        boxShadow: unlocked ? AppShadows.goldGlow : null,
      ),
      child: Icon(
        unlocked ? achievement.definition.icon : Icons.lock_rounded,
        color: unlocked ? AppColors.textOnGold : AppColors.textMuted,
        size: 28,
      ),
    );

    if (unlocked) {
      badge = badge
          .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
          .scaleXY(end: 1.06, duration: 1500.ms, curve: Curves.easeInOut);
    }

    return PremiumCard(
      borderColor: unlocked ? AppColors.gold : AppColors.cardBorder,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          badge,
          const SizedBox(height: AppSpacing.sm),
          Text(
            achievement.definition.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            achievement.definition.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
