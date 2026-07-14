import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/repositories/hive_game_repository.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/spin_outcome.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/spin_engine.dart';
import '../../domain/usecases/spin_usecase.dart';

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

  @override
  GameState build() => ref.read(gameRepositoryProvider).load();

  /// Deducts the bet/consumes a free spin and decides the outcome.
  /// Returns null (leaving state untouched) if the bet can't be covered.
  SpinOutcome? startSpin() {
    final (GameState, SpinOutcome)? prepared = ref.read(spinUseCaseProvider).prepareSpin(state);
    if (prepared == null) return null;
    final (GameState spinningState, SpinOutcome outcome) = prepared;
    _pendingSpinningState = spinningState;
    _pendingOutcome = outcome;
    state = spinningState;
    return outcome;
  }

  /// Applies the payout decided by the most recent [startSpin] once its
  /// reel animation has finished, and persists the result.
  void resolveSpin() {
    final GameState? spinningState = _pendingSpinningState;
    final SpinOutcome? outcome = _pendingOutcome;
    if (spinningState == null || outcome == null) return;

    final GameState finalState = ref.read(spinUseCaseProvider).resolveSpin(spinningState, outcome);
    state = finalState;
    _pendingSpinningState = null;
    _pendingOutcome = null;
    unawaited(ref.read(gameRepositoryProvider).save(finalState));
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
