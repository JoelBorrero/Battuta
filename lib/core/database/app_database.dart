/// Battuta — Offline SQLite embedded database using Drift.
///
/// Provides type-safe persistence for songs, setlists, and complete Score trees
/// in full offline Airplane Mode.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Table storing repertoire songs.
@DataClassName('SongEntry')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get key => text()();
  IntColumn get tempo => integer()();
  IntColumn get timeSignatureBeats =>
      integer().withDefault(const Constant(4))();
  IntColumn get timeSignatureBeatValue =>
      integer().withDefault(const Constant(4))();
  TextColumn get sectionsJson => text().withDefault(const Constant('[]'))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get coverImagePath => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table storing rehearsal and performance setlists.
@DataClassName('SetlistEntry')
class Setlists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get eventDate => dateTime().nullable()();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table storing full Score trees with lossless JSON serialization.
@DataClassName('ScoreEntry')
class Scores extends Table {
  TextColumn get id => text()();
  TextColumn get songId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get composer => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get timeSignatureJson => text()();
  TextColumn get keySignature => text()();
  IntColumn get tempo => integer()();
  TextColumn get sectionsJson => text()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Offline cache of backend rows (organizations, members, bands, invites,
/// notifications, events, assignments, absences, ...), one row per record.
///
/// Every row belongs to the signed-in account [accountId], so signing out or
/// switching account can drop the previous account's data. [recordKind]
/// names the entity (e.g. `member`), [scopeId] is the organization the row
/// belongs to (empty for account-level rows) and [json] is the entity JSON.
@DataClassName('CacheRecordEntry')
class CacheRecords extends Table {
  TextColumn get accountId => text()();
  TextColumn get recordKind => text()();
  TextColumn get recordId => text()();
  TextColumn get scopeId => text().withDefault(const Constant(''))();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {accountId, recordKind, recordId};
}

/// When each cached collection was last refreshed from the backend.
@DataClassName('CacheRefreshEntry')
class CacheRefreshes extends Table {
  TextColumn get accountId => text()();
  TextColumn get recordKind => text()();
  TextColumn get scopeId => text().withDefault(const Constant(''))();
  DateTimeColumn get refreshedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountId, recordKind, scopeId};
}

@DriftDatabase(tables: [Songs, Setlists, Scores, CacheRecords, CacheRefreshes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'battuta_offline_db'));

  /// v1: songs, setlists, scores.
  /// v2: adds the account-scoped backend cache ([CacheRecords], [CacheRefreshes]).
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cacheRecords);
        await m.createTable(cacheRefreshes);
      }
    },
  );
}
