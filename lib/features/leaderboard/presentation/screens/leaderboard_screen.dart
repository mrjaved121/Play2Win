import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../widgets/leaderboard_entry.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_row.dart';

enum _LeaderboardRange { daily, weekly, allTime }

/// Leaderboard tab: range selector, top-3 podium and ranked rows 4-10.
///
/// There's no live multiplayer backend to source other players' scores
/// from, so those stay realistic mock data — but "You"'s row uses the
/// player's real [gameProvider] balance and is re-ranked live against
/// the mock field instead of being pinned at a fixed spot.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  _LeaderboardRange _range = _LeaderboardRange.weekly;

  static const List<(String name, int coins, int vipTier)> _mockPlayers = <(String, int, int)>[
    ('ShadowWolf99', 41000, 4),
    ('MegaWinner22', 39400, 3),
    ('LuckyStrike', 39300, 2),
    ('SpinQueen', 36400, 2),
    ('GoldRush88', 34200, 1),
    ('CoinCollector', 31800, 0),
    ('NightOwlSpins', 29500, 1),
    ('ReelDeal', 27100, 0),
    ('FortuneFinder', 25000, 0),
  ];

  List<LeaderboardEntry> _rankedEntries(int myBalance) {
    final List<(String name, int coins, int vipTier, bool isMe)> combined = <(String, int, int, bool)>[
      for (final (String name, int coins, int vipTier) p in _mockPlayers) (p.$1, p.$2, p.$3, false),
      ('You', myBalance, 0, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return <LeaderboardEntry>[
      for (int i = 0; i < combined.length; i++)
        LeaderboardEntry(
          rank: i + 1,
          name: combined[i].$1,
          coins: combined[i].$2,
          vipTier: combined[i].$3,
          isCurrentUser: combined[i].$4,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final int myBalance = ref.watch(gameProvider).balance;
    final List<LeaderboardEntry> entries = _rankedEntries(myBalance);
    final List<LeaderboardEntry> top3 = entries.take(3).toList();
    final List<LeaderboardEntry> rest = entries.skip(3).toList();

    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Text('Leaderboard', style: AppTextStyles.displaySmall),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _RangeSelector(
              value: _range,
              onChanged: (_LeaderboardRange value) => setState(() => _range = value),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              children: <Widget>[
                LeaderboardPodium(top3: top3),
                const SizedBox(height: AppSpacing.xl),
                for (final LeaderboardEntry entry in rest) LeaderboardRow(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.value, required this.onChanged});

  final _LeaderboardRange value;
  final ValueChanged<_LeaderboardRange> onChanged;

  static const Map<_LeaderboardRange, String> _labels = <_LeaderboardRange, String>{
    _LeaderboardRange.daily: 'Daily',
    _LeaderboardRange.weekly: 'Weekly',
    _LeaderboardRange.allTime: 'All-Time',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardPurple,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          for (final _LeaderboardRange range in _LeaderboardRange.values)
            Expanded(
              child: PressableScale(
                onTap: () => onChanged(range),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: range == value ? AppGradients.neonPurple : null,
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    _labels[range]!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: range == value ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
