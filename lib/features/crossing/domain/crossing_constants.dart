import 'entities/crossing_round.dart';

/// Client-side fallbacks for Multiplier Crossing, used only until the real
/// `/api/public/crossing/settings` response lands (see
/// `CrossingSharedNotifier._loadSettings`) — the server enforces its own
/// copy of all of this independently, these just seed the UI so it isn't
/// empty for one frame.
abstract final class CrossingConstants {
  static const int minBet = 20;
  static const int maxBet = 500;
  static const int maxWin = 100000;
  static const int betStep = 10;
  static const int defaultBet = 20;

  /// One-tap bet amounts shown above the stepper — mirrors Multiplier
  /// Climb's [CrashConstants.quickBetPresets]. Must all fall within
  /// [minBet]/[maxBet].
  static const List<int> quickBetPresets = <int>[20, 50, 100, 250, 500];

  /// Board-layout fallback — the server is the source of truth (a
  /// difficulty's lane count is fixed, not admin-tunable, but still
  /// server-supplied so the client never hardcodes something that could
  /// drift from what the backend actually built the round on).
  static const Map<CrossingDifficulty, int> laneCounts = <CrossingDifficulty, int>{
    CrossingDifficulty.easy: 30,
    CrossingDifficulty.medium: 25,
    CrossingDifficulty.hard: 22,
    CrossingDifficulty.hardcore: 18,
  };

  /// How many rounds to keep in the client-side history cache — mirrors
  /// [CrashConstants.historyLimit].
  static const int historyLimit = 20;
}
