import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../rewards/presentation/providers/daily_bonus_providers.dart';
import '../../../slot/domain/entities/game_state.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../../slot/presentation/widgets/daily_bonus_card.dart';
import '../../domain/entities/game_catalog_entry.dart';
import '../../domain/lobby_catalog.dart';
import '../providers/favorites_providers.dart';
import '../providers/recently_played_providers.dart';
import '../widgets/category_browse_sheet.dart';
import '../widgets/category_chip_row.dart';
import '../widgets/game_card.dart';
import '../widgets/game_launch_sheet.dart';
import '../widgets/game_search_sheet.dart';
import '../widgets/lobby_header.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/recent_winners_ticker.dart';

/// The Home tab: a game hub rather than a single game. "Top Games" holds
/// what's actually playable today (just the slot machine for now); "Coming
/// Soon" previews the rest of the studio roadmap as locked tiles, so the
/// lobby reads as a growing collection from day one instead of needing a
/// second game to ship before the pattern makes sense.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  CategoryFilter _filter = CategoryFilter.all;

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.backgroundElevated,
          content: Text('$title is coming soon!', style: AppTextStyles.bodyMedium),
        ),
      );
  }

  void _openGame(GameCatalogEntry entry) {
    if (entry.isLive) {
      showGameLaunchSheet(context, entry);
    } else {
      _showComingSoon(entry.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final GameState game = ref.watch(gameProvider);
    final String playerName = ref.watch(playerNameProvider);
    final int dailyCompleted = ref.watch(dailyBonusSpinsCompletedProvider);
    final bool dailyClaimed = ref.watch(dailyBonusProvider).claimed;
    final Set<String> favorites = ref.watch(favoritesProvider);
    final List<String> recentlyPlayedIds = ref.watch(recentlyPlayedProvider);
    final List<GameCatalogEntry> recentlyPlayed = <GameCatalogEntry>[
      for (final String id in recentlyPlayedIds)
        ...LobbyCatalog.games.where((GameCatalogEntry e) => e.id == id),
    ];

    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          LobbyHeader(
            playerName: playerName,
            balance: game.balance,
            jackpot: game.jackpot,
            onSearchTap: () => showGameSearchSheet(context, onSelect: _openGame),
          ),
          const SizedBox(height: AppSpacing.lg),
          const RecentWinnersTicker(),
          const SizedBox(height: AppSpacing.lg),
          PromoCarousel(
            slides: <Widget>[
              JackpotPromoSlide(
                jackpot: game.jackpot,
                onPlay: () => context.pushNamed(RouteNames.playSlots),
              ),
              JackpotTierSlide(
                jackpot: game.jackpot,
                onPlay: () => context.pushNamed(RouteNames.playSlots),
              ),
              DailyBonusCard(
                spinsCompleted: dailyCompleted,
                spinsRequired: AppConstants.dailyBonusRequiredSpins,
                rewardCoins: AppConstants.dailyBonusReward,
                claimed: dailyClaimed,
                onTap: () => context.pushNamed(RouteNames.rewards),
                onClaim: () => ref.read(dailyBonusProvider.notifier).claim(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          CategoryChipRow(
            selected: _filter,
            onSelected: (CategoryFilter f) => setState(() => _filter = f),
            onBrowseTap: () => showCategoryBrowseSheet(
              context,
              selected: _filter,
              onSelected: (CategoryFilter f) => setState(() => _filter = f),
            ),
          ),
          if (recentlyPlayed.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Recently Played', icon: Icons.history_rounded),
            const SizedBox(height: AppSpacing.md),
            _GameRow(
              entries: recentlyPlayed,
              favorites: favorites,
              onTap: _openGame,
              onToggleFavorite: (GameCatalogEntry e) =>
                  ref.read(favoritesProvider.notifier).toggle(e.id),
            ),
          ],
          if (_filter != CategoryFilter.comingSoon) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Top Games', icon: Icons.local_fire_department_rounded),
            const SizedBox(height: AppSpacing.md),
            _GameRow(
              entries: LobbyCatalog.live,
              favorites: favorites,
              onTap: _openGame,
              onToggleFavorite: (GameCatalogEntry e) =>
                  ref.read(favoritesProvider.notifier).toggle(e.id),
            ),
          ],
          if (_filter != CategoryFilter.live) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Coming Soon', icon: Icons.upcoming_rounded),
            const SizedBox(height: AppSpacing.md),
            _GameRow(
              entries: LobbyCatalog.comingSoon,
              favorites: favorites,
              onTap: _openGame,
              onToggleFavorite: (GameCatalogEntry e) =>
                  ref.read(favoritesProvider.notifier).toggle(e.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.entries,
    required this.favorites,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final List<GameCatalogEntry> entries;
  final Set<String> favorites;
  final ValueChanged<GameCatalogEntry> onTap;
  final ValueChanged<GameCatalogEntry> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) {
          final GameCatalogEntry entry = entries[i];
          return GameCard(
            entry: entry,
            onTap: () => onTap(entry),
            onLockedTap: () => onTap(entry),
            isFavorite: favorites.contains(entry.id),
            onToggleFavorite: entry.isLive ? () => onToggleFavorite(entry) : null,
          );
        },
      ),
    );
  }
}
