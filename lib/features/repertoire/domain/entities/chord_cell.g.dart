// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chord_cell.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChordCell _$ChordCellFromJson(Map<String, dynamic> json) => _ChordCell(
  root: json['root'] as String,
  quality:
      $enumDecodeNullable(_$ChordQualityEnumMap, json['quality']) ??
      ChordQuality.major,
  bass: json['bass'] as String?,
  extensions:
      (json['extensions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  beats: (json['beats'] as num?)?.toInt() ?? 4,
  customLabel: json['customLabel'] as String?,
);

Map<String, dynamic> _$ChordCellToJson(_ChordCell instance) =>
    <String, dynamic>{
      'root': instance.root,
      'quality': _$ChordQualityEnumMap[instance.quality]!,
      'bass': instance.bass,
      'extensions': instance.extensions,
      'beats': instance.beats,
      'customLabel': instance.customLabel,
    };

const _$ChordQualityEnumMap = {
  ChordQuality.major: 'major',
  ChordQuality.minor: 'minor',
  ChordQuality.diminished: 'diminished',
  ChordQuality.augmented: 'augmented',
  ChordQuality.dominant7: 'dominant7',
  ChordQuality.major7: 'major7',
  ChordQuality.minor7: 'minor7',
  ChordQuality.sus2: 'sus2',
  ChordQuality.sus4: 'sus4',
  ChordQuality.add9: 'add9',
  ChordQuality.custom: 'custom',
};
