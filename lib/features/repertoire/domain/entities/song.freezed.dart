// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Song {

/// Unique identifier for this song.
 String get id;/// The song title.
 String get title;/// The performing artist or original composer.
 String get artist;/// The musical key as a string (e.g., `"C"`, `"G#m"`, `"Bb"`).
///
/// Use [MusicalKey.fromString] when you need transposition or
/// music-theory operations.
 String get key;/// Tempo in beats per minute.
 int get tempo;/// Time signature expressed as a record of `(beats, beatValue)`.
///
/// For example, 4/4 time is `(4, 4)` and 6/8 time is `(6, 8)`.
 (int, int,) get timeSignature;/// Ordered sections that compose this song's lead sheet.
 List<SongSection> get sections;/// Free-form tags for categorization (e.g., `["worship", "hymn"]`).
 List<String> get tags;/// Optional local path to a cover image.
 String? get coverImagePath;/// Optional free-text notes about the song.
 String? get notes;/// Timestamp when the song was first created.
 DateTime get createdAt;/// Timestamp of the last modification.
 DateTime get updatedAt;/// Id of the work (`songs.id`) this version belongs to; null until synced.
 String? get songWorkId;/// Account that owns this version; null for local-mode songs.
 String? get ownerId;/// Name of this arrangement (e.g. `"Original"`, `"Acoustic"`).
 String get label;/// Who can see this version.
 SongVisibility get visibility;/// Version this one was forked from, if any.
 String? get forkedFromVersionId;/// Organizations this version is shared with (visibility `organizations`).
 List<String> get sharedOrganizationIds;
/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SongCopyWith<Song> get copyWith => _$SongCopyWithImpl<Song>(this as Song, _$identity);

  /// Serializes this Song to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Song;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Song&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.tempo, _this.tempo) || other.tempo == _this.tempo)&&(identical(other.timeSignature, _this.timeSignature) || other.timeSignature == _this.timeSignature)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&(identical(other.coverImagePath, _this.coverImagePath) || other.coverImagePath == _this.coverImagePath)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.songWorkId, _this.songWorkId) || other.songWorkId == _this.songWorkId)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.visibility, _this.visibility) || other.visibility == _this.visibility)&&(identical(other.forkedFromVersionId, _this.forkedFromVersionId) || other.forkedFromVersionId == _this.forkedFromVersionId)&&const DeepCollectionEquality().equals(other.sharedOrganizationIds, _this.sharedOrganizationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Song;
  return Object.hash(runtimeType,_this.id,_this.title,_this.artist,_this.key,_this.tempo,_this.timeSignature,const DeepCollectionEquality().hash(_this.sections),const DeepCollectionEquality().hash(_this.tags),_this.coverImagePath,_this.notes,_this.createdAt,_this.updatedAt,_this.songWorkId,_this.ownerId,_this.label,_this.visibility,_this.forkedFromVersionId,const DeepCollectionEquality().hash(_this.sharedOrganizationIds));
}

@override
String toString() {
  final _this = this as Song;
  return 'Song(id: ${_this.id}, title: ${_this.title}, artist: ${_this.artist}, key: ${_this.key}, tempo: ${_this.tempo}, timeSignature: ${_this.timeSignature}, sections: ${_this.sections}, tags: ${_this.tags}, coverImagePath: ${_this.coverImagePath}, notes: ${_this.notes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, songWorkId: ${_this.songWorkId}, ownerId: ${_this.ownerId}, label: ${_this.label}, visibility: ${_this.visibility}, forkedFromVersionId: ${_this.forkedFromVersionId}, sharedOrganizationIds: ${_this.sharedOrganizationIds})';
}


}

