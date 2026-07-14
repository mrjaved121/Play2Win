import '../../../../core/constants/game_constants.dart';

/// The result of a single spin: what landed, what won, and what it paid.
///
/// Ephemeral — only consumed by the UI to drive the reel animation and
/// win presentation for the spin that just happened, so unlike
/// [GameState] it isn't persisted and doesn't need JSON codegen.
class SpinOutcome {
  const SpinOutcome({
    required this.grid,
    required this.winningCells,
    required this.totalPayout,
    required this.isJackpot,
    required this.isNearMiss,
  });

  /// 3x3, row-major (`grid[row][col]`).
  final List<List<SlotSymbol>> grid;

  /// (row, col) cells on a winning payline.
  final Set<(int, int)> winningCells;

  final int totalPayout;
  final bool isJackpot;
  final bool isNearMiss;

  bool get isWin => totalPayout > 0;
}
