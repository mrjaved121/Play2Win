import 'package:flutter/material.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/theme.dart';
import 'entities/game_catalog_entry.dart';

/// The game hub's catalog: what's actually playable today plus the
/// studio roadmap's upcoming titles, shown as locked "Coming Soon" tiles
/// so the lobby reads as a growing collection rather than a single game.
abstract final class LobbyCatalog {
  static const List<GameCatalogEntry> games = <GameCatalogEntry>[
    GameCatalogEntry(
      id: 'slots',
      title: 'Slot Machine',
      icon: Icons.casino_rounded,
      accentColor: AppColors.gold,
      status: GameStatus.live,
      routeName: RouteNames.playSlots,
      badgeLabel: 'PLAY',
    ),
    GameCatalogEntry(
      id: 'lucky_wheel',
      title: 'Lucky Wheel',
      icon: Icons.donut_large_rounded,
      accentColor: AppColors.neonPurple,
      status: GameStatus.comingSoon,
    ),
    GameCatalogEntry(
      id: 'scratch_card',
      title: 'Scratch Card',
      icon: Icons.style_rounded,
      accentColor: AppColors.orange,
      status: GameStatus.comingSoon,
    ),
    GameCatalogEntry(
      id: 'match_3',
      title: 'Match-3',
      icon: Icons.grid_view_rounded,
      accentColor: AppColors.success,
      status: GameStatus.comingSoon,
    ),
    GameCatalogEntry(
      id: 'bubble_shooter',
      title: 'Bubble Shooter',
      icon: Icons.bubble_chart_rounded,
      accentColor: AppColors.info,
      status: GameStatus.comingSoon,
    ),
    GameCatalogEntry(
      id: 'idle_tycoon',
      title: 'Idle Tycoon',
      icon: Icons.apartment_rounded,
      accentColor: AppColors.warning,
      status: GameStatus.comingSoon,
    ),
  ];

  static List<GameCatalogEntry> get live =>
      games.where((GameCatalogEntry g) => g.status == GameStatus.live).toList();

  static List<GameCatalogEntry> get comingSoon =>
      games.where((GameCatalogEntry g) => g.status == GameStatus.comingSoon).toList();
}
