import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/hive_game_repository.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/spin_outcome.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/spin_engine.dart';
import '../../domain/usecases/spin_usecase.dart';
import 'slots_sync_providers.dart';

final Provider<GameRepository> gameRepositoryProvider = Provider<GameRepository>(
  (Ref ref) => HiveGameRepository(getIt<StorageService>()),
);

final Provider<SpinEngine> spinEngineProvider = Provider<SpinEngine>((Ref ref) => SpinEngine());

final Provider<SpinUseCase> spinUseCaseProvider = Provider<SpinUseCase>(
  (Ref ref) => SpinUseCase(engine: ref.watch(spinEngineProvider)),
);

/// Owns the player's [GameState] and drives spins through [SpinUseCase],
/// split into [startSpin] (bet deduction, decides the outcome) and
/// [resolveSpin] (applies payout) so the caller can animate the reels in
/// between — see `SpinUseCase`'s doc comment for why.
class GameNotifier extends Notifier<GameState> {
  GameState? _pendingSpinningState;
  SpinOutcome? _pendingOutcome;
  int _pendingBetCharged = 0;

  /// Guards against a slow/late sync response reconciling [state.balance]
  /// backwards after a *newer* spin has already happened — only the most
  /// recently issued sync's response is allowed to apply.
  int _syncSeq = 0;

  @override
  GameState build() => ref.read(gameRepositoryProvider).load();

  /// Deducts the bet/consumes a free spin and decides the outcome.
  /// Returns null (leaving state untouched) if the bet can't be covered.
  SpinOutcome? startSpin() {
    final GameState stateBeforeSpin = state;
    final (GameState, SpinOutcome)? prepared = ref.read(spinUseCaseProvider).prepareSpin(state);
    if (prepared == null) return null;
    final (GameState spinningState, SpinOutcome outcome) = prepared;
    _pendingSpinningState = spinningState;
    _pendingOutcome = outcome;
    // 0 for a free spin (no balance deducted) rather than re-deriving the
    // free-spin check here — this is just "how much did balance drop".
    _pendingBetCharged = stateBeforeSpin.balance - spinningState.balance;
    state = spinningState;
    return outcome;
  }

  /// Applies the payout decided by the most recent [startSpin] once its
  /// reel animation has finished, and persists the result.
  void resolveSpin() {
    final GameState? spinningState = _pendingSpinningState;
    final SpinOutcome? outcome = _pendingOutcome;
    final int betCharged = _pendingBetCharged;
    if (spinningState == null || outcome == null) return;

    final GameState finalState = ref.read(spinUseCaseProvider).resolveSpin(spinningState, outcome);
    state = finalState;
    _pendingSpinningState = null;
    _pendingOutcome = null;
    _pendingBetCharged = 0;
    unawaited(ref.read(gameRepositoryProvider).save(finalState));
    unawaited(_syncSpin(bet: betCharged, outcome: outcome, winAmount: finalState.lastWin, clientBalance: finalState.balance));
  }

  /// Reports this spin to blackhole_admin (best-effort — see
  /// SlotsSyncController) and reconciles [state.balance] from its
  /// response, so admin gets the same visibility Multiplier Climb has and
  /// a signed-in player's balance stays portable across devices. Never
  /// touches game logic or blocks on the network; offline/unconfigured
  /// play is unaffected.
  Future<void> _syncSpin({
    required int bet,
    required SpinOutcome outcome,
    required int winAmount,
    required int clientBalance,
  }) async {
    if (!ApiConfig.isConfigured) return;
    final int seq = ++_syncSeq;
    final ({String outcome, List<String> symbols}) encoded = encodeSlotRow(outcome.grid[1]);
    final int? serverBalance = await ref.read(slotsSyncControllerProvider).recordSpin(
          bet: bet,
          winAmount: winAmount,
          isWin: winAmount > 0,
          isJackpot: outcome.isJackpot,
          outcome: encoded.outcome,
          symbols: encoded.symbols,
          clientBalance: clientBalance,
        );
    if (serverBalance != null && seq == _syncSeq && serverBalance != state.balance) {
      state = state.copyWith(balance: serverBalance);
      unawaited(ref.read(gameRepositoryProvider).save(state));
    }
  }

  void adjustBet(int delta) {
    final int newBet = (state.bet + delta).clamp(AppConstants.minBet, AppConstants.maxBet);
    state = state.copyWith(bet: newBet);
  }

  /// Credits [amount] coins outside the spin flow — mission rewards,
  /// daily bonus claims, store purchases, etc.
  void addCoins(int amount) {
    state = state.copyWith(balance: state.balance + amount);
    unawaited(ref.read(gameRepositoryProvider).save(state));
  }
}

final NotifierProvider<GameNotifier, GameState> gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
