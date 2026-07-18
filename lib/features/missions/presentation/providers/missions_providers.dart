import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../../slot/presentation/providers/game_providers.dart';
import '../../data/repositories/hive_missions_repository.dart';
import '../../domain/entities/mission_definition.dart';
import '../../domain/entities/missions_progress.dart';
import '../../domain/repositories/missions_repository.dart';

final Provider<MissionsRepository> missionsRepositoryProvider = Provider<MissionsRepository>(
  (Ref ref) => HiveMissionsRepository(getIt<StorageService>()),
);

/// Owns the persisted [MissionsProgress] (per-mission baseline + claimed
/// ids) and rolls daily/weekly missions over once their period has
/// elapsed. Live progress values are computed separately by
/// [missionViewsProvider], which combines this with the current
/// [gameProvider] state.
class MissionsProgressNotifier extends Notifier<MissionsProgress> {
  @override
  MissionsProgress build() {
    final DateTime now = DateTime.now();
    final MissionsProgress loaded = ref.read(missionsRepositoryProvider).load() ?? MissionsProgress.initial(now);
    return _rollIfNeeded(loaded, now);
  }

  MissionsProgress _rollIfNeeded(MissionsProgress progress, DateTime now) {
    final game = ref.read(gameProvider);
    final Map<String, int> baselines = Map<String, int>.of(progress.baselines);
    final List<String> claimed = List<String>.of(progress.claimedIds);
    DateTime dailyStart = progress.dailyPeriodStart;
    DateTime weeklyStart = progress.weeklyPeriodStart;
    bool changed = false;

    if (now.difference(dailyStart) >= const Duration(hours: 24)) {
      dailyStart = now;
      for (final MissionDefinition m
          in MissionDefinition.catalog.where((MissionDefinition m) => m.period == MissionPeriod.daily)) {
        baselines[m.id] = m.metricValue(game);
        claimed.remove(m.id);
      }
      changed = true;
    }
    if (now.difference(weeklyStart) >= const Duration(days: 7)) {
      weeklyStart = now;
      for (final MissionDefinition m
          in MissionDefinition.catalog.where((MissionDefinition m) => m.period == MissionPeriod.weekly)) {
        baselines[m.id] = m.metricValue(game);
        claimed.remove(m.id);
      }
      changed = true;
    }
    for (final MissionDefinition m in MissionDefinition.catalog) {
      if (!baselines.containsKey(m.id)) {
        baselines[m.id] = m.metricValue(game);
        changed = true;
      }
    }

    if (!changed) return progress;
    final MissionsProgress updated = progress.copyWith(
      dailyPeriodStart: dailyStart,
      weeklyPeriodStart: weeklyStart,
      baselines: baselines,
      claimedIds: claimed,
    );
    unawaited(ref.read(missionsRepositoryProvider).save(updated));
    return updated;
  }

  void claim(String missionId) {
    if (!AppConstants.missionsEnabled) return;
    final MissionDefinition def =
        MissionDefinition.catalog.firstWhere((MissionDefinition m) => m.id == missionId);
    final int baseline = state.baselines[missionId] ?? 0;
    final int progressValue = def.metricValue(ref.read(gameProvider)) - baseline;
    if (progressValue < def.target || state.claimedIds.contains(missionId)) return;

    final MissionsProgress updated = state.copyWith(
      claimedIds: <String>[...state.claimedIds, missionId],
    );
    state = updated;
    unawaited(ref.read(missionsRepositoryProvider).save(updated));
    ref.read(gameProvider.notifier).addCoins(def.rewardCoins);
  }
}

final NotifierProvider<MissionsProgressNotifier, MissionsProgress> missionsProgressProvider =
    NotifierProvider<MissionsProgressNotifier, MissionsProgress>(MissionsProgressNotifier.new);

/// One mission's live, UI-ready progress.
class MissionProgressView {
  const MissionProgressView({
    required this.definition,
    required this.progress,
    required this.claimed,
  });

  final MissionDefinition definition;
  final int progress;
  final bool claimed;

  bool get isComplete => progress >= definition.target;
}

final Provider<List<MissionProgressView>> missionViewsProvider = Provider<List<MissionProgressView>>(
  (Ref ref) {
    final MissionsProgress progress = ref.watch(missionsProgressProvider);
    final game = ref.watch(gameProvider);
    return <MissionProgressView>[
      for (final MissionDefinition def in MissionDefinition.catalog)
        MissionProgressView(
          definition: def,
          progress: (def.metricValue(game) - (progress.baselines[def.id] ?? 0)).clamp(0, def.target),
          claimed: progress.claimedIds.contains(def.id),
        ),
    ];
  },
);