/// @nodoc
abstract mixin class $SongCopyWith<$Res>  {
  factory $SongCopyWith(Song value, $Res Function(Song) _then) = _$SongCopyWithImpl;
@useResult
$Res call({
 String id, String title, String artist, String key, int tempo, (int, int,) timeSignature, List<SongSection> sections, List<String> tags, String? coverImagePath, String? notes, DateTime createdAt, DateTime updatedAt, String? songWorkId, String? ownerId, String label, SongVisibility visibility, String? forkedFromVersionId, List<String> sharedOrganizationIds
});




}
/// @nodoc
class _$SongCopyWithImpl<$Res>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._self, this._then);

  final Song _self;
  final $Res Function(Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? artist = null,Object? key = null,Object? tempo = null,Object? timeSignature = null,Object? sections = null,Object? tags = null,Object? coverImagePath = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? songWorkId = freezed,Object? ownerId = freezed,Object? label = null,Object? visibility = null,Object? forkedFromVersionId = freezed,Object? sharedOrganizationIds = null,}) {
  return _then(Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as int,timeSignature: null == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as (int, int,),sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<SongSection>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,coverImagePath: freezed == coverImagePath ? _self.coverImagePath : coverImagePath // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,songWorkId: freezed == songWorkId ? _self.songWorkId : songWorkId // ignore: cast_nullable_to_non_nullable
as String?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SongVisibility,forkedFromVersionId: freezed == forkedFromVersionId ? _self.forkedFromVersionId : forkedFromVersionId // ignore: cast_nullable_to_non_nullable
as String?,sharedOrganizationIds: null == sharedOrganizationIds ? _self.sharedOrganizationIds : sharedOrganizationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Song].
extension SongPatterns on Song {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Song value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Song() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Song value)  $default,){
final _that = this;
switch (_that) {
case _Song():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Song value)?  $default,){
final _that = this;
switch (_that) {
case _Song() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String artist,  String key,  int tempo,  (int, int,) timeSignature,  List<SongSection> sections,  List<String> tags,  String? coverImagePath,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? songWorkId,  String? ownerId,  String label,  SongVisibility visibility,  String? forkedFromVersionId,  List<String> sharedOrganizationIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.key,_that.tempo,_that.timeSignature,_that.sections,_that.tags,_that.coverImagePath,_that.notes,_that.createdAt,_that.updatedAt,_that.songWorkId,_that.ownerId,_that.label,_that.visibility,_that.forkedFromVersionId,_that.sharedOrganizationIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String artist,  String key,  int tempo,  (int, int,) timeSignature,  List<SongSection> sections,  List<String> tags,  String? coverImagePath,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? songWorkId,  String? ownerId,  String label,  SongVisibility visibility,  String? forkedFromVersionId,  List<String> sharedOrganizationIds)  $default,) {final _that = this;
switch (_that) {
case _Song():
return $default(_that.id,_that.title,_that.artist,_that.key,_that.tempo,_that.timeSignature,_that.sections,_that.tags,_that.coverImagePath,_that.notes,_that.createdAt,_that.updatedAt,_that.songWorkId,_that.ownerId,_that.label,_that.visibility,_that.forkedFromVersionId,_that.sharedOrganizationIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String artist,  String key,  int tempo,  (int, int,) timeSignature,  List<SongSection> sections,  List<String> tags,  String? coverImagePath,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? songWorkId,  String? ownerId,  String label,  SongVisibility visibility,  String? forkedFromVersionId,  List<String> sharedOrganizationIds)?  $default,) {final _that = this;
switch (_that) {
case _Song() when $default != null:
return $default(_that.id,_that.title,_that.artist,_that.key,_that.tempo,_that.timeSignature,_that.sections,_that.tags,_that.coverImagePath,_that.notes,_that.createdAt,_that.updatedAt,_that.songWorkId,_that.ownerId,_that.label,_that.visibility,_that.forkedFromVersionId,_that.sharedOrganizationIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Song extends Song {
  const _Song({required this.id, required this.title, required this.artist, required this.key, required this.tempo, this.timeSignature = const (4, 4),  List<SongSection> sections = const [],  List<String> tags = const [], this.coverImagePath, this.notes, required this.createdAt, required this.updatedAt, this.songWorkId, this.ownerId, this.label = 'Original', this.visibility = SongVisibility.private, this.forkedFromVersionId,  List<String> sharedOrganizationIds = const []}): _sections = sections,_tags = tags,_sharedOrganizationIds = sharedOrganizationIds,super._();
  factory _Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

/// Unique identifier for this song.
@override final  String id;
/// The song title.
@override final  String title;
/// The performing artist or original composer.
@override final  String artist;
/// The musical key as a string (e.g., `"C"`, `"G#m"`, `"Bb"`).
///
/// Use [MusicalKey.fromString] when you need transposition or
/// music-theory operations.
@override final  String key;
/// Tempo in beats per minute.
@override final  int tempo;
/// Time signature expressed as a record of `(beats, beatValue)`.
///
/// For example, 4/4 time is `(4, 4)` and 6/8 time is `(6, 8)`.
@override@JsonKey() final  (int, int,) timeSignature;
/// Ordered sections that compose this song's lead sheet.
 final  List<SongSection> _sections;
/// Ordered sections that compose this song's lead sheet.
@override@JsonKey() List<SongSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Free-form tags for categorization (e.g., `["worship", "hymn"]`).
 final  List<String> _tags;
/// Free-form tags for categorization (e.g., `["worship", "hymn"]`).
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Optional local path to a cover image.
@override final  String? coverImagePath;
/// Optional free-text notes about the song.
@override final  String? notes;
/// Timestamp when the song was first created.
@override final  DateTime createdAt;
/// Timestamp of the last modification.
@override final  DateTime updatedAt;
/// Id of the work (`songs.id`) this version belongs to; null until synced.
@override final  String? songWorkId;
/// Account that owns this version; null for local-mode songs.
@override final  String? ownerId;
/// Name of this arrangement (e.g. `"Original"`, `"Acoustic"`).
@override@JsonKey() final  String label;
/// Who can see this version.
@override@JsonKey() final  SongVisibility visibility;
/// Version this one was forked from, if any.
@override final  String? forkedFromVersionId;
/// Organizations this version is shared with (visibility `organizations`).
 final  List<String> _sharedOrganizationIds;
/// Organizations this version is shared with (visibility `organizations`).
@override@JsonKey() List<String> get sharedOrganizationIds {
  if (_sharedOrganizationIds is EqualUnmodifiableListView) return _sharedOrganizationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sharedOrganizationIds);
}


/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SongCopyWith<_Song> get copyWith => __$SongCopyWithImpl<_Song>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SongToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Song&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.key, key) || other.key == key)&&(identical(other.tempo, tempo) || other.tempo == tempo)&&(identical(other.timeSignature, timeSignature) || other.timeSignature == timeSignature)&&const DeepCollectionEquality().equals(other.sections, _sections)&&const DeepCollectionEquality().equals(other.tags, _tags)&&(identical(other.coverImagePath, coverImagePath) || other.coverImagePath == coverImagePath)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.songWorkId, songWorkId) || other.songWorkId == songWorkId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.label, label) || other.label == label)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.forkedFromVersionId, forkedFromVersionId) || other.forkedFromVersionId == forkedFromVersionId)&&const DeepCollectionEquality().equals(other.sharedOrganizationIds, _sharedOrganizationIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,artist,key,tempo,timeSignature,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_tags),coverImagePath,notes,createdAt,updatedAt,songWorkId,ownerId,label,visibility,forkedFromVersionId,const DeepCollectionEquality().hash(_sharedOrganizationIds));
}

