import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/support_entry.dart';
import '../providers/support_providers.dart';

/// Where every "Buy" CTA in the Store leads instead of a real purchase —
/// this app has no payment integration, so tapping Buy explains that
/// plainly rather than silently failing or showing a bare "coming soon"
/// toast. The FAQ-style entries below the disclaimer are admin-managed
/// content (blackhole_admin's Help & Support page), so support copy can
/// change without an app release.
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportUiState state = ref.watch(supportProvider);

    return ScreenBackground(
      child: Column(
        children: <Widget>[
          const PremiumAppBar(title: 'Help & Support'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => ref.read(supportProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                children: <Widget>[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.info_rounded, color: AppColors.gold, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text('This is a demo', style: AppTextStyles.titleLarge),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Project Blackhole is a non-commercial demo. Coins have no '
                          'real-world value and nothing here can be bought with real '
                          'money — every game runs on simulated, restricted play, not '
                          'real-money gambling.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumCard(
                    onTap: () => context.pushNamed(RouteNames.howToBuy),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.account_balance_wallet_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text('How to Buy Credits', style: AppTextStyles.titleSmall),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Help & Support', icon: Icons.help_rounded),
                  const SizedBox(height: AppSpacing.md),
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                    )
                  else if (state.errorMessage != null)
                    GlassCard(child: Text(state.errorMessage!, style: AppTextStyles.bodyMedium))
                  else if (state.entries.isEmpty)
                    GlassCard(
                      child: Text(
                        'No additional help topics right now — check back soon.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  else
                    ...state.entries.map(
                      (SupportEntry entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(entry.title, style: AppTextStyles.titleSmall),
                              const SizedBox(height: AppSpacing.xs),
                              Text(entry.content, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
