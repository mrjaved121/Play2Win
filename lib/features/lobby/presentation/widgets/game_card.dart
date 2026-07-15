import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/game_catalog_entry.dart';

/// One tile in a lobby game rail. Live games get a full-color icon tile,
/// their [GameCatalogEntry.badgeLabel] and a tap target that opens the
/// game; coming-soon games render muted with a lock badge and, on tap,
/// give a "Coming soon" acknowledgement rather than a dead, silent tap —
/// makes it obvious the app noticed you tapped instead of feeling broken.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.entry,
    this.onTap,
    this.onLockedTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    super.key,
  });

  final GameCatalogEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  /// Whether [entry] is in the player's favorites. Only live games can be
  /// favorited — [onToggleFavorite] is null for locked tiles.
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  static const double width = 136;

  @override
  Widget build(BuildContext context) {
    final bool live = entry.isLive;

    return Semantics(
      button: true,
      label: live ? '${entry.title}, play now' : '${entry.title}, coming soon',
      child: SizedBox(
        width: width,
        child: PremiumCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderColor: live ? entry.accentColor.withValues(alpha: 0.6) : AppColors.cardBorder,
          glow: live ? AppShadows.glow(entry.accentColor, intensity: 0.5) : AppShadows.card,
          onTap: live ? onTap : onLockedTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (live && onToggleFavorite != null)
                    PressableScale(
                      onTap: onToggleFavorite,
                      playClickSound: false,
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFavorite ? AppColors.neonPurple : AppColors.textMuted,
                      ),
                    ),
                  const Spacer(),
                  live
                      ? BadgePill(label: entry.badgeLabel ?? 'PLAY', color: entry.accentColor, filled: true)
                      : const BadgePill(label: 'SOON', icon: Icons.lock_rounded, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: live
                        ? LinearGradient(
                            colors: <Color>[
                              entry.accentColor,
                              entry.accentColor.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    color: live ? null : AppColors.cardPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: live ? entry.accentColor : AppColors.cardBorder),
                  ),
                  child: Icon(
                    entry.icon,
                    size: 28,
                    color: live ? AppColors.textOnGold : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: live ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
