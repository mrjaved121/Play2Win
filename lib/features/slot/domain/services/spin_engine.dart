import 'dart:math' as math;

import '../../../../core/constants/game_constants.dart';
import '../entities/spin_outcome.dart';

/// Pure game-logic engine: given a bet and payout multiplier, decides
/// what a single spin lands on. Stateless and deterministic given its
/// [math.Random] — every rule from `GameConstants` (weighted symbols,
/// paylines, near-miss chance, jackpot chance) lives here so it's
/// unit-testable without Flutter/widgets in the picture.
class SpinEngine {
  SpinEngine({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// Flattened weighted pool: each symbol appears [SlotSymbolX.weight]
  /// times, so drawing uniformly from this list reproduces the intended
  /// per-symbol odds without recomputing cumulative weights per draw.
  static final List<SlotSymbol> _weightedPool = <SlotSymbol>[
    for (final SlotSymbol symbol in SlotSymbol.values)
      ...List<SlotSymbol>.filled(symbol.weight, symbol),
  ];

  SpinOutcome spin({required int bet, double payoutMultiplier = 1.0}) {
    final List<List<SlotSymbol>> grid = _weightedGrid();
    final List<List<int>> winningLines = _winningLines(grid);

    if (winningLines.isNotEmpty) {
      final Set<(int, int)> wins = <(int, int)>{
        for (final List<int> line in winningLines)
          for (int col = 0; col < line.length; col++) (line[col], col),
      };
      int payout = 0;
      for (final List<int> line in winningLines) {
        payout += (bet * grid[line[0]][0].payoutMultiplier * payoutMultiplier).round();
      }
      final bool isJackpot = _random.nextDouble() < GameConstants.jackpotWinChance;
      return SpinOutcome(
        grid: grid,
        winningCells: wins,
        totalPayout: payout,
        isJackpot: isJackpot,
        isNearMiss: false,
      );
    }

    if (_random.nextDouble() < GameConstants.nearMissChance) {
      return SpinOutcome(
        grid: _forceNearMiss(grid),
        winningCells: const <(int, int)>{},
        totalPayout: 0,
        isJackpot: false,
        isNearMiss: true,
      );
    }

    return SpinOutcome(
      grid: grid,
      winningCells: const <(int, int)>{},
      totalPayout: 0,
      isJackpot: false,
      isNearMiss: false,
    );
  }

  List<List<SlotSymbol>> _weightedGrid() {
    return List<List<SlotSymbol>>.generate(
      GameConstants.symbolsPerReel,
      (_) => List<SlotSymbol>.generate(
        GameConstants.reelCount,
        (_) => _weightedPool[_random.nextInt(_weightedPool.length)],
      ),
    );
  }

  /// Paylines (from `GameConstants.paylines`) where all 3 symbols match.
  List<List<int>> _winningLines(List<List<SlotSymbol>> grid) {
    return <List<int>>[
      for (final List<int> line in GameConstants.paylines)
        if (List<int>.generate(line.length, (int i) => i)
            .every((int col) => grid[line[col]][col] == grid[line[0]][0]))
          line,
    ];
  }

  /// Mutates a copy of [grid] so exactly one payline shows 2 matching
  /// symbols plus a 3rd symbol adjacent to them in paytable order — the
  /// classic "so close!" psychological near-miss, per
  /// [GameConstants.nearMissChance].
  List<List<SlotSymbol>> _forceNearMiss(List<List<SlotSymbol>> grid) {
    final List<List<SlotSymbol>> copy = <List<SlotSymbol>>[
      for (final List<SlotSymbol> row in grid) List<SlotSymbol>.of(row),
    ];
    final List<int> line = GameConstants.paylines[_random.nextInt(GameConstants.paylines.length)];

    final SlotSymbol matched = SlotSymbol.values[_random.nextInt(SlotSymbol.values.length)];
    final int matchedIndex = SlotSymbol.values.indexOf(matched);
    final SlotSymbol adjacent = SlotSymbol.values[
        matchedIndex == SlotSymbol.values.length - 1 ? matchedIndex - 1 : matchedIndex + 1];

    final int oddOneOutCol = _random.nextInt(GameConstants.reelCount);
    for (int col = 0; col < GameConstants.reelCount; col++) {
      copy[line[col]][col] = col == oddOneOutCol ? adjacent : matched;
    }
    return copy;
  }
}
