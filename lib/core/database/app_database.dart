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

@DriftDatabase(tables: [Songs, Setlists, Scores])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'battuta_offline_db'));

  @override
  int get schemaVersion => 1;
}
