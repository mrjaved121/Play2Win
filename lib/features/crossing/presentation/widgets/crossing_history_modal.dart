import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/crossing_leaderboard.dart';
import '../../domain/entities/crossing_round.dart';
import '../providers/crossing_providers.dart';
import '../providers/platform_crossing_leaderboard_provider.dart';

/// Round-history popup: this session's own resolved rounds (date/bet/
/// difficulty/lanes cleared/multiplier/win), plus the platform-wide
/// "All-Time Top Wins" list — mirrors Multiplier Climb's history modal.
Future<void> showCrossingHistoryModal(BuildContext context, CrossingSharedState state) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _CrossingHistorySheet(state: state),
  );
}

class _CrossingHistorySheet extends StatelessWidget {
  const _CrossingHistorySheet({required this.state});

  final CrossingSharedState state;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.backgroundElevated,
            child: Column(
              children: <Widget>[
                _HistoryHeader(onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: <Widget>[
                      _SessionStatsRow(state: state),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: Text('No rounds played yet this session', style: AppTextStyles.bodySmall),
                          ),
                        )
                      else
                        ...state.history.map(
                          (CrossingHistoryEntry entry) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _HistoryRoundCard(entry: entry),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('ALL-TIME TOP WINS', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      const _TopWinsList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: const BoxDecoration(gradient: AppGradients.gold),
      child: Row(
        children: <Widget>[
          const Icon(Icons.history_rounded, color: AppColors.textOnGold),
          const SizedBox(width: AppSpacing.sm),
          Text('MY BET HISTORY', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textOnGold)),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Close',
            child: PressableScale(
              onTap: onClose,
              child: const Icon(Icons.close_rounded, color: AppColors.textOnGold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionStatsRow extends StatelessWidget {
  const _SessionStatsRow({required this.state});

  final CrossingSharedState state;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) {
      return Expanded(
        child: Column(
          children: <Widget>[
            Text(value, style: AppTextStyles.titleMedium),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(gradient: AppGradients.card, borderRadius: AppRadius.radiusMd),
      child: Row(
        children: <Widget>[
          stat('Rounds', '${state.sessionRoundsCount}'),
          stat('Total Bet', '${state.sessionTotalBet} CR'),
          stat('Winnings', '${state.sessionTotalWinnings} CR'),
        ],
      ),
    );
  }
}

class _HistoryRoundCard extends StatelessWidget {
  const _HistoryRoundCard({required this.entry});

  final CrossingHistoryEntry entry;

  String get _shortRoundId {
    final String id = entry.roundId;
    return id.length <= 8 ? id : id.substring(id.length - 8);
  }

  String get _timestamp {
    final DateTime t = entry.timestamp.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final Color valueColor = entry.voided
        ? AppColors.textSecondary
        : entry.isWin
            ? AppColors.success
            : AppColors.error;

    Widget field(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: AppTextStyles.bodySmall),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(gradient: AppGradients.card, borderRadius: AppRadius.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: <InlineSpan>[
                    const TextSpan(text: 'ROUND ID '),
                    TextSpan(text: _shortRoundId, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Text(_timestamp, style: AppTextStyles.bodySmall),
            ],
          ),
          if (entry.voided) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'VOIDED BY ADMIN — BET REFUNDED',
              style: AppTextStyles.bodySmall.copyWith(color: valueColor, fontWeight: FontWeight.w700),
            ),
          ],
          field('DIFFICULTY', entry.difficulty.label),
          field('BET', '${entry.bet} CR'),
          field('LANES CLEARED', '${entry.lanesCleared}'),
          field(entry.voided ? 'REFUNDED' : (entry.isWin ? 'CASHED OUT' : 'RESULT'), entry.isWin ? '${entry.multiplier.toStringAsFixed(2)}x' : 'Busted'),
          field('WIN', '${entry.winAmount} CR'),
        ],
      ),
    );
  }
}

class _TopWinsList extends ConsumerWidget {
  const _TopWinsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CrossingLeaderboard> platform = ref.watch(platformCrossingLeaderboardProvider);
    return platform.when(
      data: (CrossingLeaderboard leaderboard) {
        if (leaderboard.topWins.isEmpty) {
          return Text('No rounds won yet', style: AppTextStyles.bodySmall);
        }
        return Column(
          children: leaderboard.topWins
              .map(
                (CrossingLeaderboardEntry entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: const BoxDecoration(gradient: AppGradients.card, borderRadius: AppRadius.radiusSm),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Text(entry.playerName, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${entry.multiplier.toStringAsFixed(2)}x',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '+${entry.payout}',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (Object error, StackTrace stackTrace) => Text("Couldn't load", style: AppTextStyles.bodySmall),
    );
  }
}
