// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_bonus_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyBonusState _$DailyBonusStateFromJson(Map<String, dynamic> json) =>
    _DailyBonusState(
      periodStart: DateTime.parse(json['periodStart'] as String),
      spinsBaseline: (json['spinsBaseline'] as num).toInt(),
      claimed: json['claimed'] as bool,
    );

Map<String, dynamic> _$DailyBonusStateToJson(_DailyBonusState instance) =>
    <String, dynamic>{
      'periodStart': instance.periodStart.toIso8601String(),
      'spinsBaseline': instance.spinsBaseline,
      'claimed': instance.claimed,
    };
