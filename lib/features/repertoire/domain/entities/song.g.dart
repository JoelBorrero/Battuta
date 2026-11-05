// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Song _$SongFromJson(Map<String, dynamic> json) => _Song(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  key: json['key'] as String,
  tempo: (json['tempo'] as num).toInt(),
  timeSignature:
      _$recordConvertNullable(
        json['timeSignature'],
        ($jsonValue) => (
          ($jsonValue[r'$1'] as num).toInt(),
          ($jsonValue[r'$2'] as num).toInt(),
        ),
      ) ??
      const (4, 4),
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => SongSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  coverImagePath: json['coverImagePath'] as String?,
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SongToJson(_Song instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artist': instance.artist,
  'key': instance.key,
  'tempo': instance.tempo,
  'timeSignature': <String, dynamic>{
    r'$1': instance.timeSignature.$1,
    r'$2': instance.timeSignature.$2,
  },
  'sections': instance.sections,
  'tags': instance.tags,
  'coverImagePath': instance.coverImagePath,
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

$Rec? _$recordConvertNullable<$Rec>(
  Object? value,
  $Rec Function(Map) convert,
) => value == null ? null : convert(value as Map<String, dynamic>);
