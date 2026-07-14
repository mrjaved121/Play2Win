import '../entities/game_state.dart';

/// Persistence boundary for [GameState]. The domain layer only knows it
/// can load/save this; `data/repositories/hive_game_repository.dart`
/// supplies the actual Hive-backed implementation.
abstract class GameRepository {
  /// Returns the last-saved state, or [GameState.initial] if none exists.
  GameState load();

  Future<void> save(GameState state);
}
