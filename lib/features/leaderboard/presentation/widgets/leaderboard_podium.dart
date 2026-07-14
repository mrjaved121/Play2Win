import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import 'leaderboard_entry.dart';

/// Top-3 podium: #1 elevated in the center with a slowly bobbing trophy,
/// #2 and #3 flanking at a shorter height.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({required this.top3, super.key});

  /// Exactly 3 entries, ranked 1-3.
  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    final LeaderboardEntry first = top3[0];
    final LeaderboardEntry second = top3[1];
    final LeaderboardEntry third = top3[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _PodiumColumn(entry: second, height: 96, medalColor: const Color(0xFFC0C6D2))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(entry: first, height: 128, medalColor: AppColors.gold, crown: true)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(entry: third, height: 76, medalColor: const Color(0xFFE0A24B))),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.medalColor,
    this.crown = false,
  });

  final LeaderboardEntry entry;
  final double height;
  final Color medalColor;
  final bool crown;

  @override
  Widget build(BuildContext context) {
    final Widget trophy = Icon(Icons.emoji_events_rounded, color: medalColor, size: crown ? 28 : 22)
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1400.ms, curve: Curves.easeInOut);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        trophy,
        const SizedBox(height: AppSpacing.xs),
        AvatarBadge(size: crown ? 60 : 48, vipTier: entry.vipTier),
        const SizedBox(height: AppSpacing.xs),
        Text(
          entry.isCurrentUser ? 'You' : entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: entry.isCurrentUser ? AppColors.gold : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.gold),
            const SizedBox(width: 2),
            Text(entry.coins.asGrouped, style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[medalColor.withValues(alpha: 0.35), medalColor.withValues(alpha: 0.08)],
            ),
            border: Border.all(color: medalColor.withValues(alpha: 0.6)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            '#${entry.rank}',
            style: AppTextStyles.displaySmall.copyWith(color: medalColor),
          ),
        ),
      ],
    );
  }
}
