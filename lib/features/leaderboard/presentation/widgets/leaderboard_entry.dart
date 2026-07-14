/// One ranked player row. Placeholder UI-layer model for Phase 2 — Phase
/// 6 replaces this with a real domain entity backed by Firebase/REST.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.coins,
    this.vipTier,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final int coins;
  final int? vipTier;
  final bool isCurrentUser;
}
