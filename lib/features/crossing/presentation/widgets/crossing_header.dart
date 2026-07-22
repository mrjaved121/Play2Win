import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Top-of-screen bar: back button, title, balance chip, and a hamburger
/// menu button — mirrors [CrashHeader]'s layout, with the reference UI's
/// menu icon added on the trailing edge (Sound/Music, Provably fair
/// settings, Game rules, My bet history, How to play all live in the menu
/// sheet it opens — see `crossing_menu_sheet.dart`).
class CrossingHeader extends StatelessWidget {
  const CrossingHeader({
    required this.balance,
    required this.balanceLoading,
    required this.onBack,
    required this.onMenu,
    super.key,
  });

  final int? balance;
  final bool balanceLoading;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Back to lobby',
          child: IconActionButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Multiplier Crossing', style: AppTextStyles.titleLarge),
              Text('Server Credits', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        HeaderInfoChip(
          label: 'Balance',
          value: balance ?? 0,
          icon: Icons.dns_rounded,
          accentColor: AppColors.gold,
          animateValue: !balanceLoading,
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Menu',
          child: IconActionButton(icon: Icons.menu_rounded, onTap: onMenu),
        ),
      ],
    );
  }
}
