import 'dart:math' as math;

/// Mirrors the admin backend's `CrashRoundStatus`
/// (blackhole_admin/src/lib/types.ts).
enum CrashRoundStatus { pending, collected, crashed }

/// A round of Multiplier Climb as seen by the client. The server is the
/// only thing that knows [crashPoint]/[serverSeed] while [status] is
/// [CrashRoundStatus.pending] — see the admin backend's `CrashRepository`
/// doc comment for why. Both fields are only populated once the round
/// resolves, at which point they double as the provably-fair reveal:
/// anyone can confirm `sha256(serverSeed) == serverSeedHash` and that
/// re-deriving the crash point from `(serverSeed, roundId)` reproduces
/// [crashPoint].
class CrashRound {
  const CrashRound({
    required this.roundId,
    required this.status,
    required this.betAmount,
    required this.startedAt,
    required this.growthRate,
    required this.serverSeedHash,
    this.payout,
    this.resolvedMultiplier,
    this.crashPoint,
    this.serverSeed,
    this.voided = false,
  });

  final String roundId;
  final CrashRoundStatus status;
  final int betAmount;
  final DateTime startedAt;

  /// multiplier(t) = e^(growthRate * t) — server-supplied per round
  /// rather than a hardcoded client constant, so the client always
  /// matches whatever curve the server actually used to judge collects.
  final double growthRate;
  final String serverSeedHash;
  final int? payout;
  final double? resolvedMultiplier;
  final double? crashPoint;
  final String? serverSeed;

  /// True only for a round an admin ended via the emergency-stop "refund
  /// all" action — [status] is still [CrashRoundStatus.crashed] (never a
  /// win) but [payout] is the full bet back, not a genuine outcome. See
  /// the admin backend's `CrashRepository.emergencyStopAll`.
  final bool voided;

  /// What the climbing multiplier reads *right now*, purely from elapsed
  /// wall-clock time — this is what lets the UI render smoothly between
  /// network calls instead of polling every frame.
  double multiplierAt(DateTime now) {
    final double elapsedSeconds = now.difference(startedAt).inMilliseconds / 1000;
    return math.exp(growthRate * (elapsedSeconds < 0 ? 0 : elapsedSeconds));
  }

  factory CrashRound.fromJson(Map<String, dynamic> json) => CrashRound(
        roundId: json['roundId'] as String,
        status: CrashRoundStatus.values.byName(json['status'] as String),
        betAmount: (json['betAmount'] as num).toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        growthRate: (json['growthRate'] as num).toDouble(),
        serverSeedHash: json['serverSeedHash'] as String,
        payout: (json['payout'] as num?)?.toInt(),
        resolvedMultiplier: (json['resolvedMultiplier'] as num?)?.toDouble(),
        crashPoint: (json['crashPoint'] as num?)?.toDouble(),
        serverSeed: json['serverSeed'] as String?,
        voided: json['voided'] as bool? ?? false,
      );
}

/// The response shape every crash-game endpoint that mutates a round
/// returns: the round plus the player's balance after that action.
class CrashRoundResult {
  const CrashRoundResult({required this.round, required this.balance});

  final CrashRound round;
  final int balance;

  factory CrashRoundResult.fromJson(Map<String, dynamic> json) => CrashRoundResult(
        round: CrashRound.fromJson(json['round'] as Map<String, dynamic>),
        balance: (json['balance'] as num).toInt(),
      );
}

/// One resolved round from the player's server-side crash history — backs
/// the round history strip. Lighter than [CrashRound]: history only needs
/// the outcome, not the full pending-round shape (growthRate, seed hash, ...).
class CrashHistoryEntry {
  const CrashHistoryEntry({
    required this.roundId,
    required this.bet,
    required this.multiplier,
    required this.crashPoint,
    required this.winAmount,
    required this.isWin,
    required this.timestamp,
    this.voided = false,
  });

  final String roundId;
  final int bet;

  /// The multiplier actually cashed out at — only meaningful when [isWin]
  /// (a lost round never cashed out, so this equals [crashPoint] server-side
  /// rather than a real "odds achieved").
  final double multiplier;

  /// Where this round actually busted, win or lose — always populated.
  final double crashPoint;
  final int winAmount;
  final bool isWin;
  final DateTime timestamp;

  /// See [CrashRound.voided] — an admin-refunded round, not a real win or loss.
  final bool voided;

  factory CrashHistoryEntry.fromJson(Map<String, dynamic> json) => CrashHistoryEntry(
        roundId: json['roundId'] as String,
        bet: (json['bet'] as num).toInt(),
        multiplier: (json['multiplier'] as num).toDouble(),
        crashPoint: (json['crashPoint'] as num).toDouble(),
        winAmount: (json['winAmount'] as num).toInt(),
        isWin: json['isWin'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
        voided: json['voided'] as bool? ?? false,
      );
}
