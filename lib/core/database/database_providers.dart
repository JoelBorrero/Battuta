/// Battuta — Database & repository Riverpod providers.
///
/// Exposes the singleton [AppDatabase] and repository implementations
/// for songs, setlists, and scores.
library;

import 'dart:io';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_setlist_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart';
import 'package:battuta/features/repertoire/data/repositories/in_memory_setlist_repository.dart';
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
  return DriftSongRepository(db, session: ref.watch(accountSessionProvider));
});

/// The Drift setlist repository. Organization setlists are editable only by
/// the admins of that organization, read from the account's memberships at the
/// time of each write (so a role change applies without rebuilding it).
final driftSetlistRepositoryProvider = Provider<SetlistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSetlistRepository(
    db,
    session: ref.watch(accountSessionProvider),
    canAdministerOrganization: (organizationId) =>
        ref.read(organizationAdminCheckProvider)(organizationId),
  );
});

/// Provides the offline [SetlistRepository] backed by Drift SQLite.
final setlistRepositoryProvider = Provider<SetlistRepository>((ref) {
  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  if (isTest) {
    return InMemorySetlistRepository();
  }
  return ref.watch(driftSetlistRepositoryProvider);
});

/// Provides the offline [ScoreRepository] backed by Drift SQLite.
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftScoreRepository(db, session: ref.watch(accountSessionProvider));
});
