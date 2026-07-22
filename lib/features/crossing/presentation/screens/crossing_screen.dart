import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/crossing_round.dart';
import '../providers/crossing_providers.dart';
import '../widgets/advance_cashout_bar.dart';
import '../widgets/crossing_bet_stepper.dart';
import '../widgets/crossing_header.dart';
import '../widgets/crossing_history_modal.dart';
import '../widgets/crossing_lane_board.dart';
import '../widgets/crossing_menu_sheet.dart';
import '../widgets/difficulty_selector.dart';

/// Multiplier Crossing: bet, pick a difficulty (sets the board's lane
/// count/risk), then advance one lane at a time — each lane's outcome is
/// revealed by the server one call at a time (see `crossing_providers.dart`
/// for why there's no client-side prediction of future lanes) — cashing
/// out anytime after the first lane, or losing the bet on a bust.
class CrossingScreen extends ConsumerWidget {
  const CrossingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ApiConfig.isConfigured) {
      return ScreenBackground(
        child: GameServerNotConfigured(gameName: 'Multiplier Crossing', onBack: () => context.pop()),
      );
    }

    final CrossingSharedState shared = ref.watch(crossingSharedProvider);
    final CrossingGameState game = ref.watch(crossingGameProvider);
    final CrossingGameNotifier notifier = ref.read(crossingGameProvider.notifier);
    final CrossingRound? round = game.round;

    final int laneCount = round?.laneCount ?? shared.difficulties[game.difficulty]?.laneCount ?? 1;
    final List<double> ladder = round?.ladder ?? shared.difficulties[game.difficulty]?.ladder ?? const <double>[];

    return ScreenBackground(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: CrossingHeader(
              balance: shared.balance,
              balanceLoading: shared.balanceLoading,
              onBack: () => context.pop(),
              onMenu: () => showCrossingMenuSheet(context, shared),
            ),
          ),
          if (game.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: _ErrorBanner(message: game.errorMessage!),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: CrossingLaneBoard.boardHeight + 32,
                    child: CrossingLaneBoard(
                      laneCount: laneCount,
                      ladder: ladder,
                      currentLane: round?.currentLane ?? 0,
                      busted: round?.status == CrossingRoundStatus.busted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (game.phase == CrossingPhase.running && round != null)
                    AdvanceCashoutBar(
                      round: round,
                      busy: game.busy,
                      onAdvance: notifier.advance,
                      onCashout: notifier.cashout,
                    )
                  else if (game.phase == CrossingPhase.resolved && round != null)
                    _ResolvedPanel(round: round, onPlayAgain: notifier.startNewRound)
                  else
                    _IdlePanel(shared: shared, game: game, notifier: notifier),
                  const SizedBox(height: AppSpacing.md),
                  _SessionStrip(shared: shared),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({required this.shared, required this.game, required this.notifier});

  final CrossingSharedState shared;
  final CrossingGameState game;
  final CrossingGameNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final List<int> presets = shared.difficulties.isEmpty
        ? const <int>[20, 50, 100, 250, 500]
        : <int>[20, 50, 100, 250, 500].where((int p) => p >= shared.minBet && p <= shared.maxBet).toList();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('DIFFICULTY', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          DifficultySelector(
            selected: game.difficulty,
            difficulties: shared.difficulties,
            onSelect: notifier.setDifficulty,
            enabled: !game.busy,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('BET AMOUNT', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          CrossingBetInputField(
            value: game.bet,
            minBet: shared.minBet,
            onChanged: notifier.setBet,
            enabled: !game.busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          CrossingQuickBetRow(
            currentBet: game.bet,
            presets: presets.isEmpty ? <int>[shared.minBet] : presets,
            onSelect: notifier.setBet,
            enabled: !game.busy,
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton.primary(
            label: 'PLAY',
            icon: Icons.play_arrow_rounded,
            size: GradientButtonSize.large,
            loading: game.busy,
            enabled: game.canAfford(shared.balance),
            onPressed: notifier.placeBet,
          ),
        ],
      ),
    );
  }
}

class _ResolvedPanel extends StatelessWidget {
  const _ResolvedPanel({required this.round, required this.onPlayAgain});

  final CrossingRound round;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final bool won = round.status == CrossingRoundStatus.collected;
    final Color color = won ? AppColors.success : AppColors.error;
    return PremiumCard(
      glow: AppShadows.glow(color, intensity: 0.5),
      child: Column(
        children: <Widget>[
          Icon(won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, color: color, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            won ? 'CASHED OUT +${round.payout ?? 0} CR' : 'BUSTED — LOST ${round.betAmount} CR',
            style: AppTextStyles.titleMedium.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton.primary(label: 'PLAY AGAIN', icon: Icons.refresh_rounded, onPressed: onPlayAgain),
        ],
      ),
    );
  }
}

class _SessionStrip extends StatelessWidget {
  const _SessionStrip({required this.shared});

  final CrossingSharedState shared;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: PressableScale(
            onTap: () => showCrossingHistoryModal(context, shared),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.radiusMd,
                boxShadow: AppShadows.button(AppColors.gold),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.textOnGold),
                  const SizedBox(width: AppSpacing.xs),
                  Text('HISTORY', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnGold)),
                ],
              ),
            ),
          ),
        ),
      ],
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
