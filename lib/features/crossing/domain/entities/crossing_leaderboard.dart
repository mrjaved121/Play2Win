import 'crossing_round.dart';

/// One row in the platform-wide leaderboard — no player id, just a display
/// name (see blackhole_admin's `CrossingLeaderboardEntry`).
class CrossingLeaderboardEntry {
  const CrossingLeaderboardEntry({
    required this.playerName,
    required this.bet,
    required this.difficulty,
    required this.multiplier,
    required this.payout,
  });

  final String playerName;
  final int bet;
  final CrossingDifficulty difficulty;
  final double multiplier;
  final int payout;

  factory CrossingLeaderboardEntry.fromJson(Map<String, dynamic> json) => CrossingLeaderboardEntry(
        playerName: json['playerName'] as String,
        bet: (json['bet'] as num).toInt(),
        difficulty: CrossingDifficulty.values.byName(json['difficulty'] as String),
        multiplier: (json['multiplier'] as num).toDouble(),
        payout: (json['payout'] as num).toInt(),
      );
}

/// Platform-wide (not this session's own) Multiplier Crossing activity.
class CrossingLeaderboard {
  const CrossingLeaderboard({
    required this.totalBets,
    required this.totalWagered,
    required this.totalPayout,
    required this.topWins,
  });

  final int totalBets;
  final int totalWagered;
  final int totalPayout;
  final List<CrossingLeaderboardEntry> topWins;

  factory CrossingLeaderboard.fromJson(Map<String, dynamic> json) => CrossingLeaderboard(
        totalBets: (json['totalBets'] as num).toInt(),
        totalWagered: (json['totalWagered'] as num).toInt(),
        totalPayout: (json['totalPayout'] as num).toInt(),
        topWins: (json['topWins'] as List<dynamic>)
            .map((dynamic e) => CrossingLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
