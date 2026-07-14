import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';

/// The bottom action bar: sound toggle, total-bet stepper, the big SPIN
/// button and a Turbo toggle.
///
/// While an auto-spin run is active ([autoSpinActive]), the SPIN button
/// becomes a STOP button (per the spec's "Stop Button" control) — tapping
/// it cancels the run via [onStopAutoSpin] instead of starting a spin.
class SpinBar extends StatelessWidget {
  const SpinBar({
    required this.totalBet,
    required this.spinning,
    this.soundOn = true,
    this.turboOn = false,
    this.autoSpinActive = false,
    this.autoSpinRemaining,
    this.onSpin,
    this.onStopAutoSpin,
    this.onBetDecrement,
    this.onBetIncrement,
    this.onSoundToggle,
    this.onTurboToggle,
    super.key,
  });

  final int totalBet;
  final bool spinning;
  final bool soundOn;
  final bool turboOn;
  final bool autoSpinActive;
  final int? autoSpinRemaining;
  final VoidCallback? onSpin;
  final VoidCallback? onStopAutoSpin;
  final VoidCallback? onBetDecrement;
  final VoidCallback? onBetIncrement;
  final VoidCallback? onSoundToggle;
  final ValueChanged<bool>? onTurboToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _RoundIconToggle(
          icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: 'Sound',
          active: soundOn,
          onTap: onSoundToggle,
        ),
        const SizedBox(width: AppSpacing.md),
        _BetStepper(
          totalBet: totalBet,
          onDecrement: onBetDecrement,
          onIncrement: onBetIncrement,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: autoSpinActive
              ? GradientButton(
                  label: 'STOP',
                  subtitle: autoSpinRemaining != null ? '$autoSpinRemaining SPINS LEFT' : null,
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.error, Color(0xFF7A1420)],
                  ),
                  glowColor: AppColors.error,
                  size: GradientButtonSize.large,
                  onPressed: onStopAutoSpin,
                )
              : GradientButton.primary(
                  label: spinning ? 'SPINNING…' : 'SPIN',
                  subtitle: spinning ? null : 'HOLD FOR AUTO SPIN',
                  size: GradientButtonSize.large,
                  loading: spinning,
                  onPressed: onSpin,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        _RoundIconToggle(
          icon: Icons.flash_on_rounded,
          label: 'Turbo',
          active: turboOn,
          onTap: onTurboToggle == null ? null : () => onTurboToggle!(!turboOn),
        ),
      ],
    );
  }
}

class _BetStepper extends StatelessWidget {
  const _BetStepper({
    required this.totalBet,
    this.onDecrement,
    this.onIncrement,
  });

  final int totalBet;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('TOTAL BET', style: AppTextStyles.label.copyWith(fontSize: 9)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _StepIcon(icon: Icons.remove, onTap: onDecrement),
              SizedBox(
                width: 44,
                child: Text(
                  '$totalBet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              _StepIcon(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Icon(
        icon,
        size: 18,
        color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
      ),
    );
  }
}

class _RoundIconToggle extends StatelessWidget {
  const _RoundIconToggle({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active ? AppGradients.neonPurple : AppGradients.glass,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.neonPurpleLight : AppColors.glassBorder,
              ),
              boxShadow: active ? AppShadows.purpleGlow : null,
            ),
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 8)),
        ],
      ),
    );
  }
}
