import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/missions_providers.dart';

/// One mission row: icon, title, progress bar and a reward/claim CTA.
class MissionCard extends StatelessWidget {
  const MissionCard({required this.mission, this.onClaim, super.key});

  final MissionProgressView mission;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final bool ready = mission.isComplete && !mission.claimed;

    return PremiumCard(
      borderColor: ready ? AppColors.success : AppColors.cardBorder,
      glow: ready ? AppShadows.successGlow : AppShadows.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.16),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(mission.definition.icon, color: AppColors.neonPurpleLight, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  mission.definition.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                GradientProgressBar(
                  progress: mission.progress / mission.definition.target,
                  gradient: mission.isComplete ? AppGradients.success : AppGradients.neonPurple,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mission.progress}/${mission.definition.target}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _RewardAction(mission: mission, ready: ready, onClaim: onClaim),
        ],
      ),
    );
  }
}

class _RewardAction extends StatelessWidget {
  const _RewardAction({required this.mission, required this.ready, this.onClaim});

  final MissionProgressView mission;
  final bool ready;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    if (mission.claimed) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22);
    }

    if (ready) {
      return SizedBox(
        width: 84,
        child: GradientButton.success(
          label: 'CLAIM',
          size: GradientButtonSize.small,
          onPressed: onClaim,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.monetization_on_rounded, size: 16, color: AppColors.gold),
        const SizedBox(height: 2),
        Text('${mission.definition.rewardCoins}', style: AppTextStyles.bodySmall),
      ],
    );
  }
}
