import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';

/// Hosts the 5 bottom-navigation tabs (Home, Store, Leaderboard, Missions,
/// Settings) inside a single [StatefulNavigationShell] so each tab keeps
/// its own navigation stack and scroll position when switching away and
/// back. Wired up by [GoRouter]'s `StatefulShellRoute.indexedStack` in
/// `app_router.dart`.
class AppShellScreen extends StatelessWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<(IconData, String)> _tabs = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),
    (Icons.storefront_rounded, 'Store'),
    (Icons.leaderboard_rounded, 'Leaderboard'),
    (Icons.emoji_events_rounded, 'Missions'),
    (Icons.settings_rounded, 'Settings'),
  ];

  static const double _barHeight = 68;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.backgroundElevated,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
          boxShadow: AppShadows.cardElevated,
        ),
        child: SafeArea(
          child: SizedBox(
            height: _barHeight,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavTab(
                      icon: _tabs[i].$1,
                      label: _tabs[i].$2,
                      selected: navigationShell.currentIndex == i,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.gold : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox.expand(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyles.label.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: AppConstants.animFast,
                width: selected ? 4 : 0,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
