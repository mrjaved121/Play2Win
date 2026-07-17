import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/crash_providers.dart';
import '../widgets/crash_action_dock.dart';
import '../widgets/crash_header.dart';
import '../widgets/multiplier_stage.dart';
import '../widgets/round_history_strip.dart';

/// Multiplier Climb: place a bet, watch the multiplier climb, tap Collect
/// before it crashes. Unlike the slot machine, this screen never computes
/// a result itself — it only renders [CrashGameNotifier]'s state, which
/// in turn only ever reflects what blackhole_admin's API returned.
class CrashScreen extends ConsumerWidget {
  const CrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ApiConfig.isConfigured) {
      return ScreenBackground(
        child: GameServerNotConfigured(gameName: 'Multiplier Climb', onBack: () => context.pop()),
      );
    }

    final CrashUiState state = ref.watch(crashGameProvider);
    final CrashGameNotifier notifier = ref.read(crashGameProvider.notifier);

    return ScreenBackground(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: CrashHeader(
              balance: state.balance,
              balanceLoading: state.balanceLoading,
              onBack: () => context.pop(),
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: _ErrorBanner(message: state.errorMessage!),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  Expanded(child: MultiplierStage(state: state)),
                  const SizedBox(height: AppSpacing.md),
                  RoundHistoryStrip(history: state.history),
                ],
              ),
            ),
          ),
          CrashActionDock(
            state: state,
            onAdjustBet: notifier.adjustBet,
            onPlaceBet: notifier.placeBet,
            onCollect: notifier.collect,
            onPlayAgain: notifier.startNewRound,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error))),
        ],
      ),
    );
  }
}
