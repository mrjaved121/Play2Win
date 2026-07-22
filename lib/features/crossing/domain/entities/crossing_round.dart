/// Mirrors the admin backend's `CrossingRoundStatus` (blackhole_admin/src/lib/types.ts).
enum CrossingRoundStatus { pending, collected, busted }

/// Mirrors the admin backend's `CrossingDifficulty`. Board layout (lane
/// count) is fixed per tier — see [CrossingRound.laneCount], which is
/// server-supplied rather than a hardcoded client constant so the client
/// always matches whatever board the server actually built the round on.
enum CrossingDifficulty { easy, medium, hard, hardcore }

extension CrossingDifficultyLabel on CrossingDifficulty {
  String get label => switch (this) {
        CrossingDifficulty.easy => 'Easy',
        CrossingDifficulty.medium => 'Medium',
        CrossingDifficulty.hard => 'Hard',
        CrossingDifficulty.hardcore => 'Hardcore',
      };
}

/// A round of Multiplier Crossing as seen by the client. The server is the
/// only thing that knows whether a lane busts while [status] is
/// [CrossingRoundStatus.pending] — see the admin backend's
/// `CrossingRepository` doc comment. [serverSeed] is only populated once
/// the round resolves, at which point it doubles as the provably-fair
/// reveal: anyone can confirm `sha256(serverSeed) == serverSeedHash` and
/// that replaying the per-lane HMAC draw for lanes 1..[currentLane]
/// reproduces the exact survive/bust sequence this round actually played.
///
/// Unlike Multiplier Climb's continuously-growing multiplier, [ladder] is
/// public and fully known before betting (a pure function of
/// rtp/bustPct/laneCount, no secret involved) — only whether a given lane
/// busts is hidden, one reveal per [CrossingRepository.advance] call.
class CrossingRound {
  const CrossingRound({
    required this.roundId,
    required this.status,
    required this.difficulty,
    required this.betAmount,
    required this.laneCount,
    required this.currentLane,
    required this.ladder,
    required this.clientSeed,
    required this.serverSeedHash,
    required this.startedAt,
    this.payout,
    this.resolvedMultiplier,
    this.serverSeed,
    this.rtp,
    this.bustPct,
    this.voided = false,
  });

  final String roundId;
  final CrossingRoundStatus status;
  final CrossingDifficulty difficulty;
  final int betAmount;
  final int laneCount;

  /// 0..[laneCount] — lanes survived so far.
  final int currentLane;

  /// ladder[i] = payout multiplier for surviving lane i+1.
  final List<double> ladder;
  final String clientSeed;
  final String serverSeedHash;
  final DateTime startedAt;
  final int? payout;
  final double? resolvedMultiplier;
  final String? serverSeed;
  final double? rtp;
  final double? bustPct;

  /// True only for a round an admin ended via the emergency-stop "refund
  /// all" action — [status] is still [CrossingRoundStatus.busted] (never a
  /// win) but [payout] is the full bet back, not a genuine outcome. See the
  /// admin backend's `CrossingRepository.emergencyStopAll`.
  final bool voided;

  /// The multiplier this round is currently sitting at — 1.0 before the
  /// first successful lane, otherwise `ladder[currentLane - 1]`. What a
  /// cash-out right now would pay, before the server's `maxWin` cap.
  double get currentMultiplier => currentLane == 0 ? 1.0 : ladder[currentLane - 1];

  bool get canCashOut => status == CrossingRoundStatus.pending && currentLane >= 1;

  factory CrossingRound.fromJson(Map<String, dynamic> json) => CrossingRound(
        roundId: json['roundId'] as String,
        status: CrossingRoundStatus.values.byName(json['status'] as String),
        difficulty: CrossingDifficulty.values.byName(json['difficulty'] as String),
        betAmount: (json['betAmount'] as num).toInt(),
        laneCount: (json['laneCount'] as num).toInt(),
        currentLane: (json['currentLane'] as num).toInt(),
        ladder: (json['ladder'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(growable: false),
        clientSeed: json['clientSeed'] as String,
        serverSeedHash: json['serverSeedHash'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        payout: (json['payout'] as num?)?.toInt(),
        resolvedMultiplier: (json['resolvedMultiplier'] as num?)?.toDouble(),
        serverSeed: json['serverSeed'] as String?,
        rtp: (json['rtp'] as num?)?.toDouble(),
        bustPct: (json['bustPct'] as num?)?.toDouble(),
        voided: json['voided'] as bool? ?? false,
      );
}

/// The response shape every crossing-game endpoint that mutates a round
/// returns: the round plus the player's balance after that action.
class CrossingRoundResult {
  const CrossingRoundResult({required this.round, required this.balance});

  final CrossingRound round;
  final int balance;

  factory CrossingRoundResult.fromJson(Map<String, dynamic> json) => CrossingRoundResult(
        round: CrossingRound.fromJson(json['round'] as Map<String, dynamic>),
        balance: (json['balance'] as num).toInt(),
      );
}

/// One resolved round from the player's server-side crossing history —
/// backs the round history strip/modal.
class CrossingHistoryEntry {
  const CrossingHistoryEntry({
    required this.roundId,
    required this.bet,
    required this.difficulty,
    required this.lanesCleared,
    required this.multiplier,
    required this.winAmount,
    required this.isWin,
    required this.timestamp,
    this.voided = false,
  });

  final String roundId;
  final int bet;
  final CrossingDifficulty difficulty;
  final int lanesCleared;

  /// The multiplier actually cashed out at — 0 for a busted round.
  final double multiplier;
  final int winAmount;
  final bool isWin;
  final DateTime timestamp;

  /// See [CrossingRound.voided] — an admin-refunded round, not a real win or loss.
  final bool voided;

  factory CrossingHistoryEntry.fromJson(Map<String, dynamic> json) => CrossingHistoryEntry(
        roundId: json['roundId'] as String,
        bet: (json['bet'] as num).toInt(),
        difficulty: CrossingDifficulty.values.byName(json['difficulty'] as String),
        lanesCleared: (json['lanesCleared'] as num).toInt(),
        multiplier: (json['multiplier'] as num).toDouble(),
        winAmount: (json['winAmount'] as num).toInt(),
        isWin: json['isWin'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
        voided: json['voided'] as bool? ?? false,
      );
}
