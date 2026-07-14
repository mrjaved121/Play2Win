import 'dart:math' as math;

import '../../../../core/constants/game_constants.dart';
import '../entities/game_state.dart';
import '../entities/spin_outcome.dart';
import '../services/spin_engine.dart';

/// Orchestrates one spin across two steps so the UI can show the bet
/// deduction immediately and the payout only once the reels finish
/// landing, instead of the balance jumping straight to its final value
/// before the player has seen the result:
///
/// 1. [prepareSpin] — validates the bet, decides the outcome via
///    [SpinEngine], deducts the bet (or consumes a free spin).
/// 2. [resolveSpin] — called after the reel animation completes; applies
///    payout, jackpot pot growth/payout, win/loss streaks and free-spin
///    awarding on top of the state [prepareSpin] returned.
class SpinUseCase {
  SpinUseCase({required this._engine});

  final SpinEngine _engine;

  /// Returns null if the bet exceeds the balance and no free spin is
  /// available (the caller should keep the SPIN button disabled in that
  /// case, so this is a defensive check rather than the primary guard).
  (GameState spinningState, SpinOutcome outcome)? prepareSpin(GameState state) {
    final bool freeSpinActive = state.freeSpinsRemaining > 0;
    if (!freeSpinActive && state.bet > state.balance) return null;

    final double multiplier = freeSpinActive ? GameConstants.freeSpinsMultiplier : 1.0;
    final SpinOutcome outcome = _engine.spin(bet: state.bet, payoutMultiplier: multiplier);

    final GameState spinningState = state.copyWith(
      balance: freeSpinActive ? state.balance : state.balance - state.bet,
      freeSpinsRemaining: freeSpinActive ? state.freeSpinsRemaining - 1 : state.freeSpinsRemaining,
    );
    return (spinningState, outcome);
  }

  GameState resolveSpin(GameState spinningState, SpinOutcome outcome) {
    int newJackpot = spinningState.jackpot;
    int payout = outcome.totalPayout;
    if (outcome.isJackpot) {
      payout += newJackpot;
      newJackpot = GameConstants.jackpotSeed;
    } else {
      newJackpot += (spinningState.bet * GameConstants.jackpotContributionRate).round();
    }

    final bool won = payout > 0;
    int newLossStreak = won ? 0 : spinningState.lossStreak + 1;
    int newFreeSpinsRemaining = spinningState.freeSpinsRemaining;
    if (newLossStreak >= GameConstants.freeSpinsTriggerCount) {
      newFreeSpinsRemaining += GameConstants.freeSpinsAwarded;
      newLossStreak = 0;
    }

    return spinningState.copyWith(
      balance: spinningState.balance + payout,
      totalSpins: spinningState.totalSpins + 1,
      lastWin: payout,
      bestWinToday: math.max(spinningState.bestWinToday, payout),
      winStreak: won ? spinningState.winStreak + 1 : 0,
      lossStreak: newLossStreak,
      freeSpinsRemaining: newFreeSpinsRemaining,
      jackpot: newJackpot,
      lifetimeWinnings: spinningState.lifetimeWinnings + payout,
      jackpotsWon: spinningState.jackpotsWon + (outcome.isJackpot ? 1 : 0),
      totalWins: spinningState.totalWins + (won ? 1 : 0),
    );
  }
}
