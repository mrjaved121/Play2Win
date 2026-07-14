import '../entities/missions_progress.dart';

abstract class MissionsRepository {
  MissionsProgress? load();
  Future<void> save(MissionsProgress progress);
}
