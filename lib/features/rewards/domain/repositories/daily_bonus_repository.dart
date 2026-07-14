import '../entities/daily_bonus_state.dart';

abstract class DailyBonusRepository {
  DailyBonusState? load();
  Future<void> save(DailyBonusState state);
}
