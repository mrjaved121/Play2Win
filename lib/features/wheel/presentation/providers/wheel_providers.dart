import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/guest_identity_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../crash/presentation/providers/crash_providers.dart' show crashApiClientProvider;
import '../../data/datasources/wheel_api_client.dart';
import '../../domain/entities/wheel_result.dart';

final Provider<WheelApiClient> wheelApiClientProvider = Provider<WheelApiClient>((Ref ref) => WheelApiClient());

enum WheelPhase { idle, spinning }

class WheelUiState {
  const WheelUiState({
    this.phase = WheelPhase.idle,
    this.bet = AppConstants.defaultBet,
    this.balance,
    this.balanceLoading = true,
    this.lastResult,
    this.errorMessage,
    this.busy = false,
    this.history = const <WheelHistoryEntry>[],
  });

  final WheelPhase phase;
  final int bet;
  final int? balance;
  final bool balanceLoading;
  final WheelPlayResult? lastResult;
  final String? errorMessage;
  final bool busy;

  /// Past spins, most recent first. Seeded from the server on load, then
  /// this session's own spins are prepended locally as they resolve.
  final List<WheelHistoryEntry> history;

  bool get canAffordBet => balance == null || balance! >= bet;

  WheelUiState copyWith({
    WheelPhase? phase,
    int? bet,
    int? balance,
    bool? balanceLoading,
    WheelPlayResult? lastResult,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    List<WheelHistoryEntry>? history,
  }) {
    return WheelUiState(
      phase: phase ?? this.phase,
      bet: bet ?? this.bet,
      balance: balance ?? this.balance,
      balanceLoading: balanceLoading ?? this.balanceLoading,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      history: history ?? this.history,
    );
  }
}

/// Drives Lucky Wheel. Unlike [[GameNotifier]] (slots), there's no local
/// outcome to compute — [spin] just calls the server and applies whatever
/// it decides. `balance` reads the same `credit_balance` economy as
/// Multiplier Climb (this game shares it, see blackhole_admin's
/// GameRoundRepository), fetched via the same endpoint crash already uses
/// rather than duplicating a balance concept.
class WheelNotifier extends Notifier<WheelUiState> {
  @override
  WheelUiState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_loadBalance());
      unawaited(_loadHistory());
    }
    return WheelUiState(balanceLoading: ApiConfig.isConfigured);
  }

  String get _guestId => ref.read(guestIdProvider);
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
      final List<WheelHistoryEntry> history =
          await ref.read(wheelApiClientProvider).fetchHistory(_guestId, accessToken: _accessToken);
      state = state.copyWith(history: history);
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  void adjustBet(int delta) {
    if (state.phase != WheelPhase.idle) return;
    final int next = (state.bet + delta).clamp(AppConstants.minBet, AppConstants.maxBet);
    state = state.copyWith(bet: next);
  }

  /// Returns the result for the caller to animate toward, or null if the
  /// spin couldn't be started (already spinning, can't afford it, or the
  /// request failed — [state.errorMessage] carries the reason for that
  /// last case).
  Future<WheelPlayResult?> spin() async {
    if (state.busy || state.phase == WheelPhase.spinning || !state.canAffordBet) return null;
    state = state.copyWith(busy: true, phase: WheelPhase.spinning, clearError: true);
    try {
      final WheelPlayResult result = await ref
          .read(wheelApiClientProvider)
          .spin(guestId: _guestId, accessToken: _accessToken, bet: state.bet);
      final WheelHistoryEntry entry = WheelHistoryEntry(
        bet: state.bet,
        multiplier: result.multiplier,
        winAmount: result.winAmount,
        isWin: result.winAmount > 0,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        balance: result.newBalance,
        lastResult: result,
        busy: false,
        history: <WheelHistoryEntry>[entry, ...state.history].take(20).toList(),
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        busy: false,
        phase: WheelPhase.idle,
        errorMessage: error is WheelApiException ? error.message : "Can't reach the game server",
      );
      return null;
    }
  }

  /// Called by the screen once the landing animation finishes.
  void finishSpin() {
    state = state.copyWith(phase: WheelPhase.idle);
  }
}

final NotifierProvider<WheelNotifier, WheelUiState> wheelProvider =
    NotifierProvider<WheelNotifier, WheelUiState>(WheelNotifier.new);
