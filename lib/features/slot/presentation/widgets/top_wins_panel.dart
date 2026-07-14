import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// One row of the Home screen's "Top Wins" mini-leaderboard.
class TopWinEntry {
  const TopWinEntry({
    required this.rank,
    required this.name,
    required this.coins,
    this.vipTier,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final int coins;
  final int? vipTier;
  final bool isCurrentUser;
}

/// Compact top-N winners list shown on the Home screen. The full
/// Leaderboard screen (top 10, trophy animation, tab bar) is a separate,
/// deeper feature — this is just the at-a-glance teaser.
class TopWinsPanel extends StatelessWidget {
  const TopWinsPanel({required this.entries, super.key});

  final List<TopWinEntry> entries;

  static const List<Color> _medalColors = <Color>[
    AppColors.gold,
    Color(0xFFC0C6D2),
    Color(0xFFE0A24B),
  ];

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SectionHeader(title: 'Top Wins', icon: Icons.emoji_events_rounded),
          const SizedBox(height: AppSpacing.sm),
          for (final TopWinEntry entry in entries) _TopWinRow(entry: entry, medalColors: _medalColors),
        ],
      ),
    );
  }
}

class _TopWinRow extends StatelessWidget {
  const _TopWinRow({required this.entry, required this.medalColors});

  final TopWinEntry entry;
  final List<Color> medalColors;

  @override
  Widget build(BuildContext context) {
    final bool isMedal = entry.rank <= 3;
    final Color rankColor = isMedal ? medalColors[entry.rank - 1] : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.gold.withValues(alpha: 0.12) : null,
        borderRadius: AppRadius.radiusSm,
        border: entry.isCurrentUser ? Border.all(color: AppColors.gold.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            child: isMedal
                ? Icon(Icons.emoji_events_rounded, size: 16, color: rankColor)
                : Text('${entry.rank}', style: AppTextStyles.bodySmall.copyWith(color: rankColor)),
          ),
          const SizedBox(width: AppSpacing.xs),
          AvatarBadge(size: 30, vipTier: entry.vipTier),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.isCurrentUser ? 'You' : entry.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: entry.isCurrentUser ? AppColors.gold : AppColors.textPrimary,
                fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: <Widget>[
              const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.gold),
              const SizedBox(width: 3),
              Text('${entry.coins}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
