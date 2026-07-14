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
import '../widgets/game_card.dart';
import '../widgets/lobby_header.dart';
import '../widgets/promo_carousel.dart';

/// The Home tab: a game hub rather than a single game. "Top Games" holds
/// what's actually playable today (just the slot machine for now); "Coming
/// Soon" previews the rest of the studio roadmap as locked tiles, so the
/// lobby reads as a growing collection from day one instead of needing a
/// second game to ship before the pattern makes sense.
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  void _showComingSoon(BuildContext context, String title) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameState game = ref.watch(gameProvider);
    final String playerName = ref.watch(playerNameProvider);
    final int dailyCompleted = ref.watch(dailyBonusSpinsCompletedProvider);
    final bool dailyClaimed = ref.watch(dailyBonusProvider).claimed;

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
          LobbyHeader(playerName: playerName, balance: game.balance, jackpot: game.jackpot),
          const SizedBox(height: AppSpacing.xl),
          PromoCarousel(
            slides: <Widget>[
              JackpotPromoSlide(
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
          const SectionHeader(title: 'Top Games', icon: Icons.local_fire_department_rounded),
          const SizedBox(height: AppSpacing.md),
          _GameRow(
            entries: LobbyCatalog.live,
            onLockedTap: (GameCatalogEntry e) => _showComingSoon(context, e.title),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Coming Soon', icon: Icons.upcoming_rounded),
          const SizedBox(height: AppSpacing.md),
          _GameRow(
            entries: LobbyCatalog.comingSoon,
            onLockedTap: (GameCatalogEntry e) => _showComingSoon(context, e.title),
          ),
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.entries, required this.onLockedTap});

  final List<GameCatalogEntry> entries;
  final ValueChanged<GameCatalogEntry> onLockedTap;

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
            onTap: entry.isLive ? () => context.pushNamed(entry.routeName!) : null,
            onLockedTap: () => onLockedTap(entry),
          );
        },
      ),
    );
  }
}
