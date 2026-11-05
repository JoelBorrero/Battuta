// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SongSection _$SongSectionFromJson(Map<String, dynamic> json) => _SongSection(
  id: json['id'] as String,
  name: json['name'] as String,
  chords:
      (json['chords'] as List<dynamic>?)
          ?.map((e) => ChordCell.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  lyrics: json['lyrics'] as String?,
  rehearsalNotes: json['rehearsalNotes'] as String?,
  repeatCount: (json['repeatCount'] as num?)?.toInt() ?? 1,
  orderIndex: (json['orderIndex'] as num).toInt(),
);

Map<String, dynamic> _$SongSectionToJson(_SongSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'chords': instance.chords,
      'lyrics': instance.lyrics,
      'rehearsalNotes': instance.rehearsalNotes,
      'repeatCount': instance.repeatCount,
      'orderIndex': instance.orderIndex,
    };
