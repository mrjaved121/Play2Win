import 'dart:math';

import 'crossing_constants.dart';
import 'entities/crossing_round.dart';

/// One fake player's bet for the round the "live wins" ticker is currently
/// showing — see Multiplier Climb's `LeaderboardSeed` doc comment for why
/// this is a client-side-only simulation rather than real other-player
/// data: there's no backend for other players' rounds. Purely visual flavor,
/// seeded fresh each time this player starts a new round.
class LeaderboardSeed {
  const LeaderboardSeed({
    required this.username,
    required this.bet,
    required this.difficulty,
    required this.targetLane,
  });

  final String username;
  final int bet;
  final CrossingDifficulty difficulty;

  /// The lane this fake player "plans" to cash out at.
  final int targetLane;
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

const List<CrossingDifficulty> _difficultyPool = <CrossingDifficulty>[
  CrossingDifficulty.easy,
  CrossingDifficulty.easy,
  CrossingDifficulty.medium,
  CrossingDifficulty.medium,
  CrossingDifficulty.hard,
  CrossingDifficulty.hardcore,
];

/// Generates a fresh, plausible-looking set of "other players": random
/// handles, bets drawn from the same quick-bet presets a real player would
/// use, and cash-out targets skewed toward earlier lanes since that's how
/// most real players actually behave.
List<LeaderboardSeed> generateLeaderboardSeeds({int count = 8, int? seed}) {
  final Random random = seed == null ? Random() : Random(seed);
  final List<String> pool = List<String>.of(_mockUsernames)..shuffle(random);
  return List<LeaderboardSeed>.generate(count, (int i) {
    final CrossingDifficulty difficulty = _difficultyPool[random.nextInt(_difficultyPool.length)];
    final int laneCount = CrossingConstants.laneCounts[difficulty]!;
    final int targetLane = 1 + (pow(random.nextDouble(), 2) * (laneCount - 1)).floor();
    return LeaderboardSeed(
      username: pool[i % pool.length],
      bet: CrossingConstants.quickBetPresets[random.nextInt(CrossingConstants.quickBetPresets.length)],
      difficulty: difficulty,
      targetLane: targetLane,
    );
  });
}
