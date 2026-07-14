import 'package:flutter/material.dart';

import '../../../slot/domain/entities/game_state.dart';

/// Which running [GameState] counter a mission tracks progress against.
///
/// All four are monotonically increasing (never decrease during a
/// session), which matters: mission progress is computed as
/// `currentValue - valueAtPeriodStart`, and that only works cleanly for
/// counters that never go backwards. [GameState.winStreak] was
/// deliberately left out of this enum for that reason — it resets to 0
/// on a loss, which would make simple baseline-diffing misleading.
enum MissionMetric { totalSpins, lifetimeWinnings, totalWins, jackpotsWon }

enum MissionPeriod { daily, weekly }

/// Static catalog entry for one mission. Not persisted itself — plain
/// compile-time data; [[MissionsNotifier]] combines this with live
/// [GameState] values and a per-period baseline to compute progress.
class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.metric,
    required this.target,
    required this.rewardCoins,
    required this.period,
  });

  final String id;
  final IconData icon;
  final String title;
  final MissionMetric metric;
  final int target;
  final int rewardCoins;
  final MissionPeriod period;

  int metricValue(GameState state) => switch (metric) {
        MissionMetric.totalSpins => state.totalSpins,
        MissionMetric.lifetimeWinnings => state.lifetimeWinnings,
        MissionMetric.totalWins => state.totalWins,
        MissionMetric.jackpotsWon => state.jackpotsWon,
      };

  static const List<MissionDefinition> catalog = <MissionDefinition>[
    MissionDefinition(
      id: 'daily_spin_10',
      icon: Icons.casino_rounded,
      title: 'Spin 10 Times',
      metric: MissionMetric.totalSpins,
      target: 10,
      rewardCoins: 50,
      period: MissionPeriod.daily,
    ),
    MissionDefinition(
      id: 'daily_win_500',
      icon: Icons.monetization_on_rounded,
      title: 'Win 500 Coins',
      metric: MissionMetric.lifetimeWinnings,
      target: 500,
      rewardCoins: 100,
      period: MissionPeriod.daily,
    ),
    MissionDefinition(
      id: 'daily_win_3',
      icon: Icons.local_fire_department_rounded,
      title: 'Win 3 Spins',
      metric: MissionMetric.totalWins,
      target: 3,
      rewardCoins: 75,
      period: MissionPeriod.daily,
    ),
    MissionDefinition(
      id: 'weekly_spin_100',
      icon: Icons.replay_circle_filled_rounded,
      title: 'Play 100 Spins',
      metric: MissionMetric.totalSpins,
      target: 100,
      rewardCoins: 300,
      period: MissionPeriod.weekly,
    ),
    MissionDefinition(
      id: 'weekly_jackpot_1',
      icon: Icons.emoji_events_rounded,
      title: 'Win the Jackpot Once',
      metric: MissionMetric.jackpotsWon,
      target: 1,
      rewardCoins: 500,
      period: MissionPeriod.weekly,
    ),
  ];
}
