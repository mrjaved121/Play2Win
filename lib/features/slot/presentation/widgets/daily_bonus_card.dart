import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Compact "Daily Bonus" teaser card for the Home screen — gift icon,
/// spin progress and a Claim CTA. The full Rewards flow (countdown,
/// reward reveal animation) lives on the dedicated Rewards screen; this
/// is just the at-a-glance summary + entry point.
class DailyBonusCard extends StatelessWidget {
  const DailyBonusCard({
    required this.spinsCompleted,
    required this.spinsRequired,
    required this.rewardCoins,
    this.claimed = false,
    this.onClaim,
    this.onTap,
    super.key,
  });

  final int spinsCompleted;
  final int spinsRequired;
  final int rewardCoins;
  final bool claimed;
  final VoidCallback? onClaim;
  final VoidCallback? onTap;

  bool get _isReady => !claimed && spinsCompleted >= spinsRequired;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: _isReady ? AppColors.gold : AppColors.cardBorder,
      glow: _isReady ? AppShadows.goldGlow : AppShadows.card,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🎁', style: TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('Daily Bonus', style: AppTextStyles.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Spin $spinsRequired times',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientProgressBar(
            progress: spinsCompleted / spinsRequired,
            gradient: AppGradients.success,
          ),
          const SizedBox(height: 4),
          Text('$spinsCompleted/$spinsRequired', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 4),
              Text('$rewardCoins', style: AppTextStyles.titleSmall),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (claimed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('Claimed', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
              ],
            )
          else
            GradientButton.success(
              label: 'CLAIM',
              size: GradientButtonSize.small,
              onPressed: _isReady ? onClaim : null,
            ),
        ],
      ),
    );
  }
}
