import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import 'leaderboard_entry.dart';

/// A single rank-4-and-below leaderboard row.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({required this.entry, super.key});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: entry.isCurrentUser ? AppColors.gold : AppColors.cardBorder,
        ),
        boxShadow: entry.isCurrentUser ? AppShadows.glow(AppColors.gold, intensity: 0.5) : null,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          AvatarBadge(size: 40, vipTier: entry.vipTier),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.isCurrentUser ? 'You' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                color: entry.isCurrentUser ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: <Widget>[
              const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(entry.coins.asGrouped, style: AppTextStyles.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}
