import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../achievements/presentation/providers/achievements_providers.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../slot/domain/entities/game_state.dart';
import '../../../slot/presentation/providers/game_providers.dart';

/// Profile screen: avatar + VIP tier, a level/XP progress derived from
/// lifetime spins, a real statistics grid and an achievements preview
/// strip — all sourced from [gameProvider] / [achievementViewsProvider].
///
/// The display name is the real Guest Mode nickname from onboarding
/// ([playerNameProvider]), editable here — there's still no authenticated
/// account system (see [[project-backend-architecture]]), just a local
/// nickname.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Every 20 spins is one level — a simple, real progression derived
  /// from lifetime play rather than a separate XP system.
  static const int _spinsPerLevel = 20;

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final TextEditingController controller = TextEditingController(text: current);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cardPurple,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        title: Text('Edit Nickname', style: AppTextStyles.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Save', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      ref.read(playerNameProvider.notifier).setName(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameState game = ref.watch(gameProvider);
    final List<AchievementView> achievements = ref.watch(achievementViewsProvider);
    final String playerName = ref.watch(playerNameProvider);
    final AppAuthUser? authedUser = ref.watch(authStateProvider).value;

    final int level = (game.totalSpins ~/ _spinsPerLevel) + 1;
    final int xp = game.totalSpins % _spinsPerLevel;
    final double winRate = game.totalSpins == 0 ? 0 : game.totalWins / game.totalSpins;

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      const AvatarBadge(size: 92, vipTier: 3, showTierLabel: true),
                      const SizedBox(height: AppSpacing.md),
                      PressableScale(
                        onTap: () => _editName(context, ref, playerName),
                        playClickSound: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(playerName, style: AppTextStyles.headlineLarge),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.edit_rounded, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (authedUser == null)
                  PremiumCard(
                    onTap: () => context.pushNamed(RouteNames.login),
                    borderColor: AppColors.gold,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.cloud_upload_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text('Sign in to sync progress', style: AppTextStyles.titleSmall),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Signed in as ${authedUser.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.xl),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text('Level $level', style: AppTextStyles.titleLarge),
                          const Spacer(),
                          Text('$xp / $_spinsPerLevel spins', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GradientProgressBar(progress: xp / _spinsPerLevel, gradient: AppGradients.gold),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Statistics', icon: Icons.bar_chart_rounded),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.8,
                  children: <Widget>[
                    StatTile(label: 'Total Spins', value: game.totalSpins.asGrouped, icon: Icons.casino_rounded),
                    StatTile(
                      label: 'Biggest Win',
                      value: game.bestWinToday.asGrouped,
                      icon: Icons.emoji_events_rounded,
                    ),
                    StatTile(
                      label: 'Jackpots Won',
                      value: '${game.jackpotsWon}',
                      icon: Icons.workspace_premium_rounded,
                    ),
                    StatTile(
                      label: 'Win Rate',
                      value: '${(winRate * 100).toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(
                  title: 'Achievements',
                  icon: Icons.military_tech_rounded,
                  trailing: TextButton(
                    onPressed: () => context.pushNamed(RouteNames.achievements),
                    child: Text('See All', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: achievements.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (BuildContext context, int index) {
                      final bool unlocked = achievements[index].unlocked;
                      return Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: unlocked ? AppGradients.gold : null,
                          color: unlocked ? null : AppColors.cardPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: unlocked ? AppColors.goldLight : AppColors.cardBorder,
                          ),
                          boxShadow: unlocked ? AppShadows.goldGlow : null,
                        ),
                        child: Icon(
                          achievements[index].definition.icon,
                          color: unlocked ? AppColors.textOnGold : AppColors.textMuted,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
