/// Battuta — Database & repository Riverpod providers.
///
/// Exposes the singleton [AppDatabase] and repository implementations
/// for songs, setlists, and scores.
library;

import 'dart:io';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/domain/repositories/setlist_repository.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:battuta/features/score/data/repositories/drift_score_repository.dart';
import 'package:battuta/features/score/domain/repositories/score_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the active [AppDatabase] instance.
///
/// Can be overridden in tests with an in-memory database:
/// ```dart
/// appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  final db = isTest ? AppDatabase(NativeDatabase.memory()) : AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides the offline [SongRepository] backed by Drift SQLite.
final driftSongRepositoryProvider = Provider<SongRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSongRepository(db);
});

/// Provides the offline [SetlistRepository] backed by Drift SQLite.
final setlistRepositoryProvider = Provider<SetlistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSetlistRepository(db);
});

/// Provides the offline [ScoreRepository] backed by Drift SQLite.
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftScoreRepository(db);
});

