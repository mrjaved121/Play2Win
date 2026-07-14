import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../game/slot_machine_controller.dart';
import 'animated_reel.dart';

/// The metallic-gold-framed 3x3 slot machine, with a crown finial and a
/// ring of marquee lights around the border. Hosts 3 [AnimatedReel]s
/// driven by [controller] — this widget is chrome/layout only, all spin
/// animation lives in `features/slot/game/`.
class ReelFrame extends StatelessWidget {
  const ReelFrame({
    required this.controller,
    this.winningCells = const <(int, int)>{},
    this.hasWin = false,
    super.key,
  });

  final SlotMachineController controller;

  /// (row, col) coordinates on the active payline(s) — these cells pulse
  /// gold; everything else dims once [hasWin] is true.
  final Set<(int, int)> winningCells;
  final bool hasWin;

  static const List<List<SlotSymbol>> sampleGrid = <List<SlotSymbol>>[
    <SlotSymbol>[SlotSymbol.bar, SlotSymbol.cherry, SlotSymbol.skull],
    <SlotSymbol>[SlotSymbol.cherry, SlotSymbol.cherry, SlotSymbol.skull],
    <SlotSymbol>[SlotSymbol.lemon, SlotSymbol.bar, SlotSymbol.seven],
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppGradients.metallicGold,
              borderRadius: AppRadius.radiusXl,
              boxShadow: AppShadows.goldGlow,
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.reelBackground,
                borderRadius: BorderRadius.circular(AppRadius.xl - 6),
              ),
              child: _ReelRow(controller: controller, winningCells: winningCells, hasWin: hasWin),
            ),
          ),
          const Positioned(top: -18, child: _Crown()),
          const Positioned.fill(child: _LightRing()),
        ],
      ),
    );
  }
}

class _ReelRow extends StatelessWidget {
  const _ReelRow({required this.controller, required this.winningCells, required this.hasWin});

  final SlotMachineController controller;
  final Set<(int, int)> winningCells;
  final bool hasWin;

  static const double _cellGap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side = math.min(constraints.maxWidth, constraints.maxHeight);
        final double cellSize =
            (side - _cellGap * (GameConstants.reelCount - 1)) / GameConstants.reelCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int col = 0; col < GameConstants.reelCount; col++) ...<Widget>[
              AnimatedReel(
                controller: controller.reelControllers[col],
                cellSize: cellSize,
                cellGap: _cellGap,
                hasResolved: hasWin,
                winningRows: <int>{
                  for (final (int row, int c) in winningCells)
                    if (c == col) row,
                },
              ),
              if (col != GameConstants.reelCount - 1) const SizedBox(width: _cellGap),
            ],
          ],
        );
      },
    );
  }
}

class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.gold,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldLight, width: 1.5),
        boxShadow: AppShadows.goldGlow,
      ),
      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.textOnGold, size: 22),
    );
  }
}

/// Small marquee "light bulb" dots around the frame border — static for
/// now; Phase 5 adds the alternating blink-while-spinning animation.
class _LightRing extends StatelessWidget {
  const _LightRing();

  static const int _bulbCount = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        return Stack(
          children: List<Widget>.generate(_bulbCount, (int i) {
            final double t = i / _bulbCount;
            final double angle = t * 2 * math.pi;
            final double rx = w / 2 - 2;
            final double ry = h / 2 - 2;
            final double cx = w / 2 + rx * 0.98 * math.cos(angle);
            final double cy = h / 2 + ry * 0.98 * math.sin(angle);
            final bool lit = i.isEven;
            return Positioned(
              left: cx - 3,
              top: cy - 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lit ? AppColors.goldLight : AppColors.goldDark,
                  boxShadow: lit ? AppShadows.glow(AppColors.gold, intensity: 0.5) : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
