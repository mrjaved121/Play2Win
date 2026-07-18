import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/mock_leaderboard.dart';
import 'crash_providers.dart';

/// Holds the current flight's simulated "other players" — see
/// [generateLeaderboardSeeds]'s doc comment for why this is mocked rather
/// than real multiplayer data. Regenerates only when a genuinely new
/// roundId appears from *either* bet panel, so the board stays stable
/// while a flight is running/resolved instead of reshuffling every render
/// tick — and doesn't double-regenerate when both panels end up sharing
/// one joined flight (same `roundId`... actually a different `roundId`
/// each, but the same crash point; see `crash_providers.dart` — either
/// slot's bet is enough to mark "this flight already has a board").
class MockLeaderboardNotifier extends Notifier<List<LeaderboardSeed>> {
  String? _lastRoundId;

  @override
  List<LeaderboardSeed> build() {
    void onSlotChange(CrashSlotState? previous, CrashSlotState next) {
      final String? roundId = next.round?.roundId;
      if (roundId != null && roundId != _lastRoundId) {
        _lastRoundId = roundId;
        state = generateLeaderboardSeeds();
      }
    }

    ref.listen<CrashSlotState>(crashSlotProvider(CrashSlotId.slot1), onSlotChange);
    ref.listen<CrashSlotState>(crashSlotProvider(CrashSlotId.slot2), onSlotChange);
    return const <LeaderboardSeed>[];
  }
}

final NotifierProvider<MockLeaderboardNotifier, List<LeaderboardSeed>> mockLeaderboardProvider =
    NotifierProvider<MockLeaderboardNotifier, List<LeaderboardSeed>>(MockLeaderboardNotifier.new);
