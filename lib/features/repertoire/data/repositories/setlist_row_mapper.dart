/// Maps Drift setlist rows to the [Setlist] entity.
library;

import 'dart:convert';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist_item.dart';

/// Converts a [SetlistEntry] row into a [Setlist].
Setlist setlistFromRow(SetlistEntry row) {
  final items = (jsonDecode(row.itemsJson) as List<dynamic>)
      .map((i) => SetlistItem.fromJson(i as Map<String, dynamic>))
      .toList();
  final tags = (jsonDecode(row.tagsJson) as List<dynamic>)
      .map((t) => t as String)
      .toList();
  return Setlist(
    id: row.id,
    title: row.title,
    description: row.description,
    eventDate: row.eventDate,
    items: items,
    tags: tags,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    organizationId: row.organizationId,
  );
}
