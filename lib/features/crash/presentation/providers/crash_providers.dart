import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/crash_api_client.dart';
import '../../data/repositories/http_crash_repository.dart';
import '../../domain/crash_constants.dart';
import '../../domain/entities/crash_round.dart';
import '../../domain/repositories/crash_repository.dart';

final Provider<CrashApiClient> crashApiClientProvider = Provider<CrashApiClient>(
  (Ref ref) => CrashApiClient(),
);

final Provider<CrashRepository> crashRepositoryProvider = Provider<CrashRepository>(
  (Ref ref) => HttpCrashRepository(ref.watch(crashApiClientProvider)),
);

/// Stable per-install id sent with every crash-game request instead of a
/// login — generated once and persisted locally, same "Guest Mode" spirit
/// as the rest of this app.
final Provider<String> crashGuestIdProvider = Provider<String>((Ref ref) {
  const String key = 'crash_guest_id';
  final StorageService storage = getIt<StorageService>();
  final String? existing = storage.get<String>(key);
  if (existing != null) return existing;

  final String created = const Uuid().v4();
  unawaited(storage.put<String>(key, created));
  return created;
});

enum CrashPhase { idle, running, resolved }

class CrashUiState {
  const CrashUiState({
    this.phase = CrashPhase.idle,
    this.bet = CrashConstants.defaultBet,
    this.balance,
    this.playerId,
    this.round,
    this.displayMultiplier = 1.0,
    this.errorMessage,
    this.busy = false,
    this.balanceLoading = true,
    this.history = const <CrashHistoryEntry>[],
  });

  final CrashPhase phase;
  final int bet;
  final int? balance;

  /// The canonical `players.id` row admin sees in the dashboard — distinct
  /// from [crashGuestIdProvider]'s value, which is only this device's
  /// local lookup key. Null until the first successful balance fetch.
  final String? playerId;
  final CrashRound? round;
  final double displayMultiplier;
  final String? errorMessage;
  final bool busy;
  final bool balanceLoading;

  /// Past resolved rounds, most recent first — the small crash-history
  /// strip real crash games show so a player can eyeball how "hot" or
  /// "cold" recent rounds have been. Seeded from the server on load, then
  /// this session's own rounds are prepended locally as they resolve.
  final List<CrashHistoryEntry> history;

  bool get canAffordBet => balance == null || balance! >= bet;

  CrashUiState copyWith({
    CrashPhase? phase,
    int? bet,
    int? balance,
    String? playerId,
    CrashRound? round,
    bool clearRound = false,
    double? displayMultiplier,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    bool? balanceLoading,
    List<CrashHistoryEntry>? history,
  }) {
    return CrashUiState(
      phase: phase ?? this.phase,
      bet: bet ?? this.bet,
      balance: balance ?? this.balance,
      playerId: playerId ?? this.playerId,
      round: clearRound ? null : (round ?? this.round),
      displayMultiplier: displayMultiplier ?? this.displayMultiplier,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      balanceLoading: balanceLoading ?? this.balanceLoading,
      history: history ?? this.history,
    );
  }
}

/// Drives a round of Multiplier Climb. The multiplier shown while a round
/// is [CrashPhase.running] is rendered *locally* (see [_renderTicker])
/// from the round's `startedAt`/`growthRate` — no network call is needed
/// for that to feel smooth. A slower [_reconciliationTicker] separately
/// polls the server so the player is actually told when a round crashed
/// even if they never tap Collect; without it the local render would just
/// climb forever since the client has no other way to learn the (hidden)
/// crash time passed.
class CrashGameNotifier extends Notifier<CrashUiState> {
  Timer? _renderTicker;
  Timer? _reconciliationTicker;

  @override
  CrashUiState build() {
    ref.onDispose(() {
      _renderTicker?.cancel();
      _reconciliationTicker?.cancel();
    });
    if (ApiConfig.isConfigured) {
      unawaited(_loadBalance());
      unawaited(_loadHistory());
    }
    return CrashUiState(balanceLoading: ApiConfig.isConfigured);
  }

  String get _guestId => ref.read(crashGuestIdProvider);
  CrashRepository get _repo => ref.read(crashRepositoryProvider);

  /// Sent with every request so a signed-in player's balance resolves by
  /// account instead of this device's guestId — see
  /// blackhole_admin's CrashRepository.resolvePlayer. Read fresh each call
  /// (not cached at login) since sessions can refresh or expire.
  String? get _accessToken => ref.read(authRepositoryProvider)?.accessToken;

  Future<void> _loadBalance() async {
    try {
      final ({int balance, String? playerId}) result = await _repo.fetchBalance(_guestId, accessToken: _accessToken);
      state = state.copyWith(balance: result.balance, playerId: result.playerId, balanceLoading: false);
    } catch (error) {
      state = state.copyWith(balanceLoading: false, errorMessage: _friendlyError(error));
    }
  }

