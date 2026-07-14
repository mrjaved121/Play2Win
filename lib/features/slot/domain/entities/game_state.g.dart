// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameState _$GameStateFromJson(Map<String, dynamic> json) => _GameState(
  balance: (json['balance'] as num).toInt(),
  bet: (json['bet'] as num).toInt(),
  totalSpins: (json['totalSpins'] as num).toInt(),
  lastWin: (json['lastWin'] as num).toInt(),
  bestWinToday: (json['bestWinToday'] as num).toInt(),
  winStreak: (json['winStreak'] as num).toInt(),
  lossStreak: (json['lossStreak'] as num).toInt(),
  freeSpinsRemaining: (json['freeSpinsRemaining'] as num).toInt(),
  jackpot: (json['jackpot'] as num).toInt(),
  lifetimeWinnings: (json['lifetimeWinnings'] as num?)?.toInt() ?? 0,
  jackpotsWon: (json['jackpotsWon'] as num?)?.toInt() ?? 0,
  totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$GameStateToJson(_GameState instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'bet': instance.bet,
      'totalSpins': instance.totalSpins,
      'lastWin': instance.lastWin,
      'bestWinToday': instance.bestWinToday,
      'winStreak': instance.winStreak,
      'lossStreak': instance.lossStreak,
      'freeSpinsRemaining': instance.freeSpinsRemaining,
      'jackpot': instance.jackpot,
      'lifetimeWinnings': instance.lifetimeWinnings,
      'jackpotsWon': instance.jackpotsWon,
      'totalWins': instance.totalWins,
    };
