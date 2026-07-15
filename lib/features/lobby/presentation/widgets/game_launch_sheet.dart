import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/game_catalog_entry.dart';
import '../providers/favorites_providers.dart';
import '../providers/recently_played_providers.dart';

/// Preview modal shown before entering a live game — thumbnail, studio
/// row and favorite toggle, large Play CTA — mirroring LUNA-BET's game
/// launch sheet. Records the play in [recentlyPlayedProvider] before
/// pushing [GameCatalogEntry.routeName].
Future<void> showGameLaunchSheet(BuildContext context, GameCatalogEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final bool isFavorite = ref.watch(favoritesProvider).contains(entry.id);
        return _GameLaunchSheetContent(
          entry: entry,
          isFavorite: isFavorite,
          onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggle(entry.id),
          onPlay: () {
            Navigator.of(context).pop();
            ref.read(recentlyPlayedProvider.notifier).recordPlayed(entry.id);
            context.pushNamed(entry.routeName!);
          },
        );
      },
    ),
  );
}

class _GameLaunchSheetContent extends StatelessWidget {
  const _GameLaunchSheetContent({
    required this.entry,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onPlay,
  });

  final GameCatalogEntry entry;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: AppRadius.radiusPill,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[entry.accentColor, entry.accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: entry.accentColor),
                ),
                child: Icon(entry.icon, size: 36, color: AppColors.textOnGold),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(entry.title, style: AppTextStyles.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.storefront_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${AppConstants.appName} Studio',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PressableScale(
                onTap: onToggleFavorite,
                playClickSound: false,
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.neonPurple : AppColors.textMuted,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton.primary(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            size: GradientButtonSize.large,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
