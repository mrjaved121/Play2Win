import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../../wallet/domain/entities/wallet_transaction.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../data/repositories/hive_daily_bonus_repository.dart';
import '../../domain/entities/daily_bonus_state.dart';
import '../../domain/repositories/daily_bonus_repository.dart';

final Provider<DailyBonusRepository> dailyBonusRepositoryProvider = Provider<DailyBonusRepository>(
  (Ref ref) => HiveDailyBonusRepository(getIt<StorageService>()),
);

/// Owns the persisted [DailyBonusState], rolling it over once
/// [AppConstants.dailyBonusResetPeriod] has elapsed since the period
/// started (mirrors [[MissionsProgressNotifier]]'s baseline-diff
/// pattern, scoped to the single daily-login reward).
class DailyBonusNotifier extends Notifier<DailyBonusState> {
  @override
  DailyBonusState build() {
    final DateTime now = DateTime.now();
    final int currentSpins = ref.read(gameProvider).totalSpins;
    final DailyBonusState loaded =
        ref.read(dailyBonusRepositoryProvider).load() ?? DailyBonusState.initial(now: now, currentSpins: currentSpins);
    return _rollIfNeeded(loaded, now, currentSpins);
  }

  DailyBonusState _rollIfNeeded(DailyBonusState bonus, DateTime now, int currentSpins) {
    if (now.difference(bonus.periodStart) < AppConstants.dailyBonusResetPeriod) return bonus;
    final DailyBonusState reset = DailyBonusState.initial(now: now, currentSpins: currentSpins);
    unawaited(ref.read(dailyBonusRepositoryProvider).save(reset));
    return reset;
  }

  void claim() {
    if (!AppConstants.dailyBonusEnabled) return;
    final int currentSpins = ref.read(gameProvider).totalSpins;
    final int completed = currentSpins - state.spinsBaseline;
    if (completed < AppConstants.dailyBonusRequiredSpins || state.claimed) return;

    final DailyBonusState updated = state.copyWith(claimed: true);
    state = updated;
    unawaited(ref.read(dailyBonusRepositoryProvider).save(updated));
    ref.read(gameProvider.notifier).addCoins(AppConstants.dailyBonusReward);
    ref.read(walletTransactionsProvider.notifier).record(
          type: TransactionType.bonus,
          label: 'Daily Bonus',
          amount: AppConstants.dailyBonusReward,
        );
  }
}

final NotifierProvider<DailyBonusNotifier, DailyBonusState> dailyBonusProvider =
    NotifierProvider<DailyBonusNotifier, DailyBonusState>(DailyBonusNotifier.new);

/// Spins completed toward today's bonus, clamped to the requirement.
final Provider<int> dailyBonusSpinsCompletedProvider = Provider<int>((Ref ref) {
  final DailyBonusState bonus = ref.watch(dailyBonusProvider);
  final int currentSpins = ref.watch(gameProvider).totalSpins;
  return (currentSpins - bonus.spinsBaseline).clamp(0, AppConstants.dailyBonusRequiredSpins);
});
