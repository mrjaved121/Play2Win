import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/game_constants.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// The persisted state of a player's slot machine session: wallet +
/// running stats + jackpot pot + any pending free spins. Serialized via
/// the generated `toJson`/`fromJson` and stored as a plain map in Hive
/// (see [[project-build-environment-gotchas]] for why — no
/// `hive_generator`/`@HiveType` here).
@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    required int balance,
    required int bet,
    required int totalSpins,
    required int lastWin,
    required int bestWinToday,
    required int winStreak,
    required int lossStreak,
    required int freeSpinsRemaining,
    required int jackpot,
    // Added after the initial Phase 4 shape — @Default keeps loading
    // Hive data saved before these existed from throwing in fromJson.
    @Default(0) int lifetimeWinnings,
    @Default(0) int jackpotsWon,
    @Default(0) int totalWins,
  }) = _GameState;

  factory GameState.initial() => const GameState(
        balance: AppConstants.startingBalance,
        bet: AppConstants.defaultBet,
        totalSpins: 0,
        lastWin: 0,
        bestWinToday: 0,
        winStreak: 0,
        lossStreak: 0,
        freeSpinsRemaining: 0,
        jackpot: GameConstants.jackpotSeed,
        lifetimeWinnings: 0,
        jackpotsWon: 0,
        totalWins: 0,
      );

  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);
}
