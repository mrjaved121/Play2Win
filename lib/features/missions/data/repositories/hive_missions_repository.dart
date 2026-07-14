import '../../../../core/services/storage_service.dart';
import '../../domain/entities/missions_progress.dart';
import '../../domain/repositories/missions_repository.dart';

class HiveMissionsRepository implements MissionsRepository {
  HiveMissionsRepository(this._storage);

  final StorageService _storage;
  static const String _key = 'missions_progress';

  @override
  MissionsProgress? load() {
    final Map<String, dynamic>? json = _storage.get<Map<dynamic, dynamic>>(_key)?.cast<String, dynamic>();
    if (json == null) return null;
    return MissionsProgress.fromJson(json);
  }

  @override
  Future<void> save(MissionsProgress progress) {
    return _storage.put<Map<String, dynamic>>(_key, progress.toJson());
  }
}
