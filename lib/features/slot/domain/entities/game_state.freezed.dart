// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameState {

 int get balance; int get bet; int get totalSpins; int get lastWin; int get bestWinToday; int get winStreak; int get lossStreak; int get freeSpinsRemaining; int get jackpot; int get lifetimeWinnings; int get jackpotsWon; int get totalWins;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bet, bet) || other.bet == bet)&&(identical(other.totalSpins, totalSpins) || other.totalSpins == totalSpins)&&(identical(other.lastWin, lastWin) || other.lastWin == lastWin)&&(identical(other.bestWinToday, bestWinToday) || other.bestWinToday == bestWinToday)&&(identical(other.winStreak, winStreak) || other.winStreak == winStreak)&&(identical(other.lossStreak, lossStreak) || other.lossStreak == lossStreak)&&(identical(other.freeSpinsRemaining, freeSpinsRemaining) || other.freeSpinsRemaining == freeSpinsRemaining)&&(identical(other.jackpot, jackpot) || other.jackpot == jackpot)&&(identical(other.lifetimeWinnings, lifetimeWinnings) || other.lifetimeWinnings == lifetimeWinnings)&&(identical(other.jackpotsWon, jackpotsWon) || other.jackpotsWon == jackpotsWon)&&(identical(other.totalWins, totalWins) || other.totalWins == totalWins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,bet,totalSpins,lastWin,bestWinToday,winStreak,lossStreak,freeSpinsRemaining,jackpot,lifetimeWinnings,jackpotsWon,totalWins);

@override
String toString() {
  return 'GameState(balance: $balance, bet: $bet, totalSpins: $totalSpins, lastWin: $lastWin, bestWinToday: $bestWinToday, winStreak: $winStreak, lossStreak: $lossStreak, freeSpinsRemaining: $freeSpinsRemaining, jackpot: $jackpot, lifetimeWinnings: $lifetimeWinnings, jackpotsWon: $jackpotsWon, totalWins: $totalWins)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 int balance, int bet, int totalSpins, int lastWin, int bestWinToday, int winStreak, int lossStreak, int freeSpinsRemaining, int jackpot, int lifetimeWinnings, int jackpotsWon, int totalWins
});




}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? bet = null,Object? totalSpins = null,Object? lastWin = null,Object? bestWinToday = null,Object? winStreak = null,Object? lossStreak = null,Object? freeSpinsRemaining = null,Object? jackpot = null,Object? lifetimeWinnings = null,Object? jackpotsWon = null,Object? totalWins = null,}) {
  return _then(_self.copyWith(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,bet: null == bet ? _self.bet : bet // ignore: cast_nullable_to_non_nullable
as int,totalSpins: null == totalSpins ? _self.totalSpins : totalSpins // ignore: cast_nullable_to_non_nullable
as int,lastWin: null == lastWin ? _self.lastWin : lastWin // ignore: cast_nullable_to_non_nullable
as int,bestWinToday: null == bestWinToday ? _self.bestWinToday : bestWinToday // ignore: cast_nullable_to_non_nullable
as int,winStreak: null == winStreak ? _self.winStreak : winStreak // ignore: cast_nullable_to_non_nullable
as int,lossStreak: null == lossStreak ? _self.lossStreak : lossStreak // ignore: cast_nullable_to_non_nullable
as int,freeSpinsRemaining: null == freeSpinsRemaining ? _self.freeSpinsRemaining : freeSpinsRemaining // ignore: cast_nullable_to_non_nullable
as int,jackpot: null == jackpot ? _self.jackpot : jackpot // ignore: cast_nullable_to_non_nullable
as int,lifetimeWinnings: null == lifetimeWinnings ? _self.lifetimeWinnings : lifetimeWinnings // ignore: cast_nullable_to_non_nullable
as int,jackpotsWon: null == jackpotsWon ? _self.jackpotsWon : jackpotsWon // ignore: cast_nullable_to_non_nullable
as int,totalWins: null == totalWins ? _self.totalWins : totalWins // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int balance,  int bet,  int totalSpins,  int lastWin,  int bestWinToday,  int winStreak,  int lossStreak,  int freeSpinsRemaining,  int jackpot,  int lifetimeWinnings,  int jackpotsWon,  int totalWins)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.balance,_that.bet,_that.totalSpins,_that.lastWin,_that.bestWinToday,_that.winStreak,_that.lossStreak,_that.freeSpinsRemaining,_that.jackpot,_that.lifetimeWinnings,_that.jackpotsWon,_that.totalWins);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int balance,  int bet,  int totalSpins,  int lastWin,  int bestWinToday,  int winStreak,  int lossStreak,  int freeSpinsRemaining,  int jackpot,  int lifetimeWinnings,  int jackpotsWon,  int totalWins)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.balance,_that.bet,_that.totalSpins,_that.lastWin,_that.bestWinToday,_that.winStreak,_that.lossStreak,_that.freeSpinsRemaining,_that.jackpot,_that.lifetimeWinnings,_that.jackpotsWon,_that.totalWins);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int balance,  int bet,  int totalSpins,  int lastWin,  int bestWinToday,  int winStreak,  int lossStreak,  int freeSpinsRemaining,  int jackpot,  int lifetimeWinnings,  int jackpotsWon,  int totalWins)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.balance,_that.bet,_that.totalSpins,_that.lastWin,_that.bestWinToday,_that.winStreak,_that.lossStreak,_that.freeSpinsRemaining,_that.jackpot,_that.lifetimeWinnings,_that.jackpotsWon,_that.totalWins);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameState implements GameState {
  const _GameState({required this.balance, required this.bet, required this.totalSpins, required this.lastWin, required this.bestWinToday, required this.winStreak, required this.lossStreak, required this.freeSpinsRemaining, required this.jackpot, this.lifetimeWinnings = 0, this.jackpotsWon = 0, this.totalWins = 0});
  factory _GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

@override final  int balance;
@override final  int bet;
@override final  int totalSpins;
@override final  int lastWin;
@override final  int bestWinToday;
@override final  int winStreak;
@override final  int lossStreak;
@override final  int freeSpinsRemaining;
@override final  int jackpot;
@override@JsonKey() final  int lifetimeWinnings;
@override@JsonKey() final  int jackpotsWon;
@override@JsonKey() final  int totalWins;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bet, bet) || other.bet == bet)&&(identical(other.totalSpins, totalSpins) || other.totalSpins == totalSpins)&&(identical(other.lastWin, lastWin) || other.lastWin == lastWin)&&(identical(other.bestWinToday, bestWinToday) || other.bestWinToday == bestWinToday)&&(identical(other.winStreak, winStreak) || other.winStreak == winStreak)&&(identical(other.lossStreak, lossStreak) || other.lossStreak == lossStreak)&&(identical(other.freeSpinsRemaining, freeSpinsRemaining) || other.freeSpinsRemaining == freeSpinsRemaining)&&(identical(other.jackpot, jackpot) || other.jackpot == jackpot)&&(identical(other.lifetimeWinnings, lifetimeWinnings) || other.lifetimeWinnings == lifetimeWinnings)&&(identical(other.jackpotsWon, jackpotsWon) || other.jackpotsWon == jackpotsWon)&&(identical(other.totalWins, totalWins) || other.totalWins == totalWins));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,bet,totalSpins,lastWin,bestWinToday,winStreak,lossStreak,freeSpinsRemaining,jackpot,lifetimeWinnings,jackpotsWon,totalWins);

