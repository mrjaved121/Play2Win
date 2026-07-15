import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Top of the Lobby: player avatar + greeting, a persistent search action,
/// balance/jackpot readouts and a quick "add coins" shortcut into the
/// Store. Mirrors [HomeHeader]'s visual language so switching between the
/// lobby and the slot machine doesn't feel like a different app.
class LobbyHeader extends StatelessWidget {
  const LobbyHeader({
    required this.playerName,
    required this.balance,
    required this.jackpot,
    this.onSearchTap,
    super.key,
  });

  final String playerName;
  final int balance;
  final int jackpot;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            PressableScale(
              onTap: () => context.pushNamed(RouteNames.profile),
              child: const AvatarBadge(vipTier: 0, size: 44),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Welcome back', style: AppTextStyles.bodySmall),
                  Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge,
                  ),
                ],
              ),
            ),
            IconActionButton(icon: Icons.search_rounded, onTap: onSearchTap),
            const SizedBox(width: AppSpacing.sm),
            IconActionButton(
              icon: Icons.settings_rounded,
              onTap: () => context.goNamed(RouteNames.settings),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            HeaderInfoChip(
              label: 'Balance',
              value: balance,
              icon: Icons.monetization_on_rounded,
              accentColor: AppColors.gold,
            ),
            const SizedBox(width: AppSpacing.sm),
            HeaderInfoChip(
              label: 'Jackpot',
              value: jackpot,
              icon: Icons.emoji_events_rounded,
              accentColor: AppColors.warning,
              highlight: true,
            ),
            const Spacer(),
            PressableScale(
              onTap: () => context.goNamed(RouteNames.store),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.goldGlow,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.textOnGold, size: 26),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
