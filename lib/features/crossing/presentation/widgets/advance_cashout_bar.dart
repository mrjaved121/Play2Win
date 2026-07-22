import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/crossing_round.dart';

/// Bottom action row while a round is running: current multiplier/potential
/// payout readout, a "NEXT LANE" advance button, and a "CASH OUT" button
/// (only enabled once at least one lane has been cleared).
class AdvanceCashoutBar extends StatelessWidget {
  const AdvanceCashoutBar({
    required this.round,
    required this.busy,
    required this.onAdvance,
    required this.onCashout,
    super.key,
  });

  final CrossingRound round;
  final bool busy;
  final VoidCallback onAdvance;
  final VoidCallback onCashout;

  @override
  Widget build(BuildContext context) {
    final double multiplier = round.currentMultiplier;
    final int potentialWin = (round.betAmount * multiplier).floor();

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('LANE ${round.currentLane} / ${round.laneCount}', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      '${multiplier.toStringAsFixed(2)}x',
                      style: AppTextStyles.titleLarge.copyWith(color: AppColors.gold),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('= $potentialWin CR', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 96,
            child: GradientButton.success(
              label: 'CASH OUT',
              size: GradientButtonSize.small,
              onPressed: round.canCashOut && !busy ? onCashout : null,
              enabled: round.canCashOut && !busy,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 112,
            child: GradientButton.primary(
              label: 'NEXT LANE',
              icon: Icons.arrow_forward_rounded,
              onPressed: !busy ? onAdvance : null,
              enabled: !busy,
              loading: busy,
            ),
          ),
        ],
      ),
    );
  }
}
