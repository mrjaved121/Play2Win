import '../../../../core/services/storage_service.dart';
import '../../domain/repositories/recently_played_repository.dart';

/// Stores recently-played game ids (most recent first) as a plain string
/// list in the default Hive box — same map/list-based approach as
/// [[HiveWalletRepository]] (see [[project-build-environment-gotchas]]
/// for why: no `hive_generator`).
class HiveRecentlyPlayedRepository implements RecentlyPlayedRepository {
  HiveRecentlyPlayedRepository(this._storage);

  final StorageService _storage;
  static const String _key = 'recently_played_game_ids';

  @override
  List<String> load() {
    final List<dynamic>? raw = _storage.get<List<dynamic>>(_key);
    if (raw == null) return const <String>[];
    return raw.cast<String>();
  }

  @override
  Future<void> save(List<String> gameIds) {
    return _storage.put<List<String>>(_key, gameIds);
  }
}
