import 'dart:math';

import 'crash_constants.dart';

/// One fake player's bet for the round the leaderboard is currently
/// showing — fixed for the lifetime of a round, unlike [LeaderboardRow]'s
/// cashed-out/busted status, which is derived live from the real round's
/// multiplier. There is no backend for other players' bets (Multiplier
/// Climb has no real multiplayer state), so this is a client-side-only
/// simulation for visual flavor, seeded fresh each round.
class LeaderboardSeed {
  const LeaderboardSeed({required this.username, required this.bet, required this.targetMultiplier});

  final String username;
  final int bet;

  /// The multiplier this fake player "plans" to cash out at.
  final double targetMultiplier;
}

const List<String> _mockUsernames = <String>[
  'Ali_K',
  'Zara99',
  'Ahmed.R',
  'Nimra_Q',
  'Bilal7',
  'Sana_M',
  'Usman_X',
  'Hina.T',
  'Faisal22',
  'Ayesha_N',
  'Omar_S',
  'Mahnoor',
];

/// Generates a fresh, plausible-looking set of "other players" for one
/// round: random handles, bets drawn from the same quick-bet presets a
/// real player would use, and cash-out targets skewed toward lower
/// multipliers (squaring the random draw) since that's how most real
/// crash-game players actually behave.
List<LeaderboardSeed> generateLeaderboardSeeds({int count = 8, int? seed}) {
  final Random random = seed == null ? Random() : Random(seed);
  final List<String> pool = List<String>.of(_mockUsernames)..shuffle(random);
  return List<LeaderboardSeed>.generate(count, (int i) {
    final double skewed = 1.1 + pow(random.nextDouble(), 2) * 5.0;
    return LeaderboardSeed(
      username: pool[i % pool.length],
      bet: CrashConstants.quickBetPresets[random.nextInt(CrashConstants.quickBetPresets.length)],
      targetMultiplier: double.parse(skewed.toStringAsFixed(2)),
    );
  });
}
