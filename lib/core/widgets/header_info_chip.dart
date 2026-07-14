import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'animated_counter_text.dart';
import 'pressable_scale.dart';

/// The pill-shaped stat readouts in the home header: BALANCE, BET,
/// JACKPOT. Optionally renders a leading label, a leading icon and a
/// trailing +/- stepper (used for the bet chip).
class HeaderInfoChip extends StatelessWidget {
  const HeaderInfoChip({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor = AppColors.gold,
    this.onDecrement,
    this.onIncrement,
    this.animateValue = true,
    this.highlight = false,
    super.key,
  });

  final String label;
  final int value;
  final IconData? icon;
  final Color accentColor;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool animateValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: highlight ? accentColor : AppColors.cardBorder,
        ),
        boxShadow: highlight ? AppShadows.glow(accentColor, intensity: 0.6) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (onDecrement != null) _StepperButton(icon: Icons.remove, onTap: onDecrement!),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: onDecrement != null ? AppSpacing.sm : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label.toUpperCase(), style: AppTextStyles.label),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 14, color: accentColor),
                      const SizedBox(width: 3),
                    ],
                    animateValue
                        ? AnimatedCounterText(
                            value: value,
                            style: AppTextStyles.counter.copyWith(fontSize: 16),
                          )
                        : Text(
                            '$value',
                            style: AppTextStyles.counter.copyWith(fontSize: 16),
                          ),
                  ],
                ),
              ],
            ),
          ),
          if (onIncrement != null) _StepperButton(icon: Icons.add, onTap: onIncrement!),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.neonPurple,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: AppColors.textPrimary),
      ),
    );
  }
}
