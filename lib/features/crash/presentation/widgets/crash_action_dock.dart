import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/crash_providers.dart';

/// Bottom dock: bet stepper + the primary action button, whose label and
/// behavior swap with [CrashUiState.phase] (bet -> collect -> play again).
class CrashActionDock extends StatelessWidget {
  const CrashActionDock({
    required this.state,
    required this.onAdjustBet,
    required this.onPlaceBet,
    required this.onCollect,
    required this.onPlayAgain,
    super.key,
  });

  final CrashUiState state;
  final ValueChanged<int> onAdjustBet;
  final VoidCallback onPlaceBet;
  final VoidCallback onCollect;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (state.phase == CrashPhase.idle) ...<Widget>[
              Row(
                children: <Widget>[
                  HeaderInfoChip(
                    label: 'Bet',
                    value: state.bet,
                    accentColor: AppColors.neonPurpleLight,
                    onDecrement: () => onAdjustBet(-1),
                    onIncrement: () => onAdjustBet(1),
                  ),
                  const Spacer(),
                  if (state.balance != null)
                    Text('Balance: ${state.balance} CR', style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildPrimaryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    switch (state.phase) {
      case CrashPhase.idle:
        return GradientButton.primary(
          label: 'PLACE BET',
          subtitle: '${state.bet} CR',
          icon: Icons.rocket_launch_rounded,
          size: GradientButtonSize.large,
          onPressed: state.canAffordBet ? onPlaceBet : null,
          loading: state.busy,
          enabled: state.canAffordBet,
        );
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
