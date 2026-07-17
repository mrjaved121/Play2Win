/// Client-side bet bounds for Multiplier Climb. The server
/// (blackhole_admin's CrashRepository) enforces the same min/max
/// independently — these just drive the bet stepper UI so it doesn't let
/// the player pick something the server would reject.
abstract final class CrashConstants {
  static const int minBet = 10;
  static const int maxBet = 500;
  static const int betStep = 10;
  static const int defaultBet = 20;

  /// How often the reconciliation poll (GET .../state) checks whether a
  /// round crashed while the player hasn't tapped Collect — the local
  /// render loop ticks far more often than this, this is only for
  /// noticing a crash the player would otherwise never be told about.
  static const Duration statePollInterval = Duration(milliseconds: 900);

  /// Local render tick — how often the displayed multiplier is
  /// recomputed from elapsed time between network calls.
  static const Duration renderTickInterval = Duration(milliseconds: 33);
}
