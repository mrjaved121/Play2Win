import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/crash_constants.dart';
import '../providers/crash_providers.dart';
import 'auto_cashout_row.dart';
import 'autoplay_control.dart';
import 'bet_input_field.dart';
import 'quick_bet_row.dart';

/// One independent bet panel: input+Autoplay on one row, quick-bet
/// grid+Place Bet on the next (matching the reference layout), or the
/// running/resolved primary action button in their place. [CrashScreen]
/// renders two of these, one per [CrashSlotId] — see `crash_providers.dart`
/// for how two panels can end up riding the same flight/crash-point.
class CrashBetPanel extends StatelessWidget {
  const CrashBetPanel({
    required this.state,
    required this.minBet,
    required this.maxBet,
    required this.onSetBet,
    required this.onPlaceBet,
    required this.onCollect,
    required this.onPlayAgain,
    required this.onEnableAutoplay,
    required this.onDisableAutoplay,
    required this.onSetAutoCashout,
    super.key,
  });

  final CrashSlotState state;

  /// Live admin-configured bet bounds (see [CrashSharedState.minBet]/`maxBet`)
  /// — not per-panel either, but threaded through explicitly (rather than
  /// read via `ref` here) since this widget is otherwise plain/stateless.
  final int minBet;
  final int maxBet;
  final ValueChanged<int> onSetBet;
  final VoidCallback onPlaceBet;
  final VoidCallback onCollect;
  final VoidCallback onPlayAgain;
  final AutoplayEnableCallback onEnableAutoplay;
  final VoidCallback onDisableAutoplay;
  final ValueChanged<double?> onSetAutoCashout;

  /// [CrashConstants.quickBetPresets] filtered to the live [minBet]/[maxBet]
  /// range, so a preset admin has since put out of range (e.g. lowering
  /// maxBet below it) never shows a chip the server would reject. Falls
  /// back to the bounds themselves if that empties the list out entirely.
  List<int> get _quickBetPresets {
    final List<int> inRange =
        CrashConstants.quickBetPresets.where((int p) => p >= minBet && p <= maxBet).toList();
    return inRange.isNotEmpty ? inRange : <int>[minBet, maxBet];
  }

  @override
  Widget build(BuildContext context) {
    if (state.phase != CrashPhase.idle) return _buildPrimaryButton();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: BetInputField(
                value: state.bet,
                minBet: minBet,
                onChanged: onSetBet,
                enabled: !state.autoplayEnabled,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AutoplayControl(
                enabled: state.autoplayEnabled,
                roundsRemaining: state.autoplayRoundsRemaining,
                onEnable: onEnableAutoplay,
                onDisable: onDisableAutoplay,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: QuickBetRow(
                  currentBet: state.bet,
                  presets: _quickBetPresets,
                  onSelect: onSetBet,
                  enabled: !state.autoplayEnabled,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _PlaceBetButton(state: state, onPressed: onPlaceBet)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AutoCashoutRow(current: state.autoCashoutMultiplier, onSelect: onSetAutoCashout),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    switch (state.phase) {
      case CrashPhase.idle:
        return const SizedBox.shrink(); // handled above
      case CrashPhase.running:
        return GradientButton(
          label: 'COLLECT',
          gradient: AppGradients.success,
          glowColor: AppColors.success,
          icon: Icons.pan_tool_alt_rounded,
          size: GradientButtonSize.large,
          onPressed: onCollect,
          loading: state.busy,
        ).animate(onPlay: (AnimationController c) => c.repeat(reverse: true)).scale(
              duration: 700.ms,
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.03, 1.03),
            );
      case CrashPhase.resolved:
        return GradientButton.secondary(
          label: 'PLAY AGAIN',
          icon: Icons.replay_rounded,
          size: GradientButtonSize.large,
          onPressed: onPlayAgain,
        );
    }
  }
}

/// Custom (not [GradientButton]) so it can stretch to match the quick-bet
/// grid's natural 2-row height via [IntrinsicHeight] instead of a fixed
/// size preset.
class _PlaceBetButton extends StatelessWidget {
  const _PlaceBetButton({required this.state, required this.onPressed});

  final CrashSlotState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Always tappable while not busy — even when unaffordable — so
    // [onPressed] (see CrashScreen._panelFor) can show the Out of Credits
    // sheet instead of the tap silently doing nothing.
    final bool enabled = !state.busy;
    return Opacity(
      opacity: enabled || state.busy ? 1 : 0.45,
      child: PressableScale(
        onTap: enabled ? onPressed : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: enabled ? AppShadows.button(AppColors.gold) : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: state.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textOnGold),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.rocket_launch_rounded, size: 18, color: AppColors.textOnGold),
                      Text(
                        'PLACE BET',
                        style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnGold),
                      ),
                      Text(
                        '${state.bet} PKR',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnGold.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
