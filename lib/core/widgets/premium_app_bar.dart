import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import 'icon_action_button.dart';

/// Back button + centered title + optional trailing action, styled to
/// match the rest of the header chrome. Used by pushed (non-bottom-nav)
/// screens: Profile, Wallet, Rewards, Achievements.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            IconActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 40,
              onTap: () => context.pop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
            ),
            SizedBox(width: 40, child: trailing),
          ],
        ),
      ),
    );
  }
}
