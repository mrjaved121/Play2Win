import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/mission_definition.dart';
import '../providers/missions_providers.dart';
import '../widgets/mission_card.dart';

/// Missions tab: Daily Challenge + Weekly Challenge sections. Progress is
/// derived live from the player's actual [GameState] (spins played,
/// coins won, jackpots hit, …) via [missionViewsProvider] — not demo
/// data — and claiming credits real coins through [gameProvider].
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConstants.missionsEnabled) return const _MissionsComingSoon();

    final List<MissionProgressView> views = ref.watch(missionViewsProvider);
    final List<MissionProgressView> daily =
        views.where((MissionProgressView v) => v.definition.period == MissionPeriod.daily).toList();
    final List<MissionProgressView> weekly =
        views.where((MissionProgressView v) => v.definition.period == MissionPeriod.weekly).toList();

    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Text('Missions', style: AppTextStyles.displaySmall),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Daily Challenge', icon: Icons.today_rounded),
          const SizedBox(height: AppSpacing.md),
          for (final MissionProgressView mission in daily) ...<Widget>[
            MissionCard(
              mission: mission,
              onClaim: () => ref.read(missionsProgressProvider.notifier).claim(mission.definition.id),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Weekly Challenge', icon: Icons.calendar_month_rounded),
          const SizedBox(height: AppSpacing.md),
          for (final MissionProgressView mission in weekly) ...<Widget>[
            MissionCard(
              mission: mission,
              onClaim: () => ref.read(missionsProgressProvider.notifier).claim(mission.definition.id),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Shown instead of the real mission list while [AppConstants.missionsEnabled]
/// is off — the tab itself stays reachable (no bottom-nav restructuring)
/// but grants nothing.
class _MissionsComingSoon extends StatelessWidget {
  const _MissionsComingSoon();

  @override
  Widget build(BuildContext context) {
    return ScreenBackground(
      wrapInScaffold: false,
      bottom: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Missions', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Coming soon.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
