/// Battuta — Offline SQLite song repository implementation.
///
/// Implements [SongRepository] backed by Drift embedded database,
/// guaranteeing 100% offline functionality in Airplane Mode.
///
/// A song row is one version (see [Song]). Rows are scoped to an account:
/// `accountId == null` is local-mode data (shown to everybody until an account
/// claims it on its first sync), any other value only shows for that account.
/// Versions owned by somebody else (cached from an organization's repertoire)
/// are read-only: saving or deleting them fails with `not_owner`.
library;

import 'dart:convert';

import 'package:battuta/core/database/account_scoped_stream.dart';
import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/repertoire/data/repositories/song_row_mapper.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_visibility.dart';
import 'package:battuta/features/repertoire/domain/repositories/song_repository.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

/// Id prefix of the bundled sample songs. They live on the device only and are
/// never owned by an account nor uploaded.
const String localOnlyIdPrefix = 'seed-';

/// Concrete [SongRepository] backed by [AppDatabase].
class DriftSongRepository implements SongRepository {
  /// Creates a [DriftSongRepository] with the given [AppDatabase].
  ///
  /// [session] tells which account is signed in; without it the repository
  /// behaves as in local mode.
  DriftSongRepository(this.db, {this._session});

  /// The underlying Drift SQLite database.
  final AppDatabase db;
  final AccountSession? _session;

  String? get _account => _session?.userId;

  /// Rows the given [account] can see: not deleted, and local-mode rows or the
  /// account's own cache.
  Expression<bool> _visible($SongsTable t, String? account) {
    final mine = account == null
        ? t.accountId.isNull()
        : (t.accountId.isNull() | t.accountId.equals(account));
    return t.deletedAt.isNull() & mine;
  }

  bool _foreign(SongEntry row, String? account) =>
      (row.ownerId != null && row.ownerId != account) ||
      (row.accountId != null && row.accountId != account);

  Failure _notOwner(String id) => BackendErrorCode.notOwner.failure(
    message: 'Song "$id" belongs to another user and is read-only.',
  );

  @override
  Future<Either<Failure, List<Song>>> getAllSongs() async {
    try {
      final account = _account;
      final rows =
          await (db.select(db.songs)
                ..where((t) => _visible(t, account))
                ..orderBy([(t) => OrderingTerm.asc(t.title)]))
              .get();
      return Right(rows.map(songFromRow).toList());
    } catch (e, st) {
      return Left(
        CacheFailure(message: 'Failed to retrieve songs: $e', stackTrace: st),
      );
    }
  }

