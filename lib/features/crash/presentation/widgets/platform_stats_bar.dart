import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/crash_leaderboard.dart';
import '../providers/platform_leaderboard_provider.dart';

/// Always-visible platform-wide activity bar — "Number of bets / Total
/// bets / Total winnings" across every player, matching the reference
/// design's persistent stats banner (kept in our gold gradient rather than
/// its orange/red one).
class PlatformStatsBar extends ConsumerWidget {
  const PlatformStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CrashLeaderboard> platform = ref.watch(platformLeaderboardProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        borderRadius: AppRadius.radiusMd,
        boxShadow: AppShadows.button(AppColors.gold),
      ),
      child: platform.when(
        data: (CrashLeaderboard leaderboard) => Row(
          children: <Widget>[
            _Stat(icon: Icons.people_alt_rounded, label: 'Number of bets', value: '${leaderboard.totalBets}'),
            _Stat(icon: Icons.payments_rounded, label: 'Total bets', value: '${leaderboard.totalWagered} PKR'),
            _Stat(icon: Icons.emoji_events_rounded, label: 'Total winnings', value: '${leaderboard.totalPayout} PKR'),
          ],
        ),
        loading: () => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnGold),
          ),
        ),
        // Non-critical banner — a failed fetch just leaves the space blank
        // rather than surfacing an error over the game itself.
        error: (Object error, StackTrace stackTrace) => const SizedBox(height: 32),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.textOnGold),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnGold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.textOnGold.withValues(alpha: 0.8), fontSize: 9),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