@override
String toString() {
  return 'GameState(balance: $balance, bet: $bet, totalSpins: $totalSpins, lastWin: $lastWin, bestWinToday: $bestWinToday, winStreak: $winStreak, lossStreak: $lossStreak, freeSpinsRemaining: $freeSpinsRemaining, jackpot: $jackpot, lifetimeWinnings: $lifetimeWinnings, jackpotsWon: $jackpotsWon, totalWins: $totalWins)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 int balance, int bet, int totalSpins, int lastWin, int bestWinToday, int winStreak, int lossStreak, int freeSpinsRemaining, int jackpot, int lifetimeWinnings, int jackpotsWon, int totalWins
});




}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? bet = null,Object? totalSpins = null,Object? lastWin = null,Object? bestWinToday = null,Object? winStreak = null,Object? lossStreak = null,Object? freeSpinsRemaining = null,Object? jackpot = null,Object? lifetimeWinnings = null,Object? jackpotsWon = null,Object? totalWins = null,}) {
  return _then(_GameState(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as int,bet: null == bet ? _self.bet : bet // ignore: cast_nullable_to_non_nullable
as int,totalSpins: null == totalSpins ? _self.totalSpins : totalSpins // ignore: cast_nullable_to_non_nullable
as int,lastWin: null == lastWin ? _self.lastWin : lastWin // ignore: cast_nullable_to_non_nullable
as int,bestWinToday: null == bestWinToday ? _self.bestWinToday : bestWinToday // ignore: cast_nullable_to_non_nullable
as int,winStreak: null == winStreak ? _self.winStreak : winStreak // ignore: cast_nullable_to_non_nullable
as int,lossStreak: null == lossStreak ? _self.lossStreak : lossStreak // ignore: cast_nullable_to_non_nullable
as int,freeSpinsRemaining: null == freeSpinsRemaining ? _self.freeSpinsRemaining : freeSpinsRemaining // ignore: cast_nullable_to_non_nullable
as int,jackpot: null == jackpot ? _self.jackpot : jackpot // ignore: cast_nullable_to_non_nullable
as int,lifetimeWinnings: null == lifetimeWinnings ? _self.lifetimeWinnings : lifetimeWinnings // ignore: cast_nullable_to_non_nullable
as int,jackpotsWon: null == jackpotsWon ? _self.jackpotsWon : jackpotsWon // ignore: cast_nullable_to_non_nullable
as int,totalWins: null == totalWins ? _self.totalWins : totalWins // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
