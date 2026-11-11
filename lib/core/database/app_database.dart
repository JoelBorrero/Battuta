/// Battuta — Offline SQLite embedded database using Drift.
///
/// Provides type-safe persistence for songs, setlists, and complete Score trees
/// in full offline Airplane Mode.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Table storing repertoire songs.
///
/// A row is one song **version**: [id] is `song_versions.id` on the backend and
/// [songWorkId] the `songs.id` it belongs to. The sync columns ([isDirty],
/// [deletedAt], [remoteUpdatedAt], [accountId]) are managed by the repositories
/// and the cloud sync; `accountId == null` means the row is local-mode data
/// that no account has claimed yet.
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

  // v3: song versions and cloud sync state.
  TextColumn get songWorkId => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get label => text().withDefault(const Constant('Original'))();
  TextColumn get visibility => text().withDefault(const Constant('private'))();
  TextColumn get forkedFromVersionId => text().nullable()();
  TextColumn get sharedOrganizationIdsJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  /// Local tombstone: set when a synced version is deleted, until the delete
  /// has been pushed.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// `updated_at` of the backend row this copy was last synced with, as the
  /// exact ISO-8601 text the backend sent (Drift's `DateTime` would drop the
  /// sub-second part and make unchanged rows look changed).
  TextColumn get remoteUpdatedAt => text().nullable()();
  TextColumn get accountId => text().nullable()();

  /// When the user last edited the version, in milliseconds since the epoch.
  /// Strictly increasing per row, so two saves never share a value; it is what
  /// devices compare to decide whose edit is newer, and what tells a push that
  /// the row was edited again while it was in flight.
  IntColumn get editedAtMs => integer().withDefault(const Constant(0))();

  /// Label, visibility or shares changed locally and are not pushed yet.
  BoolColumn get sharingDirty => boolean().withDefault(const Constant(false))();

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

  // v3: personal vs organization setlists and cloud sync state.
  /// Null for a personal setlist.
  TextColumn get organizationId => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get remoteUpdatedAt => text().nullable()();
  TextColumn get accountId => text().nullable()();

  /// See [Songs.editedAtMs].
  IntColumn get editedAtMs => integer().withDefault(const Constant(0))();

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

  // v3: cloud sync state (the score belongs to the version [songId]).
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get remoteUpdatedAt => text().nullable()();

  /// See [Songs.editedAtMs].
  IntColumn get editedAtMs => integer().withDefault(const Constant(0))();

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
  /// v3: song versions, personal/organization setlists and sync state columns.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cacheRecords);
        await m.createTable(cacheRefreshes);
      }
      if (from < 3) {
        await m.addColumn(songs, songs.songWorkId);
        await m.addColumn(songs, songs.ownerId);
        await m.addColumn(songs, songs.label);
        await m.addColumn(songs, songs.visibility);
        await m.addColumn(songs, songs.forkedFromVersionId);
        await m.addColumn(songs, songs.sharedOrganizationIdsJson);
        await m.addColumn(songs, songs.isDirty);
        await m.addColumn(songs, songs.deletedAt);
        await m.addColumn(songs, songs.remoteUpdatedAt);
        await m.addColumn(songs, songs.accountId);
        await m.addColumn(setlists, setlists.organizationId);
        await m.addColumn(setlists, setlists.isDirty);
        await m.addColumn(setlists, setlists.deletedAt);
        await m.addColumn(setlists, setlists.remoteUpdatedAt);
        await m.addColumn(setlists, setlists.accountId);
        await m.addColumn(scores, scores.isDirty);
        await m.addColumn(scores, scores.deletedAt);
        await m.addColumn(scores, scores.remoteUpdatedAt);
        await m.addColumn(songs, songs.editedAtMs);
        await m.addColumn(songs, songs.sharingDirty);
        await m.addColumn(setlists, setlists.editedAtMs);
        await m.addColumn(scores, scores.editedAtMs);
        // Existing rows were last edited when they were last updated
        // (Drift stores dates as unix seconds).
        for (final table in const ['songs', 'setlists', 'scores']) {
          await customStatement(
            'UPDATE $table SET edited_at_ms = updated_at * 1000',
          );
        }
      }
    },
  );
}