@override
String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, key: $key, tempo: $tempo, timeSignature: $timeSignature, sections: $sections, tags: $tags, coverImagePath: $coverImagePath, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, songWorkId: $songWorkId, ownerId: $ownerId, label: $label, visibility: $visibility, forkedFromVersionId: $forkedFromVersionId, sharedOrganizationIds: $sharedOrganizationIds)';
}


}

/// @nodoc
abstract mixin class _$SongCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$SongCopyWith(_Song value, $Res Function(_Song) _then) = __$SongCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String artist, String key, int tempo, (int, int,) timeSignature, List<SongSection> sections, List<String> tags, String? coverImagePath, String? notes, DateTime createdAt, DateTime updatedAt, String? songWorkId, String? ownerId, String label, SongVisibility visibility, String? forkedFromVersionId, List<String> sharedOrganizationIds
});




}
/// @nodoc
class __$SongCopyWithImpl<$Res>
    implements _$SongCopyWith<$Res> {
  __$SongCopyWithImpl(this._self, this._then);

  final _Song _self;
  final $Res Function(_Song) _then;

/// Create a copy of Song
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? artist = null,Object? key = null,Object? tempo = null,Object? timeSignature = null,Object? sections = null,Object? tags = null,Object? coverImagePath = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? songWorkId = freezed,Object? ownerId = freezed,Object? label = null,Object? visibility = null,Object? forkedFromVersionId = freezed,Object? sharedOrganizationIds = null,}) {
  return _then(_Song(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as int,timeSignature: null == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as (int, int,),sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<SongSection>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,coverImagePath: freezed == coverImagePath ? _self.coverImagePath : coverImagePath // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,songWorkId: freezed == songWorkId ? _self.songWorkId : songWorkId // ignore: cast_nullable_to_non_nullable
as String?,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as SongVisibility,forkedFromVersionId: freezed == forkedFromVersionId ? _self.forkedFromVersionId : forkedFromVersionId // ignore: cast_nullable_to_non_nullable
as String?,sharedOrganizationIds: null == sharedOrganizationIds ? _self._sharedOrganizationIds : sharedOrganizationIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
