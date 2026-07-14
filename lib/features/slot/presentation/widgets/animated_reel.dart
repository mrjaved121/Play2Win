import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../game/reel_spin_controller.dart';
import 'slot_symbol_view.dart';

/// Renders one reel's scrollable symbol strip inside a fixed 3-cell
/// viewport, driven by a [ReelSpinController]. Applies a vertical motion
/// blur while spinning (strength taken from the controller) and, once
/// stopped, pulses winning cells / dims losing ones.
class AnimatedReel extends StatelessWidget {
  const AnimatedReel({
    required this.controller,
    required this.cellSize,
    required this.cellGap,
    this.winningRows = const <int>{},
    this.hasResolved = false,
    super.key,
  });

  final ReelSpinController controller;
  final double cellSize;
  final double cellGap;

  /// Row indices (0-2) of this column that are part of a winning
  /// payline. Only meaningful once spinning has stopped.
  final Set<int> winningRows;
  final bool hasResolved;

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = cellSize * GameConstants.symbolsPerReel +
        cellGap * (GameConstants.symbolsPerReel - 1);

    // Isolates this reel's own compositor layer: while spinning it repaints
    // every frame (scroll position + blur), and without this boundary that
    // would force the whole ReelFrame — metallic border, crown, light ring —
    // to repaint alongside it for every one of those frames.
    return RepaintBoundary(
      child: ClipRect(
        child: SizedBox(
          height: viewportHeight,
          width: cellSize,
          child: AnimatedBuilder(
            animation: controller.animationController,
            builder: (BuildContext context, Widget? child) {
              final List<SlotSymbol> strip = controller.strip;
              final int scrollableSymbols = strip.length - GameConstants.symbolsPerReel;
              final double scrollY =
                  controller.t * scrollableSymbols * (cellSize + cellGap);
              final double blur = controller.blurSigma;
              final bool spinning = controller.isSpinning;

              Widget stack = Transform.translate(
                offset: Offset(0, -scrollY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0; i < strip.length; i++) ...<Widget>[
                      _ReelCell(
                        symbol: strip[i],
                        size: cellSize,
                        winning: !spinning &&
                            hasResolved &&
                            i >= strip.length - GameConstants.symbolsPerReel &&
                            winningRows.contains(i - (strip.length - GameConstants.symbolsPerReel)),
                        dimmed: !spinning &&
                            hasResolved &&
                            i >= strip.length - GameConstants.symbolsPerReel &&
                            !winningRows.contains(i - (strip.length - GameConstants.symbolsPerReel)),
                      ),
                      if (i != strip.length - 1) SizedBox(height: cellGap),
                    ],
                  ],
                ),
              );

              if (blur > 0.1) {
                stack = ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: blur),
                  child: stack,
                );
              }

              return stack;
            },
          ),
        ),
      ),
    );
  }
}

class _ReelCell extends StatelessWidget {
  const _ReelCell({
    required this.symbol,
    required this.size,
    required this.winning,
    required this.dimmed,
  });

  final SlotSymbol symbol;
  final double size;
  final bool winning;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Widget cell = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: winning ? AppColors.winGlow : AppColors.cardBorder,
          width: winning ? 2 : 1,
        ),
        boxShadow: winning ? AppShadows.winGlow : null,
      ),
      child: SlotSymbolView(symbol: symbol, size: size * 0.72, dimmed: dimmed),
    );

    if (!winning) return cell;

    return cell
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .scaleXY(end: 1.08, duration: 500.ms, curve: Curves.easeInOut);
  }
}
