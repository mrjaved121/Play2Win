import 'package:flutter/animation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/game_constants.dart';
import 'reel_spin_controller.dart';

/// Orchestrates the 3 [ReelSpinController]s that make up the slot
/// machine, staggering their stop times so reels settle left-to-right
/// like a real machine rather than all at once.
///
/// This class only knows how to *animate to* a result grid — it doesn't
/// decide what that grid is. Phase 4's game-logic layer computes the
/// actual (weighted-random, payline-aware) outcome and passes it in via
/// [spinTo]; this controller stays a pure animation concern.
class SlotMachineController {
  SlotMachineController({required TickerProvider vsync})
      : reelControllers = List<ReelSpinController>.generate(
          GameConstants.reelCount,
          (int i) => ReelSpinController(
            vsync: vsync,
            duration: AppConstants.reelSpinDuration +
                AppConstants.reelStaggerDelay * i,
          ),
        );

  final List<ReelSpinController> reelControllers;

  bool get isSpinning => reelControllers.any((ReelSpinController c) => c.isSpinning);

  /// Spins every reel to land on [targetGrid] (`targetGrid[row][col]`,
  /// row-major, 3x3). All reels start together; because each has a
  /// progressively longer duration they stop in column order.
  Future<void> spinTo(List<List<SlotSymbol>> targetGrid) {
    assert(targetGrid.length == GameConstants.symbolsPerReel);
    final List<Future<void>> spins = <Future<void>>[
      for (int col = 0; col < GameConstants.reelCount; col++)
        reelControllers[col].spinTo(<SlotSymbol>[
          for (int row = 0; row < GameConstants.symbolsPerReel; row++) targetGrid[row][col],
        ]),
    ];
    return Future.wait(spins);
  }

  void dispose() {
    for (final ReelSpinController controller in reelControllers) {
      controller.dispose();
    }
  }
}
