import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_bonus_state.freezed.dart';
part 'daily_bonus_state.g.dart';

/// Persisted daily-bonus tracking: the spin count baseline the current
/// 24h period started at (so "spin N times" progress is
/// `currentTotalSpins - spinsBaseline`, the same baseline-diff pattern
/// [[MissionsProgress]] uses) and whether today's reward was claimed.
@freezed
abstract class DailyBonusState with _$DailyBonusState {
  const factory DailyBonusState({
    required DateTime periodStart,
    required int spinsBaseline,
    required bool claimed,
  }) = _DailyBonusState;

  factory DailyBonusState.initial({required DateTime now, required int currentSpins}) => DailyBonusState(
        periodStart: now,
        spinsBaseline: currentSpins,
        claimed: false,
      );

  factory DailyBonusState.fromJson(Map<String, dynamic> json) => _$DailyBonusStateFromJson(json);
}
