import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/di/guest_identity_provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
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

enum CrashPhase { idle, running, resolved }

// ---------------------------------------------------------------------
// Shared state — balance, history, and combined session tally. These
// aren't per-bet-panel: both panels spend the same balance and feed one
// combined history/tally, since they're the same player's money
// regardless of which panel placed a given bet. (Two panels sharing one
// *flight*/crash-point is a server-side concept — see
// blackhole_admin's `findJoinableRound` — this layer only holds what's
// cross-panel on the client.)
// ---------------------------------------------------------------------

class CrashSharedState {
  const CrashSharedState({
    this.balance,
    this.playerId,
    this.balanceLoading = true,
    this.history = const <CrashHistoryEntry>[],
    this.sessionBetsCount = 0,
    this.sessionTotalBet = 0,
    this.sessionTotalWinnings = 0,
    this.minBet = CrashConstants.minBet,
    this.maxBet = CrashConstants.maxBet,
  });

  final int? balance;

  /// The canonical `players.id` row admin sees in the dashboard — distinct
  /// from [guestIdProvider]'s value, which is only this device's
  /// local lookup key. Null until the first successful balance fetch.
  final String? playerId;
  final bool balanceLoading;

  /// Past resolved rounds from either panel, most recent first — the small
  /// crash-history strip real crash games show so a player can eyeball how
  /// "hot" or "cold" recent rounds have been. Seeded from the server on
  /// load, then this session's own rounds are prepended locally as they
  /// resolve. Capped at [CrashConstants.historyLimit] — unlike the session
  /// totals below, this is a display list, not a running counter.
  final List<CrashHistoryEntry> history;

  /// This session's own tally across both panels combined — separate from
  /// (and not truncated like) [history], so "Number of bets"/"Total
  /// bets"/"Total winnings" stay accurate for the whole session even past
  /// [CrashConstants.historyLimit] rounds.
  final int sessionBetsCount;
  final int sessionTotalBet;
  final int sessionTotalWinnings;

  /// Live-fetched from admin settings (see [CrashSharedNotifier._loadSettings])
  /// — [CrashConstants.minBet]/[maxBet] are only the pre-fetch/fetch-failed
  /// fallback, not a ceiling the server actually enforces.
  final int minBet;
  final int maxBet;

  int get sessionNet => sessionTotalWinnings - sessionTotalBet;

  CrashSharedState copyWith({
    int? balance,
    String? playerId,
    bool? balanceLoading,
    List<CrashHistoryEntry>? history,
    int? sessionBetsCount,
    int? sessionTotalBet,
    int? sessionTotalWinnings,
    int? minBet,
    int? maxBet,
  }) {
    return CrashSharedState(
      balance: balance ?? this.balance,
      playerId: playerId ?? this.playerId,
      balanceLoading: balanceLoading ?? this.balanceLoading,
      history: history ?? this.history,
      sessionBetsCount: sessionBetsCount ?? this.sessionBetsCount,
      sessionTotalBet: sessionTotalBet ?? this.sessionTotalBet,
      sessionTotalWinnings: sessionTotalWinnings ?? this.sessionTotalWinnings,
      minBet: minBet ?? this.minBet,
      maxBet: maxBet ?? this.maxBet,
    );
  }
}

