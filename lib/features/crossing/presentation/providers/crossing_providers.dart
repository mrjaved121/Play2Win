import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/di/guest_identity_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/crossing_api_client.dart';
import '../../data/repositories/http_crossing_repository.dart';
import '../../domain/crossing_constants.dart';
import '../../domain/entities/crossing_round.dart';
import '../../domain/repositories/crossing_repository.dart';

final Provider<CrossingApiClient> crossingApiClientProvider = Provider<CrossingApiClient>(
  (Ref ref) => CrossingApiClient(),
);

final Provider<CrossingRepository> crossingRepositoryProvider = Provider<CrossingRepository>(
  (Ref ref) => HttpCrossingRepository(ref.watch(crossingApiClientProvider)),
);

enum CrossingPhase { idle, running, resolved }

/// Stable per-install client seed for the provably-fair reveal — separate
/// from [guestIdProvider] (which identifies the *player*; this identifies
/// the *seed* half of the HMAC draw, see blackhole_admin's
/// `isLaneBust`). Persisted so it survives app restarts, but rotatable via
/// [CrossingClientSeedNotifier.regenerate] — the "Provably fair settings"
/// panel exposes this the same way the reference UI shows a "your seed"
/// field.
class CrossingClientSeedNotifier extends Notifier<String> {
  static const String _key = 'crossing_client_seed';

  @override
  String build() {
    final StorageService storage = getIt<StorageService>();
    final String? existing = storage.get<String>(_key);
    if (existing != null) return existing;
    final String created = const Uuid().v4().replaceAll('-', '').substring(0, 16);
    unawaited(storage.put<String>(_key, created));
    return created;
  }

  void regenerate() {
    final String created = const Uuid().v4().replaceAll('-', '').substring(0, 16);
    unawaited(getIt<StorageService>().put<String>(_key, created));
    state = created;
  }

  /// Lets the player set their own seed directly (the "Provably fair
  /// settings" panel's editable field) rather than only randomizing —
  /// takes effect on the next bet placed, never an in-flight round's
  /// already-fixed seed.
  void setSeed(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return;
    unawaited(getIt<StorageService>().put<String>(_key, trimmed));
    state = trimmed;
  }
}

final NotifierProvider<CrossingClientSeedNotifier, String> crossingClientSeedProvider =
    NotifierProvider<CrossingClientSeedNotifier, String>(CrossingClientSeedNotifier.new);

// ---------------------------------------------------------------------
// Shared state — balance, history, session tally, and live settings
// (min/max/maxWin bet + the public per-difficulty payout ladder). Mirrors
// CrashSharedState; there's only one bet panel here (not two), but this
// stays a separate notifier from the game state for the same reason
// crash's does: balance/history persist across rounds, game state resets
// every round.
// ---------------------------------------------------------------------

class DifficultyInfo {
  const DifficultyInfo({required this.laneCount, required this.bustPct, required this.ladder});

  final int laneCount;
  final double bustPct;
  final List<double> ladder;

