// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missions_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MissionsProgress _$MissionsProgressFromJson(Map<String, dynamic> json) =>
    _MissionsProgress(
      dailyPeriodStart: DateTime.parse(json['dailyPeriodStart'] as String),
      weeklyPeriodStart: DateTime.parse(json['weeklyPeriodStart'] as String),
      baselines: Map<String, int>.from(json['baselines'] as Map),
      claimedIds: (json['claimedIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MissionsProgressToJson(_MissionsProgress instance) =>
    <String, dynamic>{
      'dailyPeriodStart': instance.dailyPeriodStart.toIso8601String(),
      'weeklyPeriodStart': instance.weeklyPeriodStart.toIso8601String(),
      'baselines': instance.baselines,
      'claimedIds': instance.claimedIds,
    };
