/// Maps Drift song rows to the [Song] entity.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';

/// Converts a [SongEntry] row into a [Song].
Song songFromRow(SongEntry row) {
  final sections = (jsonDecode(row.sectionsJson) as List<dynamic>)
      .map((s) => SongSection.fromJson(s as Map<String, dynamic>))
      .toList();
  final tags = (jsonDecode(row.tagsJson) as List<dynamic>)
      .map((t) => t as String)
      .toList();
  return Song(
    id: row.id,
    title: row.title,
    artist: row.artist,
    key: row.key,
    tempo: row.tempo,
    timeSignature: (row.timeSignatureBeats, row.timeSignatureBeatValue),
    sections: sections,
    tags: tags,
    coverImagePath: row.coverImagePath,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    songWorkId: row.songWorkId,
    ownerId: row.ownerId,
    label: row.label,
    visibility: SongVisibility.parse(row.visibility),
    forkedFromVersionId: row.forkedFromVersionId,
    sharedOrganizationIds: decodeStringList(row.sharedOrganizationIdsJson),
    songCreatorId: row.songCreatorId,
  );
}

/// Decodes a JSON array of strings; anything else yields an empty list.
List<String> decodeStringList(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) return [for (final e in decoded) e.toString()];
  } catch (_) {
    // Fall through.
  }
  return const [];
}
