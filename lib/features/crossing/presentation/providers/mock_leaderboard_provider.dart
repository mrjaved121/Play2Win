import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/mock_leaderboard.dart';
import 'crossing_providers.dart';

/// Holds the current round's simulated "other players" — see
/// [generateLeaderboardSeeds]'s doc comment for why this is mocked rather
/// than real multiplayer data. Regenerates only when a genuinely new
/// roundId appears, so the ticker stays stable while a round is running/
/// resolved instead of reshuffling every render tick.
class MockCrossingLeaderboardNotifier extends Notifier<List<LeaderboardSeed>> {
  String? _lastRoundId;

  @override
  List<LeaderboardSeed> build() {
    ref.listen<CrossingGameState>(crossingGameProvider, (CrossingGameState? previous, CrossingGameState next) {
      final String? roundId = next.round?.roundId;
      if (roundId != null && roundId != _lastRoundId) {
        _lastRoundId = roundId;
        state = generateLeaderboardSeeds();
      }
    });
    return const <LeaderboardSeed>[];
  }
}

final NotifierProvider<MockCrossingLeaderboardNotifier, List<LeaderboardSeed>> mockCrossingLeaderboardProvider =
    NotifierProvider<MockCrossingLeaderboardNotifier, List<LeaderboardSeed>>(MockCrossingLeaderboardNotifier.new);
