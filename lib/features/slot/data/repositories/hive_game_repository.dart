import '../../../../core/services/storage_service.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';

/// Stores [GameState] as a JSON map in the default Hive box — see
/// [[project-build-environment-gotchas]] for why this doesn't use
/// `@HiveType` codegen: `toJson()`/`fromJson()` from the Freezed entity
/// do the serializing, Hive just persists the resulting map.
class HiveGameRepository implements GameRepository {
  HiveGameRepository(this._storage);

  final StorageService _storage;

  static const String _key = 'game_state';

  @override
  GameState load() {
    final Map<String, dynamic>? json = _storage.get<Map<dynamic, dynamic>>(_key)?.cast<String, dynamic>();
    if (json == null) return GameState.initial();
    return GameState.fromJson(json);
  }

  @override
  Future<void> save(GameState state) {
    return _storage.put<Map<String, dynamic>>(_key, state.toJson());
  }
}
