// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SongSection {

/// Unique identifier for this section.
 String get id;/// Human-readable section name (e.g., `"Intro"`, `"Chorus"`, `"Bridge"`).
 String get name;/// Ordered chord cells that make up this section's chord chart.
 List<ChordCell> get chords;/// Optional lyrics for this section, displayed below or alongside chords.
 String? get lyrics;/// Private rehearsal notes (e.g., `"Hold last chord for 2 extra beats"`).
 String? get rehearsalNotes;/// How many times this section repeats during performance.
 int get repeatCount;/// Zero-based position of this section within the parent song.
 int get orderIndex;
/// Create a copy of SongSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongSectionCopyWith<SongSection> get copyWith => _$SongSectionCopyWithImpl<SongSection>(this as SongSection, _$identity);

  /// Serializes this SongSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SongSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongSection&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.chords, _this.chords)&&(identical(other.lyrics, _this.lyrics) || other.lyrics == _this.lyrics)&&(identical(other.rehearsalNotes, _this.rehearsalNotes) || other.rehearsalNotes == _this.rehearsalNotes)&&(identical(other.repeatCount, _this.repeatCount) || other.repeatCount == _this.repeatCount)&&(identical(other.orderIndex, _this.orderIndex) || other.orderIndex == _this.orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SongSection;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.chords),_this.lyrics,_this.rehearsalNotes,_this.repeatCount,_this.orderIndex);
}

@override
String toString() {
  final _this = this as SongSection;
  return 'SongSection(id: ${_this.id}, name: ${_this.name}, chords: ${_this.chords}, lyrics: ${_this.lyrics}, rehearsalNotes: ${_this.rehearsalNotes}, repeatCount: ${_this.repeatCount}, orderIndex: ${_this.orderIndex})';
}


}

/// @nodoc
abstract mixin class $SongSectionCopyWith<$Res>  {
  factory $SongSectionCopyWith(SongSection value, $Res Function(SongSection) _then) = _$SongSectionCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<ChordCell> chords, String? lyrics, String? rehearsalNotes, int repeatCount, int orderIndex
});




}
/// @nodoc
class _$SongSectionCopyWithImpl<$Res>
    implements $SongSectionCopyWith<$Res> {
  _$SongSectionCopyWithImpl(this._self, this._then);

  final SongSection _self;
  final $Res Function(SongSection) _then;

/// Create a copy of SongSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? chords = null,Object? lyrics = freezed,Object? rehearsalNotes = freezed,Object? repeatCount = null,Object? orderIndex = null,}) {
  return _then(SongSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,chords: null == chords ? _self.chords : chords // ignore: cast_nullable_to_non_nullable
as List<ChordCell>,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String?,rehearsalNotes: freezed == rehearsalNotes ? _self.rehearsalNotes : rehearsalNotes // ignore: cast_nullable_to_non_nullable
as String?,repeatCount: null == repeatCount ? _self.repeatCount : repeatCount // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SongSection].
extension SongSectionPatterns on SongSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SongSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SongSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SongSection value)  $default,){
final _that = this;
switch (_that) {
case _SongSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SongSection value)?  $default,){
final _that = this;
switch (_that) {
case _SongSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<ChordCell> chords,  String? lyrics,  String? rehearsalNotes,  int repeatCount,  int orderIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SongSection() when $default != null:
return $default(_that.id,_that.name,_that.chords,_that.lyrics,_that.rehearsalNotes,_that.repeatCount,_that.orderIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<ChordCell> chords,  String? lyrics,  String? rehearsalNotes,  int repeatCount,  int orderIndex)  $default,) {final _that = this;
switch (_that) {
case _SongSection():
return $default(_that.id,_that.name,_that.chords,_that.lyrics,_that.rehearsalNotes,_that.repeatCount,_that.orderIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<ChordCell> chords,  String? lyrics,  String? rehearsalNotes,  int repeatCount,  int orderIndex)?  $default,) {final _that = this;
switch (_that) {
case _SongSection() when $default != null:
return $default(_that.id,_that.name,_that.chords,_that.lyrics,_that.rehearsalNotes,_that.repeatCount,_that.orderIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SongSection implements SongSection {
  const _SongSection({required this.id, required this.name,  List<ChordCell> chords = const [], this.lyrics, this.rehearsalNotes, this.repeatCount = 1, required this.orderIndex}): _chords = chords;
  factory _SongSection.fromJson(Map<String, dynamic> json) => _$SongSectionFromJson(json);

/// Unique identifier for this section.
@override final  String id;
/// Human-readable section name (e.g., `"Intro"`, `"Chorus"`, `"Bridge"`).
@override final  String name;
/// Ordered chord cells that make up this section's chord chart.
 final  List<ChordCell> _chords;
/// Ordered chord cells that make up this section's chord chart.
@override@JsonKey() List<ChordCell> get chords {
  if (_chords is EqualUnmodifiableListView) return _chords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chords);
}

/// Optional lyrics for this section, displayed below or alongside chords.
@override final  String? lyrics;
/// Private rehearsal notes (e.g., `"Hold last chord for 2 extra beats"`).
@override final  String? rehearsalNotes;
/// How many times this section repeats during performance.
@override@JsonKey() final  int repeatCount;
/// Zero-based position of this section within the parent song.
@override final  int orderIndex;

/// Create a copy of SongSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongSectionCopyWith<_SongSection> get copyWith => __$SongSectionCopyWithImpl<_SongSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongSection&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.chords, _chords)&&(identical(other.lyrics, lyrics) || other.lyrics == lyrics)&&(identical(other.rehearsalNotes, rehearsalNotes) || other.rehearsalNotes == rehearsalNotes)&&(identical(other.repeatCount, repeatCount) || other.repeatCount == repeatCount)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_chords),lyrics,rehearsalNotes,repeatCount,orderIndex);
}

@override
String toString() {
    return 'SongSection(id: $id, name: $name, chords: $chords, lyrics: $lyrics, rehearsalNotes: $rehearsalNotes, repeatCount: $repeatCount, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class _$SongSectionCopyWith<$Res> implements $SongSectionCopyWith<$Res> {
  factory _$SongSectionCopyWith(_SongSection value, $Res Function(_SongSection) _then) = __$SongSectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<ChordCell> chords, String? lyrics, String? rehearsalNotes, int repeatCount, int orderIndex
});




}
/// @nodoc
class __$SongSectionCopyWithImpl<$Res>
    implements _$SongSectionCopyWith<$Res> {
  __$SongSectionCopyWithImpl(this._self, this._then);

  final _SongSection _self;
  final $Res Function(_SongSection) _then;

/// Create a copy of SongSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? chords = null,Object? lyrics = freezed,Object? rehearsalNotes = freezed,Object? repeatCount = null,Object? orderIndex = null,}) {
  return _then(_SongSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,chords: null == chords ? _self._chords : chords // ignore: cast_nullable_to_non_nullable
as List<ChordCell>,lyrics: freezed == lyrics ? _self.lyrics : lyrics // ignore: cast_nullable_to_non_nullable
as String?,rehearsalNotes: freezed == rehearsalNotes ? _self.rehearsalNotes : rehearsalNotes // ignore: cast_nullable_to_non_nullable
as String?,repeatCount: null == repeatCount ? _self.repeatCount : repeatCount // ignore: cast_nullable_to_non_nullable
as int,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
