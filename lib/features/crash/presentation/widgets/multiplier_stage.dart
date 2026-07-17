import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/crash_round.dart';
import '../providers/crash_providers.dart';
import 'crash_curve_painter.dart';

/// The centerpiece: the climb curve, the big multiplier readout, and
/// (once resolved) the win/crash result banner.
class MultiplierStage extends StatelessWidget {
  const MultiplierStage({required this.state, super.key});

  final CrashUiState state;

  static const double _visualCap = 30;

  Color get _color {
    if (state.phase == CrashPhase.resolved) {
      return state.round?.status == CrashRoundStatus.collected ? AppColors.success : AppColors.error;
    }
    return AppColors.gold;
  }

  double get _multiplierToShow {
    if (state.phase == CrashPhase.resolved) {
      return state.round?.resolvedMultiplier ?? state.round?.crashPoint ?? state.displayMultiplier;
    }
    return state.displayMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    final double capped = _multiplierToShow.clamp(1.0, _visualCap);
    final double progress = (math.log(capped) / math.log(_visualCap)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: CrashCurvePainter(progress: progress, color: _color)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${_multiplierToShow.toStringAsFixed(2)}x',
                  style: AppTextStyles.displayJackpot.copyWith(fontSize: 56, color: _color),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusLine(state: state),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final CrashUiState state;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case CrashPhase.idle:
        return Text('Place a bet to start climbing', style: AppTextStyles.bodyMedium);
      case CrashPhase.running:
        final int potential = (state.bet * state.displayMultiplier).round();
        return Text(
          'Potential payout: $potential CR',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        );
      case CrashPhase.resolved:
        final bool won = state.round?.status == CrashRoundStatus.collected;
        final String label = won
            ? 'Collected +${state.round?.payout ?? 0} CR'
            : 'Crashed — bet lost';
        return Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(color: won ? AppColors.success : AppColors.error),
        );
    }
  }
}
