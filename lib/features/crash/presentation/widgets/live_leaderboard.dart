import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/mock_leaderboard.dart';
import '../providers/crash_providers.dart';
import '../providers/mock_leaderboard_provider.dart';

/// Persistent, always-visible "who's playing this round" list — see
/// [MockLeaderboardNotifier]'s doc comment for why this is a client-side
/// simulation rather than real other-player data. Each row's cashed-out/
/// busted state is derived live from [activeSlot]'s
/// `displayMultiplier` (while running) or the revealed
/// [CrashRound.crashPoint] (once resolved), so it tracks whichever real
/// bet panel is currently flying rather than its own timer. The
/// platform-wide "All-Time Top Wins" (real data) lives in the History
/// modal instead of here.
class LiveLeaderboard extends ConsumerWidget {
  const LiveLeaderboard({required this.activeSlot, super.key});

  /// Whichever [CrashSlotState] is currently the "active flight" — computed
  /// once in `crash_screen.dart` so this and [MultiplierStage] never
  /// disagree on which panel's round is the one to track.
  final CrashSlotState activeSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CrashSlotState crash = activeSlot;
    final List<LeaderboardSeed> seeds = ref.watch(mockLeaderboardProvider);

    if (seeds.isEmpty) {
      return Center(
        child: Text('Place a bet to see who else is playing', style: AppTextStyles.bodySmall),
      );
    }

    final double? referenceMultiplier = crash.phase == CrashPhase.idle
        ? null
        : (crash.phase == CrashPhase.resolved
            ? (crash.round?.crashPoint ?? crash.round?.resolvedMultiplier ?? crash.displayMultiplier)
            : crash.displayMultiplier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _LeaderboardHeaderRow(),
        const Divider(height: AppSpacing.md, color: AppColors.cardBorder),
        Expanded(
          child: ListView.separated(
            itemCount: seeds.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (BuildContext context, int index) {
              final LeaderboardSeed seed = seeds[index];
              final bool cashedOut = referenceMultiplier != null && seed.targetMultiplier <= referenceMultiplier;
              final bool busted = crash.phase == CrashPhase.resolved && !cashedOut;
              return _LeaderboardRow(seed: seed, cashedOut: cashedOut, busted: busted);
            },
          ),
        ),
      ],
    );
  }
}

class _LeaderboardHeaderRow extends StatelessWidget {
  const _LeaderboardHeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.label;
    return Row(
      children: <Widget>[
        Expanded(flex: 3, child: Text('USERNAME', style: style)),
        Expanded(flex: 2, child: Text('ODDS', style: style, textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text('BET', style: style, textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text('WIN', style: style, textAlign: TextAlign.right)),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.seed, required this.cashedOut, required this.busted});

  final LeaderboardSeed seed;
  final bool cashedOut;
  final bool busted;

  @override
  Widget build(BuildContext context) {
    final int winAmount = cashedOut ? (seed.bet * seed.targetMultiplier).round() : 0;
    final Color statusColor = cashedOut ? AppColors.success : (busted ? AppColors.error : AppColors.textSecondary);

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Text(seed.username, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${seed.targetMultiplier.toStringAsFixed(2)}x',
            style: AppTextStyles.bodyMedium.copyWith(color: statusColor),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('${seed.bet}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 2,
          child: Text(
            cashedOut ? '+$winAmount' : (busted ? 'Busted' : '—'),
            style: AppTextStyles.bodyMedium.copyWith(color: statusColor, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
