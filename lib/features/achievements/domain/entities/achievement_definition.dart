import 'package:flutter/material.dart';

import '../../../slot/domain/entities/game_state.dart';

/// Static catalog entry for one achievement. Unlike missions, these
/// don't reset — once [isUnlocked] is true for a given [GameState] it
/// stays true, since all the underlying counters are monotonically
/// increasing lifetime totals.
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  final String id;
  final IconData icon;
  final String title;
  final String description;
  final bool Function(GameState state) isUnlocked;

  static const List<AchievementDefinition> catalog = <AchievementDefinition>[
    AchievementDefinition(
      id: 'first_win',
      icon: Icons.flag_circle_rounded,
      title: 'First Win',
      description: 'Win your first spin',
      isUnlocked: _firstWin,
    ),
    AchievementDefinition(
      id: 'century_club',
      icon: Icons.casino_rounded,
      title: '100 Spins',
      description: 'Play 100 total spins',
      isUnlocked: _centuryClub,
    ),
    AchievementDefinition(
      id: 'jackpot_winner',
      icon: Icons.emoji_events_rounded,
      title: 'Jackpot Winner',
      description: 'Hit the jackpot once',
      isUnlocked: _jackpotWinner,
    ),
    AchievementDefinition(
      id: 'lucky_streak',
      icon: Icons.auto_awesome_rounded,
      title: 'Lucky Player',
      description: 'Win 10 spins total',
      isUnlocked: _luckyStreak,
    ),
    AchievementDefinition(
      id: 'high_roller',
      icon: Icons.diamond_rounded,
      title: 'High Roller',
      description: 'Earn 1,000 lifetime coins',
      isUnlocked: _highRoller,
    ),
    AchievementDefinition(
      id: 'big_spender',
      icon: Icons.military_tech_rounded,
      title: 'Big Win',
      description: 'Win 500+ coins in a single spin',
      isUnlocked: _bigSpender,
    ),
  ];

  static bool _firstWin(GameState s) => s.totalWins >= 1;
  static bool _centuryClub(GameState s) => s.totalSpins >= 100;
  static bool _jackpotWinner(GameState s) => s.jackpotsWon >= 1;
  static bool _luckyStreak(GameState s) => s.totalWins >= 10;
  static bool _highRoller(GameState s) => s.lifetimeWinnings >= 1000;
  static bool _bigSpender(GameState s) => s.bestWinToday >= 500;
}
