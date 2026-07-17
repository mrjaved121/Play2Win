import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../crash/presentation/providers/crash_providers.dart'
    show crashApiClientProvider, crashGuestIdProvider;
import '../../data/datasources/scratch_api_client.dart';
import '../../domain/entities/scratch_result.dart';

final Provider<ScratchApiClient> scratchApiClientProvider = Provider<ScratchApiClient>(
  (Ref ref) => ScratchApiClient(),
);

enum ScratchPhase { idle, revealing }

class ScratchUiState {
  const ScratchUiState({
    this.phase = ScratchPhase.idle,
    this.cost = AppConstants.defaultBet,
    this.balance,
    this.balanceLoading = true,
    this.lastResult,
    this.errorMessage,
    this.busy = false,
    this.history = const <ScratchHistoryEntry>[],
  });

  final ScratchPhase phase;
  final int cost;
  final int? balance;
  final bool balanceLoading;
  final ScratchPlayResult? lastResult;
  final String? errorMessage;
  final bool busy;

  /// Past cards, most recent first. Seeded from the server on load, then
  /// this session's own cards are prepended locally as they resolve.
  final List<ScratchHistoryEntry> history;

  bool get canAfford => balance == null || balance! >= cost;

  ScratchUiState copyWith({
    ScratchPhase? phase,
    int? cost,
    int? balance,
    bool? balanceLoading,
    ScratchPlayResult? lastResult,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    List<ScratchHistoryEntry>? history,
  }) {
    return ScratchUiState(
      phase: phase ?? this.phase,
      cost: cost ?? this.cost,
      balance: balance ?? this.balance,
      balanceLoading: balanceLoading ?? this.balanceLoading,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      history: history ?? this.history,
    );
  }
}

/// Drives Scratch Card. Like [[WheelNotifier]], there's no local outcome
/// to compute — [buy] just calls the server and applies whatever it
/// decides; the scratch-reveal gesture on screen is purely cosmetic
/// animation over an already-resolved result. `balance` reads the same
/// `credit_balance` economy as Multiplier Climb and Lucky Wheel.
class ScratchNotifier extends Notifier<ScratchUiState> {
  @override
  ScratchUiState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_loadBalance());
      unawaited(_loadHistory());
    }
    return ScratchUiState(balanceLoading: ApiConfig.isConfigured);
  }

  String get _guestId => ref.read(crashGuestIdProvider);
  String? get _accessToken => ref.read(authRepositoryProvider)?.accessToken;

  Future<void> _loadBalance() async {
    try {
      final ({int balance, String? playerId}) result =
          await ref.read(crashApiClientProvider).fetchBalance(_guestId, accessToken: _accessToken);
      state = state.copyWith(balance: result.balance, balanceLoading: false);
    } catch (_) {
      state = state.copyWith(balanceLoading: false);
    }
  }

  /// Best-effort — an empty history strip on failure is a fine fallback.
  Future<void> _loadHistory() async {
    try {
      final List<ScratchHistoryEntry> history =
          await ref.read(scratchApiClientProvider).fetchHistory(_guestId, accessToken: _accessToken);
      state = state.copyWith(history: history);
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  void adjustCost(int delta) {
    if (state.phase != ScratchPhase.idle) return;
    final int next = (state.cost + delta).clamp(AppConstants.minBet, AppConstants.maxBet);
    state = state.copyWith(cost: next);
  }

  /// Buys and resolves a new card; the caller drives the reveal animation
  /// from the returned result, then calls [finishReveal].
  Future<ScratchPlayResult?> buy() async {
    if (state.busy || !state.canAfford) return null;
    state = state.copyWith(busy: true, clearError: true, clearResult: true);
    try {
      final ScratchPlayResult result =
          await ref.read(scratchApiClientProvider).play(guestId: _guestId, accessToken: _accessToken, cost: state.cost);
      final ScratchHistoryEntry entry = ScratchHistoryEntry(
        cost: state.cost,
        multiplier: result.multiplier,
        winAmount: result.winAmount,
        isWin: result.winAmount > 0,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        balance: result.newBalance,
        phase: ScratchPhase.revealing,
        busy: false,
        history: <ScratchHistoryEntry>[entry, ...state.history].take(20).toList(),
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        busy: false,
        errorMessage: error is ScratchApiException ? error.message : "Can't reach the game server",
      );
      return null;
    }
  }

  /// Called by the screen once the reveal animation finishes.
  void finishReveal(ScratchPlayResult result) {
    state = state.copyWith(phase: ScratchPhase.idle, lastResult: result);
  }
}

final NotifierProvider<ScratchNotifier, ScratchUiState> scratchProvider =
    NotifierProvider<ScratchNotifier, ScratchUiState>(ScratchNotifier.new);
