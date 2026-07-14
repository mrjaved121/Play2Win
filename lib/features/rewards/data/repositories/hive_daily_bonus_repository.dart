import '../../../../core/services/storage_service.dart';
import '../../domain/entities/daily_bonus_state.dart';
import '../../domain/repositories/daily_bonus_repository.dart';

class HiveDailyBonusRepository implements DailyBonusRepository {
  HiveDailyBonusRepository(this._storage);

  final StorageService _storage;
  static const String _key = 'daily_bonus_state';

  @override
  DailyBonusState? load() {
    final Map<String, dynamic>? json = _storage.get<Map<dynamic, dynamic>>(_key)?.cast<String, dynamic>();
    if (json == null) return null;
    return DailyBonusState.fromJson(json);
  }

  @override
  Future<void> save(DailyBonusState state) {
    return _storage.put<Map<String, dynamic>>(_key, state.toJson());
  }
}
