import 'package:freezed_annotation/freezed_annotation.dart';

part 'missions_progress.freezed.dart';
part 'missions_progress.g.dart';

/// Persisted bookkeeping behind the mission catalog: per-mission
/// "counter value when the current period started" (so progress can be
/// shown as `currentValue - baseline` instead of a lifetime total) and
/// which missions have already been claimed this period.
@freezed
abstract class MissionsProgress with _$MissionsProgress {
  const factory MissionsProgress({
    required DateTime dailyPeriodStart,
    required DateTime weeklyPeriodStart,
    required Map<String, int> baselines,
    required List<String> claimedIds,
  }) = _MissionsProgress;

  factory MissionsProgress.initial(DateTime now) => MissionsProgress(
        dailyPeriodStart: now,
        weeklyPeriodStart: now,
        baselines: const <String, int>{},
        claimedIds: const <String>[],
      );

  factory MissionsProgress.fromJson(Map<String, dynamic> json) =>
      _$MissionsProgressFromJson(json);
}
