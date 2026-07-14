// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'missions_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MissionsProgress {

 DateTime get dailyPeriodStart; DateTime get weeklyPeriodStart; Map<String, int> get baselines; List<String> get claimedIds;
/// Create a copy of MissionsProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MissionsProgressCopyWith<MissionsProgress> get copyWith => _$MissionsProgressCopyWithImpl<MissionsProgress>(this as MissionsProgress, _$identity);

  /// Serializes this MissionsProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MissionsProgress&&(identical(other.dailyPeriodStart, dailyPeriodStart) || other.dailyPeriodStart == dailyPeriodStart)&&(identical(other.weeklyPeriodStart, weeklyPeriodStart) || other.weeklyPeriodStart == weeklyPeriodStart)&&const DeepCollectionEquality().equals(other.baselines, baselines)&&const DeepCollectionEquality().equals(other.claimedIds, claimedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dailyPeriodStart,weeklyPeriodStart,const DeepCollectionEquality().hash(baselines),const DeepCollectionEquality().hash(claimedIds));

@override
String toString() {
  return 'MissionsProgress(dailyPeriodStart: $dailyPeriodStart, weeklyPeriodStart: $weeklyPeriodStart, baselines: $baselines, claimedIds: $claimedIds)';
}


}

/// @nodoc
abstract mixin class $MissionsProgressCopyWith<$Res>  {
  factory $MissionsProgressCopyWith(MissionsProgress value, $Res Function(MissionsProgress) _then) = _$MissionsProgressCopyWithImpl;
@useResult
$Res call({
 DateTime dailyPeriodStart, DateTime weeklyPeriodStart, Map<String, int> baselines, List<String> claimedIds
});




}
/// @nodoc
class _$MissionsProgressCopyWithImpl<$Res>
    implements $MissionsProgressCopyWith<$Res> {
  _$MissionsProgressCopyWithImpl(this._self, this._then);

  final MissionsProgress _self;
  final $Res Function(MissionsProgress) _then;

/// Create a copy of MissionsProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dailyPeriodStart = null,Object? weeklyPeriodStart = null,Object? baselines = null,Object? claimedIds = null,}) {
  return _then(_self.copyWith(
dailyPeriodStart: null == dailyPeriodStart ? _self.dailyPeriodStart : dailyPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,weeklyPeriodStart: null == weeklyPeriodStart ? _self.weeklyPeriodStart : weeklyPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,baselines: null == baselines ? _self.baselines : baselines // ignore: cast_nullable_to_non_nullable
as Map<String, int>,claimedIds: null == claimedIds ? _self.claimedIds : claimedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MissionsProgress].
extension MissionsProgressPatterns on MissionsProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MissionsProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MissionsProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MissionsProgress value)  $default,){
final _that = this;
switch (_that) {
case _MissionsProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MissionsProgress value)?  $default,){
final _that = this;
switch (_that) {
case _MissionsProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime dailyPeriodStart,  DateTime weeklyPeriodStart,  Map<String, int> baselines,  List<String> claimedIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MissionsProgress() when $default != null:
return $default(_that.dailyPeriodStart,_that.weeklyPeriodStart,_that.baselines,_that.claimedIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime dailyPeriodStart,  DateTime weeklyPeriodStart,  Map<String, int> baselines,  List<String> claimedIds)  $default,) {final _that = this;
switch (_that) {
case _MissionsProgress():
return $default(_that.dailyPeriodStart,_that.weeklyPeriodStart,_that.baselines,_that.claimedIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime dailyPeriodStart,  DateTime weeklyPeriodStart,  Map<String, int> baselines,  List<String> claimedIds)?  $default,) {final _that = this;
switch (_that) {
case _MissionsProgress() when $default != null:
return $default(_that.dailyPeriodStart,_that.weeklyPeriodStart,_that.baselines,_that.claimedIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MissionsProgress implements MissionsProgress {
  const _MissionsProgress({required this.dailyPeriodStart, required this.weeklyPeriodStart, required final  Map<String, int> baselines, required final  List<String> claimedIds}): _baselines = baselines,_claimedIds = claimedIds;
  factory _MissionsProgress.fromJson(Map<String, dynamic> json) => _$MissionsProgressFromJson(json);

@override final  DateTime dailyPeriodStart;
@override final  DateTime weeklyPeriodStart;
 final  Map<String, int> _baselines;
@override Map<String, int> get baselines {
  if (_baselines is EqualUnmodifiableMapView) return _baselines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_baselines);
}

 final  List<String> _claimedIds;
@override List<String> get claimedIds {
  if (_claimedIds is EqualUnmodifiableListView) return _claimedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_claimedIds);
}


/// Create a copy of MissionsProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MissionsProgressCopyWith<_MissionsProgress> get copyWith => __$MissionsProgressCopyWithImpl<_MissionsProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MissionsProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MissionsProgress&&(identical(other.dailyPeriodStart, dailyPeriodStart) || other.dailyPeriodStart == dailyPeriodStart)&&(identical(other.weeklyPeriodStart, weeklyPeriodStart) || other.weeklyPeriodStart == weeklyPeriodStart)&&const DeepCollectionEquality().equals(other._baselines, _baselines)&&const DeepCollectionEquality().equals(other._claimedIds, _claimedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dailyPeriodStart,weeklyPeriodStart,const DeepCollectionEquality().hash(_baselines),const DeepCollectionEquality().hash(_claimedIds));

@override
String toString() {
  return 'MissionsProgress(dailyPeriodStart: $dailyPeriodStart, weeklyPeriodStart: $weeklyPeriodStart, baselines: $baselines, claimedIds: $claimedIds)';
}


}

/// @nodoc
abstract mixin class _$MissionsProgressCopyWith<$Res> implements $MissionsProgressCopyWith<$Res> {
  factory _$MissionsProgressCopyWith(_MissionsProgress value, $Res Function(_MissionsProgress) _then) = __$MissionsProgressCopyWithImpl;
@override @useResult
$Res call({
 DateTime dailyPeriodStart, DateTime weeklyPeriodStart, Map<String, int> baselines, List<String> claimedIds
});




}
/// @nodoc
class __$MissionsProgressCopyWithImpl<$Res>
    implements _$MissionsProgressCopyWith<$Res> {
  __$MissionsProgressCopyWithImpl(this._self, this._then);

  final _MissionsProgress _self;
  final $Res Function(_MissionsProgress) _then;

/// Create a copy of MissionsProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dailyPeriodStart = null,Object? weeklyPeriodStart = null,Object? baselines = null,Object? claimedIds = null,}) {
  return _then(_MissionsProgress(
dailyPeriodStart: null == dailyPeriodStart ? _self.dailyPeriodStart : dailyPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,weeklyPeriodStart: null == weeklyPeriodStart ? _self.weeklyPeriodStart : weeklyPeriodStart // ignore: cast_nullable_to_non_nullable
as DateTime,baselines: null == baselines ? _self._baselines : baselines // ignore: cast_nullable_to_non_nullable
as Map<String, int>,claimedIds: null == claimedIds ? _self._claimedIds : claimedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
