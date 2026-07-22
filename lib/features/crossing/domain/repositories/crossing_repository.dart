import '../entities/crossing_round.dart';

/// Gameplay boundary for Multiplier Crossing. Like Multiplier Climb, the
/// per-lane bust/survive draw and the payout math only exist server-side
/// (blackhole_admin's CrossingRepository); this interface just names the
/// network calls a client is allowed to make. Unlike crash's single
/// `collect()`, a round here advances one lane at a time via [advance] —
/// each lane's outcome must stay hidden until the server reveals it, so
/// there's no client-side equivalent of crash's locally-rendered
/// continuous multiplier.
abstract class CrossingRepository {
  /// [accessToken], when signed in, makes the server resolve balance by
  /// account rather than this device's [guestId] — what makes balance
  /// portable across devices/reinstalls once linked. `playerId` is the
  /// canonical `players.id` row admin sees in the dashboard.
  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken});

  /// Rejects if this player already has a pending round — unlike crash,
  /// there's no "join an existing flight" concept, only one round in
  /// flight per player at a time.
  Future<CrossingRoundResult> placeBet({
    required String guestId,
    required int betAmount,
    required CrossingDifficulty difficulty,
    required String clientSeed,
    String? accessToken,
  });

  /// Reveals the outcome of exactly one lane (`currentLane + 1`).
  Future<CrossingRoundResult> advance({
    required String guestId,
    required String roundId,
    String? accessToken,
  });

  /// Cashes out at the current lane's multiplier. Requires currentLane >= 1.
  Future<CrossingRoundResult> cashout({
    required String guestId,
    required String roundId,
    String? accessToken,
  });

  /// Null if the server has no record of this round (e.g. a stale/replayed
  /// roundId) rather than an error, since "not found" is an expected
  /// outcome for a reconciliation check.
  Future<CrossingRound?> fetchState({
    required String guestId,
    required String roundId,
    String? accessToken,
  });

  /// Adopts this device's guest balance into the signed-in account the
  /// first time it links (so signing up doesn't erase guest progress).
  /// Best-effort — callers should log failures and move on rather than
  /// block sign-in on them.
  Future<void> linkAccount({required String guestId, required String accessToken});

  /// This player's past resolved rounds, most recent first.
  Future<List<CrossingHistoryEntry>> fetchHistory(String guestId, {String? accessToken});
}
