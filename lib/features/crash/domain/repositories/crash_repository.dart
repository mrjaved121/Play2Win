import '../entities/crash_round.dart';

/// Gameplay boundary for Multiplier Climb. Unlike every other repository
/// in this app, this one has no local implementation — the crash point
/// and the payout math only exist server-side (blackhole_admin's
/// CrashRepository); this interface just names the network calls a
/// client is allowed to make.
abstract class CrashRepository {
  /// [accessToken], when signed in, makes the server resolve balance by
  /// account rather than this device's [guestId] — what makes balance
  /// portable across devices/reinstalls once linked. `playerId` is the
  /// canonical `players.id` row admin sees in the dashboard.
  Future<({int balance, String? playerId})> fetchBalance(String guestId, {String? accessToken});

  Future<CrashRoundResult> placeBet({
    required String guestId,
    required int betAmount,
    String? accessToken,
  });

  Future<CrashRoundResult> collect({
    required String guestId,
    required String roundId,
    String? accessToken,
  });

  /// Null if the server has no record of this round (e.g. a stale/replayed
  /// roundId) rather than an error, since "not found" is an expected
  /// outcome for a reconciliation check.
  Future<CrashRound?> fetchState({
    required String guestId,
    required String roundId,
    String? accessToken,
  });

  /// Adopts this device's guest balance into the signed-in account the
  /// first time it links (so signing up doesn't erase guest progress).
  /// Best-effort — callers should log failures and move on rather than
  /// block sign-in on them.
  Future<void> linkAccount({required String guestId, required String accessToken});

  /// This player's past resolved rounds, most recent first — replaces the
  /// old session-only in-memory history with the server's persisted log.
  Future<List<CrashHistoryEntry>> fetchHistory(String guestId, {String? accessToken});
}
