/// Battuta — Local Backing Stem Storage Manager.
///
/// Manages multi-track backing stems (Click, Guide, Keys, Bass, Drums, Vocals)
/// per song in offline-first local storage.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

@immutable
class StemTrack {
  const StemTrack({
    required this.id,
    required this.name,
    required this.filePath,
    this.volume = 1.0,
    this.isMuted = false,
    this.isSolo = false,
  });

  /// Unique stem identifier (e.g. "stem_click_01").
  final String id;

  /// Musical track label (e.g. "Click", "Guide", "Keys", "Bass", "Drums").
  final String name;

  /// Local absolute or relative filesystem path.
  final String filePath;

  /// Gain multiplier between 0.0 (silent) and 1.0 (unity).
  final double volume;

  /// Whether this track is temporarily muted.
  final bool isMuted;

  /// Whether this track is soloed in the rehearsal monitor.
  final bool isSolo;

  factory StemTrack.fromJson(Map<String, dynamic> json) {
    return StemTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: (json['isMuted'] as bool?) ?? false,
      isSolo: (json['isSolo'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'volume': volume,
      'isMuted': isMuted,
      'isSolo': isSolo,
    };
  }

  StemTrack copyWith({
    String? id,
    String? name,
    String? filePath,
    double? volume,
    bool? isMuted,
    bool? isSolo,
  }) {
    return StemTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StemTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          filePath == other.filePath &&
          volume == other.volume &&
          isMuted == other.isMuted &&
          isSolo == other.isSolo;

  @override
  int get hashCode => Object.hash(id, name, filePath, volume, isMuted, isSolo);

  @override
  String toString() =>
      'StemTrack(id: $id, name: $name, path: $filePath, vol: $volume, muted: $isMuted, solo: $isSolo)';
}

/// Service managing offline multi-track backing stems on disk.
class LocalStemStorageService {
  LocalStemStorageService({FutureOr<Directory> Function()? baseDirResolver})
    : _baseDirResolver = baseDirResolver ?? _defaultBaseDirResolver;

  final FutureOr<Directory> Function() _baseDirResolver;

  static Directory _defaultBaseDirResolver() {
    return Directory('${Directory.systemTemp.path}/battuta_stems');
  }

  Future<File> _getFileForSong(String songId) async {
    final baseDir = await _baseDirResolver();
    if (!baseDir.existsSync()) {
      baseDir.createSync(recursive: true);
    }
    // Sanitize songId for filename safety
    final safeId = songId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${baseDir.path}/stems_$safeId.json');
  }

  /// Retrieves all registered stems for [songId].
  Future<List<StemTrack>> getStemsForSong(String songId) async {
    try {
      final file = await _getFileForSong(songId);
      if (!file.existsSync()) {
        return const [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return const [];

      final list = jsonDecode(contents) as List<dynamic>;
      return list
          .map((item) => StemTrack.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Overwrites the full list of stems for [songId].
  Future<void> saveStemsForSong(String songId, List<StemTrack> stems) async {
    final file = await _getFileForSong(songId);
    final jsonList = stems.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Appends or updates a single [StemTrack] for [songId].
  Future<void> registerStemTrack(String songId, StemTrack stem) async {
    final stems = await getStemsForSong(songId);
    final existingIndex = stems.indexWhere((s) => s.id == stem.id);

    final updated = List<StemTrack>.from(stems);
    if (existingIndex >= 0) {
      updated[existingIndex] = stem;
    } else {
      updated.add(stem);
    }

    await saveStemsForSong(songId, updated);
  }

  /// Removes a stem by [stemId] for [songId].
  Future<void> deleteStemTrack(String songId, String stemId) async {
    final stems = await getStemsForSong(songId);
    final updated = stems.where((s) => s.id != stemId).toList();
    await saveStemsForSong(songId, updated);
  }

  /// Clears all stems stored for [songId].
  Future<void> clearAllStems(String songId) async {
    final file = await _getFileForSong(songId);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
