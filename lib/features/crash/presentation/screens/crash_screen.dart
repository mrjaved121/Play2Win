import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/crash_providers.dart';
import '../widgets/crash_bet_panel.dart';
import '../widgets/crash_header.dart';
import '../widgets/crash_top_actions.dart';
import '../widgets/live_leaderboard.dart';
import '../widgets/multiplier_stage.dart';
import '../widgets/platform_stats_bar.dart';

/// Multiplier Climb: two independent bet panels can each place a bet, and
/// if both are placed while the same flight is still climbing, the server
/// makes them share one crash point (see blackhole_admin's
/// `findJoinableRound`) — hedging with two different cash-out strategies
/// on the same rocket, exactly like the reference design. Neither panel
/// computes a result itself; each only ever renders its own
/// [CrashSlotNotifier]'s state, which in turn only ever reflects what
/// blackhole_admin's API returned.
///
/// Layout mirrors the reference Aviator-style design (top T&C/History
/// buttons, one shared graph, two bet panels, a persistent platform-wide
/// stats bar, and a persistent live player list) while keeping this app's
/// own Midnight & Gold Marquee color scheme rather than the reference's
/// blue/orange one.
class CrashScreen extends ConsumerWidget {
  const CrashScreen({super.key});

  /// Whichever panel is "the current flight" for the shared graph/live
  /// list: prefer whichever isn't idle; if both are mid-flight they're
  /// numerically identical anyway (same shared crash point), so it doesn't
  /// matter which is picked.
  CrashSlotState _activeSlot(CrashSlotState slot1, CrashSlotState slot2) {
    if (slot1.phase != CrashPhase.idle) return slot1;
    if (slot2.phase != CrashPhase.idle) return slot2;
    return slot1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ApiConfig.isConfigured) {
      return ScreenBackground(
        child: GameServerNotConfigured(gameName: 'Multiplier Climb', onBack: () => context.pop()),
      );
    }

    final CrashSharedState shared = ref.watch(crashSharedProvider);
    final CrashSlotState slot1 = ref.watch(crashSlotProvider(CrashSlotId.slot1));
    final CrashSlotState slot2 = ref.watch(crashSlotProvider(CrashSlotId.slot2));
    final CrashSlotState active = _activeSlot(slot1, slot2);

    return ScreenBackground(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: CrashHeader(
              balance: shared.balance,
              balanceLoading: shared.balanceLoading,
              onBack: () => context.pop(),
            ),
          ),
          if (slot1.errorMessage != null || slot2.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: _ErrorBanner(message: (slot1.errorMessage ?? slot2.errorMessage)!),
            ),
          Expanded(
            // Two full bet panels take real, non-negotiable vertical space
            // (~170px each) — on shorter screens there just isn't room left
            // for a flex-sized graph/list too, so this scrolls as a whole
            // rather than fighting for space via flex ratios. The graph and
            // live list get fixed heights (instead of Expanded/flex) so
            // they still read as generously sized on tall screens without
            // ever being the thing that overflows on short ones.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  CrashTopActions(state: shared),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(height: 240, child: MultiplierStage(state: active)),
                  const SizedBox(height: AppSpacing.sm),
                  _panelFor(ref, CrashSlotId.slot1, slot1, shared),
                  const SizedBox(height: AppSpacing.sm),
                  _panelFor(ref, CrashSlotId.slot2, slot2, shared),
                  const SizedBox(height: AppSpacing.sm),
                  const PlatformStatsBar(),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 220,
                    child: PremiumCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: LiveLeaderboard(activeSlot: active),
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

  Widget _panelFor(WidgetRef ref, CrashSlotId id, CrashSlotState state, CrashSharedState shared) {
    final CrashSlotNotifier notifier = ref.read(crashSlotProvider(id).notifier);
    return CrashBetPanel(
      state: state,
      balance: shared.balance,
      minBet: shared.minBet,
      maxBet: shared.maxBet,
      onSetBet: notifier.setBet,
      onPlaceBet: notifier.placeBet,
      onCollect: notifier.collect,
      onPlayAgain: notifier.startNewRound,
      onSetAutoCashout: notifier.setAutoCashout,
      onEnableAutoplay: ({int? maxRounds, int? stopOnProfit, int? stopOnLoss}) => notifier.setAutoplay(
        enabled: true,
        maxRounds: maxRounds,
        stopOnProfit: stopOnProfit,
        stopOnLoss: stopOnLoss,
      ),
      onDisableAutoplay: () => notifier.setAutoplay(enabled: false),
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
