import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/crash_round.dart';
import '../providers/crash_providers.dart';
import 'crash_curve_painter.dart';

/// The centerpiece: the climb curve, the big multiplier readout, and
/// (once resolved) the win/crash result banner.
class MultiplierStage extends StatelessWidget {
  const MultiplierStage({required this.state, super.key});

  final CrashSlotState state;

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

  bool get _justCrashed =>
      state.phase == CrashPhase.resolved && state.round?.status == CrashRoundStatus.crashed;

  /// A fresh [Key] per round so the shake replays on every crash this
  /// session, not just the first — the multiplier [Text] itself is always
  /// present (unlike the one-shot flash overlay below, which is only ever
  /// inserted into the tree at the moment of a crash), so without a key
  /// tied to the round, flutter_animate would just reuse the same
  /// already-completed [Animate] element on a later crash.
  Widget _buildMultiplierText() {
    final Text text = Text(
      '${_multiplierToShow.toStringAsFixed(2)}x',
      style: AppTextStyles.displayJackpot.copyWith(fontSize: 56, color: _color),
    );
    if (!_justCrashed) return text;
    return text
        .animate(key: ValueKey<String?>(state.round?.roundId))
        .shake(duration: 400.ms, hz: 6, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final double capped = _multiplierToShow.clamp(1.0, _visualCap);
    final double progress = (math.log(capped) / math.log(_visualCap)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // A plain Stack sizes itself to fit its non-positioned child (the
        // multiplier-text Column) when given loose constraints, which this
        // widget's parent Column does (default, non-stretch cross-axis
        // alignment). Pinning the Stack to the LayoutBuilder's own bounds
        // here means _CurvePlane's math (below) and CrashCurvePainter's
        // canvas are guaranteed to be the same size — otherwise the two
        // silently disagree on "the curve's box" and the plane drifts away
        // from the line/dot it's supposed to be riding.
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(painter: CrashCurvePainter(progress: progress, color: _color)),
              ),
              if (progress > 0)
                _CurvePlane(progress: progress, color: _color, constraints: constraints),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildMultiplierText(),
                  const SizedBox(height: AppSpacing.sm),
                  _StatusLine(state: state),
                  if (state.round != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    _RoundDetailsLine(state: state),
                  ],
                ],
              ),
              if (_justCrashed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: AppColors.error)
                        .animate()
                        .fadeIn(duration: 120.ms, curve: Curves.easeOut)
                        .then()
                        .fadeOut(duration: 500.ms, curve: Curves.easeIn),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Round ID, start time, and crash point — the last one only revealed once
/// the round has resolved, matching the provably-fair design elsewhere in
/// this feature (the server itself withholds `crashPoint` while `pending`;
/// see [CrashRound]'s doc comment).
class _RoundDetailsLine extends StatelessWidget {
  const _RoundDetailsLine({required this.state});

  final CrashSlotState state;

  String get _shortRoundId {
    final String id = state.round!.roundId;
    return id.length <= 8 ? id : '#${id.substring(id.length - 6)}';
  }

  String get _time {
    final DateTime t = state.round!.startedAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final double? crashPoint = state.round!.crashPoint;
    return Text(
      'Round $_shortRoundId  •  $_time  •  '
      '${crashPoint != null ? "Crash ${crashPoint.toStringAsFixed(2)}x" : "Crash: hidden"}',
      style: AppTextStyles.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final CrashSlotState state;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case CrashPhase.idle:
        return Text('Place a bet to start climbing', style: AppTextStyles.bodyMedium);
      case CrashPhase.running:
        final int potential = (state.bet * state.displayMultiplier).round();
        return Text(
          'Potential payout: $potential PKR',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        );
      case CrashPhase.resolved:
        final bool won = state.round?.status == CrashRoundStatus.collected;
        final String label = won
            ? 'Collected +${state.round?.payout ?? 0} PKR'
            : 'Crashed — bet lost';
        return Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(color: won ? AppColors.success : AppColors.error),
        );
    }
  }
}

/// A plane riding the curve's leading edge — purely decorative, matching
/// the reference design's motif. Mirrors [CrashCurvePainter]'s own head-
/// position formula exactly so the plane and the line/dot it paints never
/// visibly diverge.
class _CurvePlane extends StatelessWidget {
  const _CurvePlane({required this.progress, required this.color, required this.constraints});

  final double progress;
  final Color color;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final double x = constraints.maxWidth * progress;
    final double y = constraints.maxHeight * (1 - math.pow(progress, 1.8));

    // Follows the curve's actual tangent instead of a fixed guessed angle:
    // dx/df = width (constant); dy/df = -1.8 * height * f^0.8, the
    // derivative of CrashCurvePainter's own easing. Nearly flat right at
    // the start (matching the curve hugging the bottom edge early on) and
    // steepening as the climb accelerates — `Icons.flight_rounded`'s
    // un-rotated glyph already points along +x (rightward), so
    // atan2(dy, dx) is the exact angle needed, no extra offset.
    final double dx = constraints.maxWidth;
    final double dy = -1.8 * constraints.maxHeight * math.pow(progress, 0.8);
    final double angle = math.atan2(dy, dx);

    return Positioned(
      left: x - 14,
      top: y - 14,
      child: Transform.rotate(
        angle: angle,
        child: Icon(Icons.flight_rounded, size: 28, color: color),
      ),
    );
  }
}
