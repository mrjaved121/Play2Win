import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/daily_bonus_providers.dart';
import '../widgets/spin_progress_strip.dart';

/// Rewards / Daily Bonus screen: gift box hero, spin progress, claim CTA
/// with a reward-reveal micro-animation, and a reset countdown once
/// today's bonus has been claimed.
///
/// Backed by [dailyBonusProvider] / [dailyBonusSpinsCompletedProvider] —
/// progress is real spins played today, not demo data.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int spinsCompleted = ref.watch(dailyBonusSpinsCompletedProvider);
    final bool claimed = ref.watch(dailyBonusProvider).claimed;
    final bool ready = spinsCompleted >= AppConstants.dailyBonusRequiredSpins && !claimed;

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Daily Rewards'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
              children: <Widget>[
                Center(
                  child: const Text('🎁', style: TextStyle(fontSize: 80))
                      .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -10, duration: 1200.ms, curve: Curves.easeInOut),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  claimed ? 'Come back tomorrow!' : 'Daily Login Reward',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  claimed
                      ? 'You’ve claimed today’s bonus.'
                      : 'Spin ${AppConstants.dailyBonusRequiredSpins} times to unlock your reward',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                SpinProgressStrip(
                  completed: spinsCompleted,
                  total: AppConstants.dailyBonusRequiredSpins,
                ),
                const SizedBox(height: AppSpacing.xl),
                PremiumCard(
                  borderColor: ready ? AppColors.gold : AppColors.cardBorder,
                  glow: ready ? AppShadows.goldGlow : AppShadows.card,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: <Widget>[
                      Text('TODAY’S REWARD', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 28),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${AppConstants.dailyBonusReward}',
                            style: AppTextStyles.displayJackpot,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (claimed)
                        CountdownText(
                          duration: AppConstants.dailyBonusResetPeriod,
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                        )
                      else
                        GradientButton.success(
                          label: 'CLAIM',
                          icon: Icons.card_giftcard_rounded,
                          onPressed: ready ? () => ref.read(dailyBonusProvider.notifier).claim() : null,
                        ),
                    ],
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
