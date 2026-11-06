/// Battuta — Section layout index for navigation and synchronization.
///
/// Records vertical Y-offsets and GlobalKeys for rendered score sections,
/// enabling instant scrolling to rehearsal marks and readiness for v1.1
/// remote stage presentation synchronization (e.g. ProPresenter triggers).
library;

import 'package:flutter/widgets.dart';

/// Entry representing a registered score section's layout coordinates.
class SectionLayoutEntry {
  const SectionLayoutEntry({
    required this.sectionId,
    required this.yOffset,
    this.key,
    this.externalSyncId,
    this.name,
  });

  /// The unique section ID within the score.
  final String sectionId;

  /// Vertical Y position (in logical canvas pixels) of the section header.
  final double yOffset;

  /// Optional [GlobalKey] attached to the section header widget.
  final GlobalKey? key;

  /// Optional external synchronization ID (e.g. ProPresenter Group UUID).
  final String? externalSyncId;

  /// Display name of the section (e.g. "Verse 1", "Chorus").
  final String? name;
}

/// Index holding coordinates of all sections in the active score layout.
class SectionLayoutIndex {
  final Map<String, SectionLayoutEntry> _entries = {};
  final Map<String, String> _syncIdToSectionId = {};
  final Map<String, String> _nameToSectionId = {};

  /// Registers or updates a section's vertical offset and metadata.
  void register({
    required String sectionId,
    required double yOffset,
    GlobalKey? key,
    String? externalSyncId,
    String? name,
  }) {
    final entry = SectionLayoutEntry(
      sectionId: sectionId,
      yOffset: yOffset,
      key: key,
      externalSyncId: externalSyncId,
      name: name,
    );

    _entries[sectionId] = entry;

    if (externalSyncId != null && externalSyncId.isNotEmpty) {
      _syncIdToSectionId[externalSyncId] = sectionId;
    }
    if (name != null && name.isNotEmpty) {
      _nameToSectionId[name.toLowerCase()] = sectionId;
    }
  }

  /// Retrieves the layout entry for [sectionId], [externalSyncId], or section [name].
  SectionLayoutEntry? getEntry(String identifier) {
    if (_entries.containsKey(identifier)) {
      return _entries[identifier];
    }
    final resolvedBySync = _syncIdToSectionId[identifier];
    if (resolvedBySync != null && _entries.containsKey(resolvedBySync)) {
      return _entries[resolvedBySync];
    }
    final resolvedByName = _nameToSectionId[identifier.toLowerCase()];
    if (resolvedByName != null && _entries.containsKey(resolvedByName)) {
      return _entries[resolvedByName];
    }
    return null;
  }

  /// Retrieves the vertical Y-offset for [identifier].
  double? getYOffset(String identifier) => getEntry(identifier)?.yOffset;

  /// Retrieves the [GlobalKey] for [identifier].
  GlobalKey? getKey(String identifier) => getEntry(identifier)?.key;

  /// Map of all section IDs to their vertical Y-offsets.
  Map<String, double> get allOffsets => {
        for (final entry in _entries.entries) entry.key: entry.value.yOffset,
      };

  /// Map of all section IDs to their registered [GlobalKey]s.
  Map<String, GlobalKey> get allKeys => {
        for (final entry in _entries.entries)
          if (entry.value.key != null) entry.key: entry.value.key!,
      };

  /// Count of registered sections.
  int get length => _entries.length;

  /// Clears all entries from the index.
  void clear() {
    _entries.clear();
    _syncIdToSectionId.clear();
    _nameToSectionId.clear();
  }
}
