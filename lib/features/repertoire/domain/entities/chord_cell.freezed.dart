// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chord_cell.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChordCell {

/// The root note of the chord (e.g., `"C"`, `"F#"`, `"Bb"`).
 String get root;/// The harmonic quality of the chord.
 ChordQuality get quality;/// Optional bass note for slash chords (e.g., `"E"` in `"C/E"`).
 String? get bass;/// Additional chord extensions such as `["9", "13"]`.
 List<String> get extensions;/// Number of beats this chord spans in the bar.
 int get beats;/// An optional custom label for non-standard chord names.
///
/// When provided and [quality] is [ChordQuality.custom], this label
/// is used as-is for display instead of computing root + quality symbol.
 String? get customLabel;
/// Create a copy of ChordCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChordCellCopyWith<ChordCell> get copyWith => _$ChordCellCopyWithImpl<ChordCell>(this as ChordCell, _$identity);

  /// Serializes this ChordCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChordCell;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChordCell&&(identical(other.root, _this.root) || other.root == _this.root)&&(identical(other.quality, _this.quality) || other.quality == _this.quality)&&(identical(other.bass, _this.bass) || other.bass == _this.bass)&&const DeepCollectionEquality().equals(other.extensions, _this.extensions)&&(identical(other.beats, _this.beats) || other.beats == _this.beats)&&(identical(other.customLabel, _this.customLabel) || other.customLabel == _this.customLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChordCell;
  return Object.hash(runtimeType,_this.root,_this.quality,_this.bass,const DeepCollectionEquality().hash(_this.extensions),_this.beats,_this.customLabel);
}

@override
String toString() {
  final _this = this as ChordCell;
  return 'ChordCell(root: ${_this.root}, quality: ${_this.quality}, bass: ${_this.bass}, extensions: ${_this.extensions}, beats: ${_this.beats}, customLabel: ${_this.customLabel})';
}


}

/// @nodoc
abstract mixin class $ChordCellCopyWith<$Res>  {
  factory $ChordCellCopyWith(ChordCell value, $Res Function(ChordCell) _then) = _$ChordCellCopyWithImpl;
@useResult
$Res call({
 String root, ChordQuality quality, String? bass, List<String> extensions, int beats, String? customLabel
});




}
/// @nodoc
class _$ChordCellCopyWithImpl<$Res>
    implements $ChordCellCopyWith<$Res> {
  _$ChordCellCopyWithImpl(this._self, this._then);

  final ChordCell _self;
  final $Res Function(ChordCell) _then;

/// Create a copy of ChordCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? root = null,Object? quality = null,Object? bass = freezed,Object? extensions = null,Object? beats = null,Object? customLabel = freezed,}) {
  return _then(ChordCell(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as ChordQuality,bass: freezed == bass ? _self.bass : bass // ignore: cast_nullable_to_non_nullable
as String?,extensions: null == extensions ? _self.extensions : extensions // ignore: cast_nullable_to_non_nullable
as List<String>,beats: null == beats ? _self.beats : beats // ignore: cast_nullable_to_non_nullable
as int,customLabel: freezed == customLabel ? _self.customLabel : customLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChordCell].
extension ChordCellPatterns on ChordCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChordCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChordCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChordCell value)  $default,){
final _that = this;
switch (_that) {
case _ChordCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChordCell value)?  $default,){
final _that = this;
switch (_that) {
case _ChordCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String root,  ChordQuality quality,  String? bass,  List<String> extensions,  int beats,  String? customLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChordCell() when $default != null:
return $default(_that.root,_that.quality,_that.bass,_that.extensions,_that.beats,_that.customLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String root,  ChordQuality quality,  String? bass,  List<String> extensions,  int beats,  String? customLabel)  $default,) {final _that = this;
switch (_that) {
case _ChordCell():
return $default(_that.root,_that.quality,_that.bass,_that.extensions,_that.beats,_that.customLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String root,  ChordQuality quality,  String? bass,  List<String> extensions,  int beats,  String? customLabel)?  $default,) {final _that = this;
switch (_that) {
case _ChordCell() when $default != null:
return $default(_that.root,_that.quality,_that.bass,_that.extensions,_that.beats,_that.customLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChordCell extends ChordCell {
  const _ChordCell({required this.root, this.quality = ChordQuality.major, this.bass,  List<String> extensions = const [], this.beats = 4, this.customLabel}): _extensions = extensions,super._();
  factory _ChordCell.fromJson(Map<String, dynamic> json) => _$ChordCellFromJson(json);

/// The root note of the chord (e.g., `"C"`, `"F#"`, `"Bb"`).
@override final  String root;
/// The harmonic quality of the chord.
@override@JsonKey() final  ChordQuality quality;
/// Optional bass note for slash chords (e.g., `"E"` in `"C/E"`).
@override final  String? bass;
/// Additional chord extensions such as `["9", "13"]`.
 final  List<String> _extensions;
/// Additional chord extensions such as `["9", "13"]`.
@override@JsonKey() List<String> get extensions {
  if (_extensions is EqualUnmodifiableListView) return _extensions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_extensions);
}

/// Number of beats this chord spans in the bar.
@override@JsonKey() final  int beats;
/// An optional custom label for non-standard chord names.
///
/// When provided and [quality] is [ChordQuality.custom], this label
/// is used as-is for display instead of computing root + quality symbol.
@override final  String? customLabel;

/// Create a copy of ChordCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChordCellCopyWith<_ChordCell> get copyWith => __$ChordCellCopyWithImpl<_ChordCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChordCellToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChordCell&&(identical(other.root, root) || other.root == root)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.bass, bass) || other.bass == bass)&&const DeepCollectionEquality().equals(other.extensions, _extensions)&&(identical(other.beats, beats) || other.beats == beats)&&(identical(other.customLabel, customLabel) || other.customLabel == customLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,root,quality,bass,const DeepCollectionEquality().hash(_extensions),beats,customLabel);
}

@override
String toString() {
    return 'ChordCell(root: $root, quality: $quality, bass: $bass, extensions: $extensions, beats: $beats, customLabel: $customLabel)';
}


}

/// @nodoc
abstract mixin class _$ChordCellCopyWith<$Res> implements $ChordCellCopyWith<$Res> {
  factory _$ChordCellCopyWith(_ChordCell value, $Res Function(_ChordCell) _then) = __$ChordCellCopyWithImpl;
@override @useResult
$Res call({
 String root, ChordQuality quality, String? bass, List<String> extensions, int beats, String? customLabel
});




}
/// @nodoc
class __$ChordCellCopyWithImpl<$Res>
    implements _$ChordCellCopyWith<$Res> {
  __$ChordCellCopyWithImpl(this._self, this._then);

  final _ChordCell _self;
  final $Res Function(_ChordCell) _then;

/// Create a copy of ChordCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? root = null,Object? quality = null,Object? bass = freezed,Object? extensions = null,Object? beats = null,Object? customLabel = freezed,}) {
  return _then(_ChordCell(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as ChordQuality,bass: freezed == bass ? _self.bass : bass // ignore: cast_nullable_to_non_nullable
as String?,extensions: null == extensions ? _self._extensions : extensions // ignore: cast_nullable_to_non_nullable
as List<String>,beats: null == beats ? _self.beats : beats // ignore: cast_nullable_to_non_nullable
as int,customLabel: freezed == customLabel ? _self.customLabel : customLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
