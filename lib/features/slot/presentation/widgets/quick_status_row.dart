import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Compact single-row summary of Daily Bonus progress, win streak and
/// the current limited-time offer countdown — replaces the full-size
/// [DailyBonusCard]/[WinStreakCard]/[PromoTicker] on phones, where that
/// vertical space is needed to keep the reel itself always on-screen
/// (see `HomeScreen` doc comment). Those full cards are still used in
/// the tablet/web side panel, where space isn't as tight.
class QuickStatusRow extends StatelessWidget {
  const QuickStatusRow({
    required this.dailyBonusReady,
    required this.dailyBonusProgress,
    required this.winStreak,
    required this.offerRemaining,
    required this.onDailyBonusTap,
    this.showDailyBonus = true,
    super.key,
  });

  final bool dailyBonusReady;
  final String dailyBonusProgress;
  final int winStreak;
  final Duration offerRemaining;
  final VoidCallback onDailyBonusTap;

  /// False hides the badge entirely (see AppConstants.dailyBonusEnabled)
  /// rather than showing one that does nothing when tapped.
  final bool showDailyBonus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          if (showDailyBonus) ...<Widget>[
            PressableScale(
              onTap: onDailyBonusTap,
              child: BadgePill(
                label: dailyBonusReady ? 'BONUS READY' : 'BONUS $dailyBonusProgress',
                icon: Icons.card_giftcard_rounded,
                color: AppColors.success,
                filled: dailyBonusReady,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (winStreak > 0) ...<Widget>[
            BadgePill(label: '$winStreak STREAK', icon: Icons.local_fire_department_rounded, color: AppColors.orange),
            const SizedBox(width: AppSpacing.sm),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.timer_rounded, size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Text('OFFER', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.error)),
              const SizedBox(width: 4),
              CountdownText(
                duration: offerRemaining,
                style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
