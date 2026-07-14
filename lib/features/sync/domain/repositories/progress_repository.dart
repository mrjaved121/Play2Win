/// Cloud persistence boundary for a player's whole local progress,
/// stored as one JSON snapshot (mirrors this app's existing "JSON-map-
/// in-a-box" pattern used for Hive — see [[HiveGameRepository]] — rather
/// than exploding into normalized columns).
abstract class ProgressRepository {
  /// Null if this account has never synced from any device.
  Future<Map<String, dynamic>?> fetch(String userId);

  Future<void> push(String userId, Map<String, dynamic> snapshot);
}