class CrashSharedNotifier extends Notifier<CrashSharedState> {
  @override
  CrashSharedState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_loadBalance());
      unawaited(_loadHistory());
      unawaited(_loadSettings());
    }
    return CrashSharedState(balanceLoading: ApiConfig.isConfigured);
  }

  String get _guestId => ref.read(guestIdProvider);
  CrashRepository get _repo => ref.read(crashRepositoryProvider);
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
      final List<CrashHistoryEntry> history = await _repo.fetchHistory(_guestId, accessToken: _accessToken);
      state = state.copyWith(history: history);
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  /// Best-effort, same as [_loadHistory] — a fetch failure just leaves the
  /// static [CrashConstants] defaults in place, which the server enforces
  /// independently regardless of whether this ever completes.
  Future<void> _loadSettings() async {
    try {
      final Map<String, dynamic> json = await ref.read(crashApiClientProvider).fetchSettings();
      state = state.copyWith(minBet: (json['minBet'] as num).toInt(), maxBet: (json['maxBet'] as num).toInt());
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  void applyBalance(int balance) => state = state.copyWith(balance: balance);

  void prependHistory(CrashHistoryEntry entry) {
    state = state.copyWith(
      history: <CrashHistoryEntry>[entry, ...state.history].take(CrashConstants.historyLimit).toList(),
    );
  }

  void recordBet(int amount) {
    state = state.copyWith(
      sessionBetsCount: state.sessionBetsCount + 1,
      sessionTotalBet: state.sessionTotalBet + amount,
    );
  }

  void recordWinnings(int amount) {
    if (amount == 0) return;
    state = state.copyWith(sessionTotalWinnings: state.sessionTotalWinnings + amount);
  }
}

final NotifierProvider<CrashSharedNotifier, CrashSharedState> crashSharedProvider =
    NotifierProvider<CrashSharedNotifier, CrashSharedState>(CrashSharedNotifier.new);

// ---------------------------------------------------------------------
// Per-panel state — one independent bet "slot". Two bets sharing a
// flight (same crash point) is decided entirely server-side (see
// blackhole_admin's `findJoinableRound`) — this notifier doesn't need to
// know about the other slot at all, it just places/collects bets exactly
// like a single-panel game would, and the shared-flight behavior emerges
// automatically whenever the server chooses to join one.
// ---------------------------------------------------------------------

enum CrashSlotId { slot1, slot2 }

class CrashSlotState {
  const CrashSlotState({
    this.phase = CrashPhase.idle,
    this.bet = CrashConstants.defaultBet,
    this.round,
    this.displayMultiplier = 1.0,
    this.errorMessage,
    this.busy = false,
    this.autoplayEnabled = false,
    this.autoplayRoundsRemaining,
    this.autoplayStopOnProfit,
    this.autoplayStopOnLoss,
    this.autoplayBaselineNet = 0,
    this.autoCashoutMultiplier,
  });

  final CrashPhase phase;
  final int bet;
  final CrashRound? round;
  final double displayMultiplier;
  final String? errorMessage;
  final bool busy;

  final bool autoplayEnabled;

  /// Rounds left before autoplay auto-disables itself. Null means "no
  /// limit configured" (runs until toggled off or the player can't afford
  /// the bet).
  final int? autoplayRoundsRemaining;

  /// Optional autoplay stop conditions, in PKR net profit/loss *since
  /// autoplay was last enabled* (see [autoplayBaselineNet]), measured
  /// against the shared session net (both panels combined) — not an
  /// isolated per-panel P&L.
  final int? autoplayStopOnProfit;
  final int? autoplayStopOnLoss;

  /// The shared session's net (winnings - bet) at the moment autoplay was
  /// last enabled for *this* panel.
  final int autoplayBaselineNet;

  /// Multiplier this panel auto-collects at once the live multiplier
  /// reaches it. Null means manual cash-out only (the default).
  final double? autoCashoutMultiplier;

  bool canAfford(int? balance) => balance == null || balance >= bet;

  CrashSlotState copyWith({
    CrashPhase? phase,
    int? bet,
    CrashRound? round,
    bool clearRound = false,
    double? displayMultiplier,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    bool? autoplayEnabled,
    int? autoplayRoundsRemaining,
    bool clearAutoplayRounds = false,
    int? autoplayStopOnProfit,
    bool clearAutoplayStopOnProfit = false,
    int? autoplayStopOnLoss,
    bool clearAutoplayStopOnLoss = false,
    int? autoplayBaselineNet,
    double? autoCashoutMultiplier,
    bool clearAutoCashout = false,
  }) {
    return CrashSlotState(
      phase: phase ?? this.phase,
      bet: bet ?? this.bet,
      round: clearRound ? null : (round ?? this.round),
      displayMultiplier: displayMultiplier ?? this.displayMultiplier,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      autoplayEnabled: autoplayEnabled ?? this.autoplayEnabled,
      autoplayRoundsRemaining:
          clearAutoplayRounds ? null : (autoplayRoundsRemaining ?? this.autoplayRoundsRemaining),
      autoplayStopOnProfit:
          clearAutoplayStopOnProfit ? null : (autoplayStopOnProfit ?? this.autoplayStopOnProfit),
      autoplayStopOnLoss: clearAutoplayStopOnLoss ? null : (autoplayStopOnLoss ?? this.autoplayStopOnLoss),
      autoplayBaselineNet: autoplayBaselineNet ?? this.autoplayBaselineNet,
      autoCashoutMultiplier: clearAutoCashout ? null : (autoCashoutMultiplier ?? this.autoCashoutMultiplier),
    );
  }
}

/// Drives one independent bet panel. See [CrashSlotState] for what's
/// tracked per-panel vs [CrashSharedState] for what's shared (balance/
/// history/session tally). The multiplier shown while [CrashPhase.running]
/// is rendered *locally* (see [_startRoundTimers]) from the round's
/// `startedAt`/`growthRate`; a slower reconciliation poll separately
/// checks the server so the player is told when a round crashed even if
/// they never tap Collect.
///
/// Riverpod 3's family notifiers are plain [Notifier]s whose constructor
/// captures the family argument (`FamilyNotifier` was removed) — [slotId]
/// isn't currently read by any logic here, since placing/collecting a bet
/// is identical regardless of which panel initiated it, but it's kept for
/// future debugging/logging.
class CrashSlotNotifier extends Notifier<CrashSlotState> {
  CrashSlotNotifier(this.slotId);

  final CrashSlotId slotId;

  Timer? _renderTicker;
  Timer? _reconciliationTicker;

  /// Delay before autoplay fires the next bet after a round resolves, so
  /// the player has a moment to see the result — see [_continueAutoplay].
  static const Duration _autoplayDelay = Duration(milliseconds: 1500);
  Timer? _autoplayTimer;

  @override
  CrashSlotState build() {
    ref.onDispose(() {
      _renderTicker?.cancel();
      _reconciliationTicker?.cancel();
      _autoplayTimer?.cancel();
    });
    return const CrashSlotState();
  }

  String get _guestId => ref.read(guestIdProvider);
  CrashRepository get _repo => ref.read(crashRepositoryProvider);

  /// Sent with every request so a signed-in player's balance resolves by
  /// account instead of this device's guestId — see
  /// blackhole_admin's CrashRepository.resolvePlayer. Read fresh each call
  /// (not cached at login) since sessions can refresh or expire.
  String? get _accessToken => ref.read(authRepositoryProvider)?.accessToken;

  CrashSharedNotifier get _shared => ref.read(crashSharedProvider.notifier);
  int? get _balance => ref.read(crashSharedProvider).balance;

  /// Sets the bet directly — from a [CrashConstants.quickBetPresets] tap
  /// or free-text entry alike.
  void setBet(int amount) {
    if (state.phase != CrashPhase.idle) return;
    final CrashSharedState shared = ref.read(crashSharedProvider);
    state = state.copyWith(bet: amount.clamp(shared.minBet, shared.maxBet));
  }

  /// `null` means manual cash-out only (the default).
  void setAutoCashout(double? multiplier) {
    if (multiplier == null) {
      state = state.copyWith(clearAutoCashout: true);
    } else {
      state = state.copyWith(autoCashoutMultiplier: multiplier);
    }
  }

  /// Enables/disables autoplay. When enabling while idle, immediately
  /// places the first bet. [maxRounds] null means "until turned off";
  /// [stopOnProfit]/[stopOnLoss] (in PKR, measured from the moment autoplay
  /// is enabled) are additional optional stop conditions.
  void setAutoplay({required bool enabled, int? maxRounds, int? stopOnProfit, int? stopOnLoss}) {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    if (!enabled) {
      state = state.copyWith(
        autoplayEnabled: false,
        clearAutoplayRounds: true,
        clearAutoplayStopOnProfit: true,
        clearAutoplayStopOnLoss: true,
      );
      return;
    }
    state = state.copyWith(
      autoplayEnabled: true,
      autoplayRoundsRemaining: maxRounds,
      clearAutoplayRounds: maxRounds == null,
      autoplayStopOnProfit: stopOnProfit,
      clearAutoplayStopOnProfit: stopOnProfit == null,
      autoplayStopOnLoss: stopOnLoss,
      clearAutoplayStopOnLoss: stopOnLoss == null,
      autoplayBaselineNet: ref.read(crashSharedProvider).sessionNet,
    );
    if (state.phase == CrashPhase.idle && state.canAfford(_balance)) placeBet();
  }

  Future<void> placeBet() async {
    if (state.busy || state.phase == CrashPhase.running) return;
    if (!state.canAfford(_balance)) {
      setAutoplay(enabled: false);
      return;
    }
    final int betAmount = state.bet;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final CrashRoundResult result = await _repo.placeBet(
        guestId: _guestId,
        betAmount: betAmount,
        accessToken: _accessToken,
      );
      state = state.copyWith(
        phase: CrashPhase.running,
        round: result.round,
        displayMultiplier: 1.0,
        busy: false,
      );
      _shared.applyBalance(result.balance);
      _shared.recordBet(betAmount);
      _startRoundTimers();
    } catch (error) {
      state = state.copyWith(busy: false, errorMessage: _friendlyError(error));
      setAutoplay(enabled: false);
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
        displayMultiplier: result.round.resolvedMultiplier ?? result.round.crashPoint ?? state.displayMultiplier,
        busy: false,
      );
      _shared.applyBalance(result.balance);
      _shared.prependHistory(_toHistoryEntry(result.round));
      _shared.recordWinnings(result.round.payout ?? 0);
      _playSfx((result.round.resolvedMultiplier ?? 1.0) >= 5.0 ? SfxType.bigWin : SfxType.win);
      _continueAutoplay();
    } catch (error) {
      // The server has no record of this round at all (as opposed to any
      // other failure, e.g. a network hiccup, which stays retryable) —
      // there's no outcome left to recover, so stop climbing forever with
      // no way out. See _pollForCrash's identical case for how this round
      // could go missing server-side in the first place.
      if (error is CrashApiException && error.message == _roundNotFoundMessage) {
        _abandonUnrecoverableRound();
        return;
      }
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
      final double multiplier = round.multiplierAt(DateTime.now());
      state = state.copyWith(displayMultiplier: multiplier);
      final double? target = state.autoCashoutMultiplier;
      if (target != null && multiplier >= target && !state.busy && state.phase == CrashPhase.running) {
        collect();
      }
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
  /// Collect" — network-level failures here are silently ignored (next
  /// tick retries) rather than surfaced as a user-facing error, since this
  /// is a background reconciliation, not something the player asked for.
  /// A confirmed 404 (`latest == null`, see [CrashRepository.fetchState]'s
  /// doc comment) is different: the server has no record of this round at
  /// all — never a transient/expected state for a round this client just
  /// started and is actively polling — so retrying forever would just
  /// leave the multiplier climbing with nothing that can ever stop it.
  Future<void> _pollForCrash() async {
    final CrashRound? round = state.round;
    if (round == null || state.phase != CrashPhase.running) return;
    try {
      final CrashRound? latest = await _repo.fetchState(
        guestId: _guestId,
        roundId: round.roundId,
        accessToken: _accessToken,
      );
      if (latest == null) {
        _abandonUnrecoverableRound();
        return;
      }
      if (latest.status == CrashRoundStatus.crashed) {
        _stopRoundTimers();
        state = state.copyWith(
          phase: CrashPhase.resolved,
          round: latest,
          displayMultiplier: latest.crashPoint ?? state.displayMultiplier,
        );
        _shared.prependHistory(_toHistoryEntry(latest));
        _playSfx(SfxType.crash);
        _continueAutoplay();
      }
    } catch (_) {
      // Ignored — see doc comment.
    }
  }

  static const String _roundNotFoundMessage = 'Round not found';

  /// Stops the round outright when the server has no record of it — its
  /// real win/loss outcome is unknowable at this point (not a loss, not a
  /// win), so this neither pays out nor charges anything further; the bet
  /// itself was already deducted up front when it was placed. Also cancels
  /// autoplay, since blindly re-betting into whatever broke this round
  /// would just repeat the problem.
  void _abandonUnrecoverableRound() {
    _stopRoundTimers();
    state = state.copyWith(
      phase: CrashPhase.idle,
      clearRound: true,
      displayMultiplier: 1.0,
      busy: false,
      errorMessage: 'Lost track of that round — it may have been interrupted server-side. Place a new bet to continue.',
    );
    setAutoplay(enabled: false);
  }

  /// Builds an optimistic history entry from a just-resolved round, so the
  /// strip updates immediately instead of waiting for the next app launch's
  /// history fetch to pick it up from the server.
  CrashHistoryEntry _toHistoryEntry(CrashRound round) {
    final double crashPoint = round.crashPoint ?? round.resolvedMultiplier ?? 1.0;
    return CrashHistoryEntry(
      roundId: round.roundId,
      bet: round.betAmount,
      multiplier: round.resolvedMultiplier ?? crashPoint,
      crashPoint: crashPoint,
      winAmount: round.payout ?? 0,
      isWin: round.status == CrashRoundStatus.collected,
      timestamp: DateTime.now(),
    );
  }

  /// Called right after a round resolves (won or crashed). If autoplay is
  /// on, waits [_autoplayDelay] so the player sees the result, decrements
  /// the round budget, then either fires the next bet or auto-disables
  /// once the budget/stop-condition/balance runs out.
  void _continueAutoplay() {
    if (!state.autoplayEnabled) return;
    final int netSinceEnabled = ref.read(crashSharedProvider).sessionNet - state.autoplayBaselineNet;
    final int? stopOnProfit = state.autoplayStopOnProfit;
    final int? stopOnLoss = state.autoplayStopOnLoss;
    if ((stopOnProfit != null && netSinceEnabled >= stopOnProfit) ||
        (stopOnLoss != null && netSinceEnabled <= -stopOnLoss)) {
      setAutoplay(enabled: false);
      return;
    }
    final int? remaining = state.autoplayRoundsRemaining;
    if (remaining != null && remaining <= 1) {
      setAutoplay(enabled: false);
      return;
    }
    state = state.copyWith(
      autoplayRoundsRemaining: remaining != null ? remaining - 1 : null,
      clearAutoplayRounds: remaining == null,
    );
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer(_autoplayDelay, () {
      if (!state.autoplayEnabled) return;
      startNewRound();
      if (state.canAfford(_balance)) {
        placeBet();
      } else {
        setAutoplay(enabled: false);
      }
    });
  }

  String _friendlyError(Object error) {
    if (error is CrashApiException) return error.message;
    return "Can't reach the game server";
  }

  void _playSfx(SfxType type) {
    if (getIt.isRegistered<AudioService>()) {
      unawaited(getIt<AudioService>().playSfx(type));
    }
  }
}

final crashSlotProvider = NotifierProvider.family<CrashSlotNotifier, CrashSlotState, CrashSlotId>(
  CrashSlotNotifier.new,
);
