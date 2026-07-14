import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';

/// Top-of-Home header: back-to-lobby button, player avatar + VIP badge,
/// balance/bet/jackpot readouts, and quick actions (settings,
/// notifications, wallet, profile). Wraps to a second row on narrow
/// phones so nothing clips.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.balance,
    required this.bet,
    required this.jackpot,
    required this.vipTier,
    this.notificationCount = 3,
    this.onBetDecrement,
    this.onBetIncrement,
    this.onBack,
    super.key,
  });

  final int balance;
  final int bet;
  final int jackpot;
  final int vipTier;
  final int notificationCount;
  final VoidCallback? onBetDecrement;
  final VoidCallback? onBetIncrement;

  /// Shown as a leading back button when the slot machine was pushed on
  /// top of the Lobby (its normal entry point) rather than hosted as a
  /// bottom-nav tab.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.isCompact;

    final Widget avatar = PressableScale(
      onTap: () => context.pushNamed(RouteNames.profile),
      child: const AvatarBadge(vipTier: 0, size: 48, showTierLabel: true),
    );

    final Widget? back = onBack == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Semantics(
              button: true,
              label: 'Back to lobby',
              child: IconActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
            ),
          );

    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconActionButton(
          icon: Icons.notifications_rounded,
          badgeCount: notificationCount,
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.sm),
        IconActionButton(
          icon: Icons.account_balance_wallet_rounded,
          onTap: () => context.pushNamed(RouteNames.wallet),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconActionButton(
          icon: Icons.settings_rounded,
          onTap: () => context.goNamed(RouteNames.settings),
        ),
      ],
    );

    final List<Widget> chips = <Widget>[
      HeaderInfoChip(
        label: 'Balance',
        value: balance,
        icon: Icons.monetization_on_rounded,
        accentColor: AppColors.gold,
      ),
      HeaderInfoChip(
        label: 'Bet',
        value: bet,
        accentColor: AppColors.neonPurpleLight,
        onDecrement: onBetDecrement,
        onIncrement: onBetIncrement,
      ),
      HeaderInfoChip(
        label: 'Jackpot',
        value: jackpot,
        icon: Icons.emoji_events_rounded,
        accentColor: AppColors.warning,
        highlight: true,
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ?back,
              avatar,
              const Spacer(),
              actions,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final Widget chip in chips) ...<Widget>[
                  chip,
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ?back,
        avatar,
        const SizedBox(width: AppSpacing.lg),
        for (final Widget chip in chips) ...<Widget>[
          chip,
          const SizedBox(width: AppSpacing.sm),
        ],
        const Spacer(),
        actions,
      ],
    );
  }
}
