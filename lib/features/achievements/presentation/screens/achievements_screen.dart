import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/achievements_providers.dart';
import '../widgets/achievement_badge.dart';

/// Achievements screen: a responsive grid of unlockable badges, all
/// derived live from the player's real [GameState] via
/// [achievementViewsProvider].
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int columns = context.isExpanded ? 5 : (context.isTablet ? 4 : 2);
    final List<AchievementView> achievements = ref.watch(achievementViewsProvider);

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Achievements'),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.05,
              ),
              itemCount: achievements.length,
              itemBuilder: (BuildContext context, int index) {
                return AchievementBadge(achievement: achievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