  @override
  Future<Either<Failure, Song>> getSongById(String id) async {
    try {
      final account = _account;
      final row =
          await (db.select(db.songs)
                ..where((t) => t.id.equals(id) & _visible(t, account)))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
      }
      return Right(songFromRow(row));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to retrieve song "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Song>> saveSong(Song song) async {
    try {
      final account = _account;
      final existing = await (db.select(
        db.songs,
      )..where((t) => t.id.equals(song.id))).getSingleOrNull();
      if (existing != null && _foreign(existing, account)) {
        return Left(_notOwner(song.id));
      }

      final localOnly = song.id.startsWith(localOnlyIdPrefix);
      // Identity and sharing belong to the version, not to what an editor
      // rebuilt from a form: an existing row keeps them (sharing changes go
      // through [updateSharing]).
      final ownerId = existing != null
          ? existing.ownerId
          : (localOnly ? null : account);
      final accountId = existing != null
          ? existing.accountId
          : (localOnly ? null : account);
      final songWorkId = existing?.songWorkId ?? song.songWorkId;
      final forkedFrom = existing != null
          ? existing.forkedFromVersionId
          : song.forkedFromVersionId;
      final label = existing?.label ?? song.label;
      final visibility = existing?.visibility ?? song.visibility.name;
      final shared =
          existing?.sharedOrganizationIdsJson ??
          jsonEncode(song.sharedOrganizationIds);
      final creator = existing != null
          ? existing.songCreatorId
          : song.songCreatorId;
      // Title and artist belong to the song, not to this version: only the
      // creator of the song changes them (a sync would revert anything else).
      final titleLocked =
          existing != null &&
          !songFromRow(existing).canEditTitleBy(account);
      final title = titleLocked ? existing.title : song.title;
      final artist = titleLocked ? existing.artist : song.artist;

      final companion = SongsCompanion(
        id: Value(song.id),
        title: Value(title),
        artist: Value(artist),
        key: Value(song.key),
        tempo: Value(song.tempo),
        timeSignatureBeats: Value(song.timeSignature.$1),
        timeSignatureBeatValue: Value(song.timeSignature.$2),
        sectionsJson: Value(
          jsonEncode(song.sections.map((s) => s.toJson()).toList()),
        ),
        tagsJson: Value(jsonEncode(song.tags)),
        coverImagePath: Value(song.coverImagePath),
        notes: Value(song.notes),
        createdAt: Value(song.createdAt),
        updatedAt: Value(song.updatedAt),
        songWorkId: Value(songWorkId),
        ownerId: Value(ownerId),
        label: Value(label),
        visibility: Value(visibility),
        forkedFromVersionId: Value(forkedFrom),
        sharedOrganizationIdsJson: Value(shared),
        // Owned rows are pushed by the next sync; local-mode rows are claimed
        // (and marked dirty) when an account signs in.
        isDirty: Value(ownerId != null),
        deletedAt: const Value(null),
        remoteUpdatedAt: Value(existing?.remoteUpdatedAt),
        accountId: Value(accountId),
        editedAtMs: Value(SyncPolicy.nextEditMs(existing?.editedAtMs)),
        sharingDirty: Value(existing?.sharingDirty ?? false),
        songCreatorId: Value(creator),
      );

      await db.into(db.songs).insertOnConflictUpdate(companion);
      return Right(
        song.copyWith(
          title: title,
          artist: artist,
          songCreatorId: creator,
          songWorkId: songWorkId,
          ownerId: ownerId,
          label: label,
          visibility: SongVisibility.parse(visibility),
          forkedFromVersionId: forkedFrom,
          sharedOrganizationIds: decodeStringList(shared),
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save song "${song.id}": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Song>> updateSharing(
    String id, {
    String? label,
    SongVisibility? visibility,
    List<String>? sharedOrganizationIds,
  }) async {
    try {
      final account = _account;
      final row =
          await (db.select(db.songs)
                ..where((t) => t.id.equals(id) & _visible(t, account)))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
      }
      if (_foreign(row, account) || row.ownerId == null) {
        return Left(_notOwner(id));
      }
      final newVisibility = visibility?.name ?? row.visibility;
      final newShares = newVisibility == SongVisibility.organizations.name
          ? (sharedOrganizationIds ??
                decodeStringList(row.sharedOrganizationIdsJson))
          : const <String>[];
      final newLabel = label?.trim().isNotEmpty ?? false
          ? label!.trim()
          : row.label;
      final sharesJson = jsonEncode(newShares);
      if (newLabel == row.label &&
          newVisibility == row.visibility &&
          sharesJson == row.sharedOrganizationIdsJson) {
        return Right(songFromRow(row));
      }
      await (db.update(db.songs)..where((t) => t.id.equals(id))).write(
        SongsCompanion(
          label: Value(newLabel),
          visibility: Value(newVisibility),
          sharedOrganizationIdsJson: Value(sharesJson),
          isDirty: const Value(true),
          sharingDirty: const Value(true),
        ),
      );
      final updated = await (db.select(
        db.songs,
      )..where((t) => t.id.equals(id))).getSingle();
      return Right(songFromRow(updated));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to update sharing of "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteSong(String id) async {
    try {
      final account = _account;
      final row =
          await (db.select(db.songs)
                ..where((t) => t.id.equals(id) & _visible(t, account)))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Song with ID "$id" not found.'));
      }
      if (_foreign(row, account)) return Left(_notOwner(id));

      if (row.remoteUpdatedAt == null) {
        // Never reached the backend: nothing to tell it.
        await (db.delete(db.songs)..where((t) => t.id.equals(id))).go();
      } else {
        // Keep a tombstone until the delete has been pushed.
        await (db.update(db.songs)..where((t) => t.id.equals(id))).write(
          SongsCompanion(
            deletedAt: Value(DateTime.now()),
            isDirty: const Value(true),
            editedAtMs: Value(SyncPolicy.nextEditMs(row.editedAtMs)),
          ),
        );
      }
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to delete song "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Song>>> searchSongs(String query) async {
    try {
      final cleanQuery = query.trim().toLowerCase();
      if (cleanQuery.isEmpty) {
        return await getAllSongs();
      }

      final account = _account;
      final rows =
          await (db.select(db.songs)..where(
                (t) =>
                    _visible(t, account) &
                    (t.title.lower().contains(cleanQuery) |
                        t.artist.lower().contains(cleanQuery) |
                        t.tagsJson.lower().contains(cleanQuery)),
              ))
              .get();

      return Right(rows.map(songFromRow).toList());
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Search failed for query "$query": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<Song>> watchAllSongs() {
    return watchForAccount(
      _session,
      (account) =>
          (db.select(db.songs)
                ..where((t) => _visible(t, account))
                ..orderBy([(t) => OrderingTerm.asc(t.title)]))
              .watch()
              .map((rows) => rows.map(songFromRow).toList()),
    );
  }
}