  /// Best-effort — an empty history strip on failure is a fine fallback,
  /// not worth surfacing as a user-facing error.
  Future<void> _loadHistory() async {
    try {
      final List<CrashHistoryEntry> history = await _repo.fetchHistory(_guestId, accessToken: _accessToken);
      state = state.copyWith(history: history);
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  void adjustBet(int delta) {
    if (state.phase != CrashPhase.idle) return;
    final int next = (state.bet + delta).clamp(CrashConstants.minBet, CrashConstants.maxBet);
    state = state.copyWith(bet: next);
  }

  Future<void> placeBet() async {
    if (state.busy || state.phase == CrashPhase.running) return;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final CrashRoundResult result = await _repo.placeBet(
        guestId: _guestId,
        betAmount: state.bet,
        accessToken: _accessToken,
      );
      state = state.copyWith(
        phase: CrashPhase.running,
        round: result.round,
        balance: result.balance,
        displayMultiplier: 1.0,
        busy: false,
      );
      _startRoundTimers();
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
    }
  }

  Future<void> collect() async {
    final CrashRound? round = state.round;
    if (round == null || state.busy || state.phase != CrashPhase.running) return;
    state = state.copyWith(busy: true);
    try {
      final CrashRoundResult result = await _repo.collect(
        guestId: _guestId,
        roundId: round.roundId,
        accessToken: _accessToken,
      );
      _stopRoundTimers();
      state = state.copyWith(
        phase: CrashPhase.resolved,
        round: result.round,
        balance: result.balance,
        displayMultiplier: result.round.resolvedMultiplier ?? result.round.crashPoint ?? state.displayMultiplier,
        busy: false,
        history: <CrashHistoryEntry>[_toHistoryEntry(result.round), ...state.history].take(20).toList(),
      );
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
    }
  }

  /// Clears the resolved round so the player can set a new bet and play
  /// again.
  void startNewRound() {
    _stopRoundTimers();
    state = state.copyWith(phase: CrashPhase.idle, clearRound: true, displayMultiplier: 1.0, clearError: true);
  }

  void _startRoundTimers() {
    _stopRoundTimers();
    _renderTicker = Timer.periodic(CrashConstants.renderTickInterval, (_) {
      final CrashRound? round = state.round;
      if (round == null) return;
      state = state.copyWith(displayMultiplier: round.multiplierAt(DateTime.now()));
    });
    _reconciliationTicker = Timer.periodic(CrashConstants.statePollInterval, (_) => _pollForCrash());
  }

  void _stopRoundTimers() {
    _renderTicker?.cancel();
    _renderTicker = null;
    _reconciliationTicker?.cancel();
    _reconciliationTicker = null;
  }

  /// Best-effort check for "it already crashed and I never tapped
  /// Collect" — failures here are silently ignored (next tick retries)
  /// rather than surfaced as a user-facing error, since this is a
  /// background reconciliation, not something the player asked for.
  Future<void> _pollForCrash() async {
    final CrashRound? round = state.round;
    if (round == null || state.phase != CrashPhase.running) return;
    try {
      final CrashRound? latest = await _repo.fetchState(
        guestId: _guestId,
        roundId: round.roundId,
        accessToken: _accessToken,
      );
      if (latest != null && latest.status == CrashRoundStatus.crashed) {
        _stopRoundTimers();
        state = state.copyWith(
          phase: CrashPhase.resolved,
          round: latest,
          displayMultiplier: latest.crashPoint ?? state.displayMultiplier,
          history: <CrashHistoryEntry>[_toHistoryEntry(latest), ...state.history].take(20).toList(),
        );
      }
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  /// Builds an optimistic history entry from a just-resolved round, so the
  /// strip updates immediately instead of waiting for the next app launch's
  /// [_loadHistory] to pick it up from the server.
  CrashHistoryEntry _toHistoryEntry(CrashRound round) {
    return CrashHistoryEntry(
      roundId: round.roundId,
      bet: round.betAmount,
      multiplier: round.resolvedMultiplier ?? round.crashPoint ?? 1.0,
      winAmount: round.payout ?? 0,
      isWin: round.status == CrashRoundStatus.collected,
      timestamp: DateTime.now(),
    );
  }

  String _friendlyError(Object error) {
    if (error is CrashApiException) return error.message;
    return "Can't reach the game server";
  }
}

final NotifierProvider<CrashGameNotifier, CrashUiState> crashGameProvider =
    NotifierProvider<CrashGameNotifier, CrashUiState>(CrashGameNotifier.new);