  factory DifficultyInfo.fromJson(Map<String, dynamic> json) => DifficultyInfo(
        laneCount: (json['laneCount'] as num).toInt(),
        bustPct: (json['bustPct'] as num).toDouble(),
        ladder: (json['ladder'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(growable: false),
      );
}

const Map<CrossingDifficulty, DifficultyInfo> _fallbackDifficulties = <CrossingDifficulty, DifficultyInfo>{
  CrossingDifficulty.easy: DifficultyInfo(laneCount: 30, bustPct: 6, ladder: <double>[]),
  CrossingDifficulty.medium: DifficultyInfo(laneCount: 25, bustPct: 9, ladder: <double>[]),
  CrossingDifficulty.hard: DifficultyInfo(laneCount: 22, bustPct: 13, ladder: <double>[]),
  CrossingDifficulty.hardcore: DifficultyInfo(laneCount: 18, bustPct: 20, ladder: <double>[]),
};

class CrossingSharedState {
  const CrossingSharedState({
    this.balance,
    this.playerId,
    this.balanceLoading = true,
    this.history = const <CrossingHistoryEntry>[],
    this.sessionRoundsCount = 0,
    this.sessionTotalBet = 0,
    this.sessionTotalWinnings = 0,
    this.minBet = CrossingConstants.minBet,
    this.maxBet = CrossingConstants.maxBet,
    this.maxWin = CrossingConstants.maxWin,
    this.difficulties = _fallbackDifficulties,
  });

  final int? balance;

  /// The canonical `players.id` row admin sees in the dashboard — distinct
  /// from [guestIdProvider]'s value. Null until the first successful
  /// balance fetch.
  final String? playerId;
  final bool balanceLoading;

  /// Past resolved rounds, most recent first — seeded from the server on
  /// load, then this session's own rounds are prepended locally as they
  /// resolve. Capped at [CrossingConstants.historyLimit].
  final List<CrossingHistoryEntry> history;

  final int sessionRoundsCount;
  final int sessionTotalBet;
  final int sessionTotalWinnings;

  /// Live-fetched from admin settings (see [_loadSettings]) —
  /// [CrossingConstants] fields are only the pre-fetch/fetch-failed
  /// fallback, not a ceiling the server actually enforces.
  final int minBet;
  final int maxBet;
  final int maxWin;

  /// Per-difficulty lane count + full payout ladder — public, no secret
  /// involved (see CrossingRound's doc comment), so this can be shown in
  /// the difficulty picker before the player bets.
  final Map<CrossingDifficulty, DifficultyInfo> difficulties;

  int get sessionNet => sessionTotalWinnings - sessionTotalBet;

  CrossingSharedState copyWith({
    int? balance,
    String? playerId,
    bool? balanceLoading,
    List<CrossingHistoryEntry>? history,
    int? sessionRoundsCount,
    int? sessionTotalBet,
    int? sessionTotalWinnings,
    int? minBet,
    int? maxBet,
    int? maxWin,
    Map<CrossingDifficulty, DifficultyInfo>? difficulties,
  }) {
    return CrossingSharedState(
      balance: balance ?? this.balance,
      playerId: playerId ?? this.playerId,
      balanceLoading: balanceLoading ?? this.balanceLoading,
      history: history ?? this.history,
      sessionRoundsCount: sessionRoundsCount ?? this.sessionRoundsCount,
      sessionTotalBet: sessionTotalBet ?? this.sessionTotalBet,
      sessionTotalWinnings: sessionTotalWinnings ?? this.sessionTotalWinnings,
      minBet: minBet ?? this.minBet,
      maxBet: maxBet ?? this.maxBet,
      maxWin: maxWin ?? this.maxWin,
      difficulties: difficulties ?? this.difficulties,
    );
  }
}

class CrossingSharedNotifier extends Notifier<CrossingSharedState> {
  @override
  CrossingSharedState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_loadBalance());
      unawaited(_loadHistory());
      unawaited(_loadSettings());
    }
    return CrossingSharedState(balanceLoading: ApiConfig.isConfigured);
  }

  String get _guestId => ref.read(guestIdProvider);
  CrossingRepository get _repo => ref.read(crossingRepositoryProvider);
  String? get _accessToken => ref.read(authRepositoryProvider)?.accessToken;

  Future<void> _loadBalance() async {
    try {
      final ({int balance, String? playerId}) result = await _repo.fetchBalance(_guestId, accessToken: _accessToken);
      state = state.copyWith(balance: result.balance, playerId: result.playerId, balanceLoading: false);
    } catch (_) {
      state = state.copyWith(balanceLoading: false);
    }
  }

  /// Best-effort — an empty history strip on failure is a fine fallback,
  /// not worth surfacing as a user-facing error.
  Future<void> _loadHistory() async {
    try {
      final List<CrossingHistoryEntry> history = await _repo.fetchHistory(_guestId, accessToken: _accessToken);
      state = state.copyWith(history: history);
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  /// Best-effort, same as [_loadHistory] — a fetch failure just leaves the
  /// static [CrossingConstants] defaults in place, which the server
  /// enforces independently regardless of whether this ever completes.
  Future<void> _loadSettings() async {
    try {
      final Map<String, dynamic> json = await ref.read(crossingApiClientProvider).fetchSettings();
      final Map<String, dynamic> rawDifficulties = json['difficulties'] as Map<String, dynamic>;
      final Map<CrossingDifficulty, DifficultyInfo> difficulties = <CrossingDifficulty, DifficultyInfo>{
        for (final CrossingDifficulty d in CrossingDifficulty.values)
          d: DifficultyInfo.fromJson(rawDifficulties[d.name] as Map<String, dynamic>),
      };
      state = state.copyWith(
        minBet: (json['minBet'] as num).toInt(),
        maxBet: (json['maxBet'] as num).toInt(),
        maxWin: (json['maxWin'] as num).toInt(),
        difficulties: difficulties,
      );
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  void applyBalance(int balance) => state = state.copyWith(balance: balance);

  void prependHistory(CrossingHistoryEntry entry) {
    state = state.copyWith(
      history: <CrossingHistoryEntry>[entry, ...state.history].take(CrossingConstants.historyLimit).toList(),
    );
  }

  void recordRound(int betAmount) {
    state = state.copyWith(
      sessionRoundsCount: state.sessionRoundsCount + 1,
      sessionTotalBet: state.sessionTotalBet + betAmount,
    );
  }

  void recordWinnings(int amount) {
    if (amount == 0) return;
    state = state.copyWith(sessionTotalWinnings: state.sessionTotalWinnings + amount);
  }
}

final NotifierProvider<CrossingSharedNotifier, CrossingSharedState> crossingSharedProvider =
    NotifierProvider<CrossingSharedNotifier, CrossingSharedState>(CrossingSharedNotifier.new);

// ---------------------------------------------------------------------
// Game state — a single round in flight. Unlike crash, there's only ever
// one panel and no shared "flight": placeBet rejects outright if this
// player already has a pending round server-side. There's also no
// client-rendered continuous multiplier to tick — the displayed
// multiplier only changes in response to an explicit advance()/cashout()
// server round-trip, since each lane's outcome must stay hidden until
// the server reveals it.
// ---------------------------------------------------------------------

class CrossingGameState {
  const CrossingGameState({
    this.phase = CrossingPhase.idle,
    this.difficulty = CrossingDifficulty.easy,
    this.bet = CrossingConstants.defaultBet,
    this.round,
    this.errorMessage,
    this.busy = false,
    this.justBusted = false,
  });

  final CrossingPhase phase;
  final CrossingDifficulty difficulty;
  final int bet;
  final CrossingRound? round;
  final String? errorMessage;
  final bool busy;

  /// One-shot flag: true for the single state emission right after a bust,
  /// so the UI can play a "hit" animation exactly once instead of on every
  /// rebuild while resolved.
  final bool justBusted;

  bool canAfford(int? balance) => balance == null || balance >= bet;

  CrossingGameState copyWith({
    CrossingPhase? phase,
    CrossingDifficulty? difficulty,
    int? bet,
    CrossingRound? round,
    bool clearRound = false,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    bool? justBusted,
  }) {
    return CrossingGameState(
      phase: phase ?? this.phase,
      difficulty: difficulty ?? this.difficulty,
      bet: bet ?? this.bet,
      round: clearRound ? null : (round ?? this.round),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      justBusted: justBusted ?? false,
    );
  }
}

class CrossingGameNotifier extends Notifier<CrossingGameState> {
  @override
  CrossingGameState build() => const CrossingGameState();

  String get _guestId => ref.read(guestIdProvider);
  CrossingRepository get _repo => ref.read(crossingRepositoryProvider);
  String? get _accessToken => ref.read(authRepositoryProvider)?.accessToken;
  CrossingSharedNotifier get _shared => ref.read(crossingSharedProvider.notifier);
  int? get _balance => ref.read(crossingSharedProvider).balance;

  /// Sets the bet — from a [CrossingConstants.quickBetPresets] tap or
  /// free-text entry alike. Only while idle: changing the stake mid-round
  /// would retroactively change what's already at risk.
  void setBet(int amount) {
    if (state.phase != CrossingPhase.idle) return;
    final CrossingSharedState shared = ref.read(crossingSharedProvider);
    state = state.copyWith(bet: amount.clamp(shared.minBet, shared.maxBet));
  }

  void setDifficulty(CrossingDifficulty difficulty) {
    if (state.phase != CrossingPhase.idle) return;
    state = state.copyWith(difficulty: difficulty);
  }

  Future<void> placeBet() async {
    if (state.busy || state.phase == CrossingPhase.running) return;
    if (!state.canAfford(_balance)) {
      state = state.copyWith(errorMessage: 'Not enough balance for this bet.');
      return;
    }
    final int betAmount = state.bet;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final CrossingRoundResult result = await _repo.placeBet(
        guestId: _guestId,
        betAmount: betAmount,
        difficulty: state.difficulty,
        clientSeed: ref.read(crossingClientSeedProvider),
        accessToken: _accessToken,
      );
      state = state.copyWith(phase: CrossingPhase.running, round: result.round, busy: false);
      _shared.applyBalance(result.balance);
      _shared.recordRound(betAmount);
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
    }
  }

  /// Reveals the outcome of the next lane. On bust, the round resolves as
  /// a loss and [CrossingGameState.justBusted] flips on for one emission.
  /// On survival, either the lane count advances (still running) or — on
  /// the final lane — the server auto-resolves as a win.
  Future<void> advance() async {
    final CrossingRound? round = state.round;
    if (round == null || state.busy || state.phase != CrossingPhase.running) return;
    state = state.copyWith(busy: true);
    try {
      final CrossingRoundResult result = await _repo.advance(
        guestId: _guestId,
        roundId: round.roundId,
        accessToken: _accessToken,
      );
      final bool busted = result.round.status == CrossingRoundStatus.busted;
      final bool resolved = result.round.status != CrossingRoundStatus.pending;
      state = state.copyWith(
        phase: resolved ? CrossingPhase.resolved : CrossingPhase.running,
        round: result.round,
        busy: false,
        justBusted: busted,
      );
      _shared.applyBalance(result.balance);
      if (resolved) {
        _shared.prependHistory(_toHistoryEntry(result.round));
        _shared.recordWinnings(result.round.payout ?? 0);
        _playSfx(busted ? SfxType.crash : ((result.round.resolvedMultiplier ?? 1.0) >= 5.0 ? SfxType.bigWin : SfxType.win));
      }
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
    }
  }

  Future<void> cashout() async {
    final CrossingRound? round = state.round;
    if (round == null || state.busy || !state.round!.canCashOut) return;
    state = state.copyWith(busy: true);
    try {
      final CrossingRoundResult result = await _repo.cashout(
        guestId: _guestId,
        roundId: round.roundId,
        accessToken: _accessToken,
      );
      state = state.copyWith(phase: CrossingPhase.resolved, round: result.round, busy: false);
      _shared.applyBalance(result.balance);
      _shared.prependHistory(_toHistoryEntry(result.round));
      _shared.recordWinnings(result.round.payout ?? 0);
      _playSfx((result.round.resolvedMultiplier ?? 1.0) >= 5.0 ? SfxType.bigWin : SfxType.win);
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
    }
  }

  /// Clears the resolved round so the player can set a new bet/difficulty
  /// and play again.
  void startNewRound() {
    state = state.copyWith(phase: CrossingPhase.idle, clearRound: true, clearError: true);
  }

  CrossingHistoryEntry _toHistoryEntry(CrossingRound round) {
    return CrossingHistoryEntry(
      roundId: round.roundId,
      bet: round.betAmount,
      difficulty: round.difficulty,
      lanesCleared: round.currentLane,
      multiplier: round.resolvedMultiplier ?? 0,
      winAmount: round.payout ?? 0,
      isWin: round.status == CrossingRoundStatus.collected,
      timestamp: DateTime.now(),
    );
  }

  String _friendlyError(Object error) {
    if (error is CrossingApiException) return error.message;
    return "Can't reach the game server";
  }

  void _playSfx(SfxType type) {
    if (getIt.isRegistered<AudioService>()) {
      unawaited(getIt<AudioService>().playSfx(type));
    }
  }
}

final NotifierProvider<CrossingGameNotifier, CrossingGameState> crossingGameProvider =
    NotifierProvider<CrossingGameNotifier, CrossingGameState>(CrossingGameNotifier.new);
