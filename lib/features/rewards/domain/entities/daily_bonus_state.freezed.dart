// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_bonus_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyBonusState {

 DateTime get periodStart; int get spinsBaseline; bool get claimed;
/// Create a copy of DailyBonusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyBonusStateCopyWith<DailyBonusState> get copyWith => _$DailyBonusStateCopyWithImpl<DailyBonusState>(this as DailyBonusState, _$identity);

  /// Serializes this DailyBonusState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyBonusState&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.spinsBaseline, spinsBaseline) || other.spinsBaseline == spinsBaseline)&&(identical(other.claimed, claimed) || other.claimed == claimed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,periodStart,spinsBaseline,claimed);

@override
String toString() {
  return 'DailyBonusState(periodStart: $periodStart, spinsBaseline: $spinsBaseline, claimed: $claimed)';
}


}

/// @nodoc
abstract mixin class $DailyBonusStateCopyWith<$Res>  {
  factory $DailyBonusStateCopyWith(DailyBonusState value, $Res Function(DailyBonusState) _then) = _$DailyBonusStateCopyWithImpl;
@useResult
$Res call({
 DateTime periodStart, int spinsBaseline, bool claimed
});




}
/// @nodoc
class _$DailyBonusStateCopyWithImpl<$Res>
    implements $DailyBonusStateCopyWith<$Res> {
  _$DailyBonusStateCopyWithImpl(this._self, this._then);

  final DailyBonusState _self;
  final $Res Function(DailyBonusState) _then;

/// Create a copy of DailyBonusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? periodStart = null,Object? spinsBaseline = null,Object? claimed = null,}) {
  return _then(_self.copyWith(
periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,spinsBaseline: null == spinsBaseline ? _self.spinsBaseline : spinsBaseline // ignore: cast_nullable_to_non_nullable
as int,claimed: null == claimed ? _self.claimed : claimed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyBonusState].
extension DailyBonusStatePatterns on DailyBonusState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyBonusState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyBonusState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyBonusState value)  $default,){
final _that = this;
switch (_that) {
case _DailyBonusState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyBonusState value)?  $default,){
final _that = this;
switch (_that) {
case _DailyBonusState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime periodStart,  int spinsBaseline,  bool claimed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyBonusState() when $default != null:
return $default(_that.periodStart,_that.spinsBaseline,_that.claimed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime periodStart,  int spinsBaseline,  bool claimed)  $default,) {final _that = this;
switch (_that) {
case _DailyBonusState():
return $default(_that.periodStart,_that.spinsBaseline,_that.claimed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime periodStart,  int spinsBaseline,  bool claimed)?  $default,) {final _that = this;
switch (_that) {
case _DailyBonusState() when $default != null:
return $default(_that.periodStart,_that.spinsBaseline,_that.claimed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyBonusState implements DailyBonusState {
  const _DailyBonusState({required this.periodStart, required this.spinsBaseline, required this.claimed});
  factory _DailyBonusState.fromJson(Map<String, dynamic> json) => _$DailyBonusStateFromJson(json);

@override final  DateTime periodStart;
@override final  int spinsBaseline;
@override final  bool claimed;

/// Create a copy of DailyBonusState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyBonusStateCopyWith<_DailyBonusState> get copyWith => __$DailyBonusStateCopyWithImpl<_DailyBonusState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyBonusStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyBonusState&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.spinsBaseline, spinsBaseline) || other.spinsBaseline == spinsBaseline)&&(identical(other.claimed, claimed) || other.claimed == claimed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,periodStart,spinsBaseline,claimed);

@override
String toString() {
  return 'DailyBonusState(periodStart: $periodStart, spinsBaseline: $spinsBaseline, claimed: $claimed)';
}


}

/// @nodoc
abstract mixin class _$DailyBonusStateCopyWith<$Res> implements $DailyBonusStateCopyWith<$Res> {
  factory _$DailyBonusStateCopyWith(_DailyBonusState value, $Res Function(_DailyBonusState) _then) = __$DailyBonusStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime periodStart, int spinsBaseline, bool claimed
});




}
/// @nodoc
class __$DailyBonusStateCopyWithImpl<$Res>
    implements _$DailyBonusStateCopyWith<$Res> {
  __$DailyBonusStateCopyWithImpl(this._self, this._then);

  final _DailyBonusState _self;
  final $Res Function(_DailyBonusState) _then;

/// Create a copy of DailyBonusState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? periodStart = null,Object? spinsBaseline = null,Object? claimed = null,}) {
  return _then(_DailyBonusState(
periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,spinsBaseline: null == spinsBaseline ? _self.spinsBaseline : spinsBaseline // ignore: cast_nullable_to_non_nullable
as int,claimed: null == claimed ? _self.claimed : claimed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
