/// One row in the platform-wide leaderboard — no player id, just a display
/// name (see blackhole_admin's `CrashLeaderboardEntry`).
class CrashLeaderboardEntry {
  const CrashLeaderboardEntry({
    required this.playerName,
    required this.bet,
    required this.multiplier,
    required this.payout,
  });

  final String playerName;
  final int bet;
  final double multiplier;
  final int payout;

  factory CrashLeaderboardEntry.fromJson(Map<String, dynamic> json) => CrashLeaderboardEntry(
        playerName: json['playerName'] as String,
        bet: (json['bet'] as num).toInt(),
        multiplier: (json['multiplier'] as num).toDouble(),
        payout: (json['payout'] as num).toInt(),
      );
}

/// Platform-wide (not this session's own) Multiplier Climb activity.
class CrashLeaderboard {
  const CrashLeaderboard({
    required this.totalBets,
    required this.totalWagered,
    required this.totalPayout,
    required this.topWins,
    required this.topBets,
  });

  final int totalBets;
  final int totalWagered;
  final int totalPayout;
  final List<CrashLeaderboardEntry> topWins;
  final List<CrashLeaderboardEntry> topBets;

  factory CrashLeaderboard.fromJson(Map<String, dynamic> json) => CrashLeaderboard(
        totalBets: (json['totalBets'] as num).toInt(),
        totalWagered: (json['totalWagered'] as num).toInt(),
        totalPayout: (json['totalPayout'] as num).toInt(),
        topWins: (json['topWins'] as List<dynamic>)
            .map((dynamic e) => CrashLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        topBets: (json['topBets'] as List<dynamic>)
            .map((dynamic e) => CrashLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
