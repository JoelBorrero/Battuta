/// Battuta — Offline SQLite setlist repository implementation.
///
/// Implements [SetlistRepository] backed by Drift embedded database,
/// guaranteeing 100% offline functionality in Airplane Mode.
///
/// Like songs, setlist rows are scoped to an account (`accountId == null` is
/// unclaimed local-mode data). A setlist is either personal or belongs to an
/// organization (`organizationId`); organization setlists are read-only unless
/// [canAdministerOrganization] says the account is an admin of it.
library;

import 'dart:convert';

import 'package:battuta/core/database/account_scoped_stream.dart';
import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/repertoire/data/repositories/drift_song_repository.dart'
    show localOnlyIdPrefix;
import 'package:battuta/features/repertoire/data/repositories/setlist_row_mapper.dart';
import 'package:battuta/features/repertoire/domain/entities/setlist.dart';
import 'package:battuta/features/repertoire/domain/repositories/setlist_repository.dart';
import 'package:battuta/features/sync/domain/services/sync_policy.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

/// Concrete [SetlistRepository] backed by [AppDatabase].
class DriftSetlistRepository implements SetlistRepository {
  /// Creates a [DriftSetlistRepository] with the given [AppDatabase].
  DriftSetlistRepository(
    this.db, {
    this._session,
    this.canAdministerOrganization,
  });

  /// The underlying Drift SQLite database.
  final AppDatabase db;
  final AccountSession? _session;

  /// Whether the signed-in account may edit the setlists of an organization.
  /// When null, organization setlists are read-only.
  final bool Function(String organizationId)? canAdministerOrganization;

  String? get _account => _session?.userId;

  Expression<bool> _visible($SetlistsTable t, String? account) {
    final mine = account == null
        ? t.accountId.isNull()
        : (t.accountId.isNull() | t.accountId.equals(account));
    return t.deletedAt.isNull() & mine;
  }

  Failure? _writeDenied(String? organizationId) {
    if (organizationId == null) return null;
    if (canAdministerOrganization?.call(organizationId) ?? false) return null;
    return BackendErrorCode.notAdmin.failure(
      message: 'Only organization admins can edit organization setlists.',
    );
  }

  @override
  Future<Either<Failure, List<Setlist>>> getAllSetlists() async {
    try {
      final account = _account;
      final rows =
          await (db.select(db.setlists)
                ..where((t) => _visible(t, account))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();
      return Right(rows.map(setlistFromRow).toList());
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to retrieve setlists: $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Setlist>> getSetlistById(String id) async {
    try {
      final account = _account;
      final row =
          await (db.select(db.setlists)
                ..where((t) => t.id.equals(id) & _visible(t, account)))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
      }
      return Right(setlistFromRow(row));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to retrieve setlist "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Setlist>> saveSetlist(Setlist setlist) async {
    try {
      final account = _account;
      final existing = await (db.select(
        db.setlists,
      )..where((t) => t.id.equals(setlist.id))).getSingleOrNull();
      if (existing != null &&
          existing.accountId != null &&
          existing.accountId != account) {
        return Left(
          BackendErrorCode.notOwner.failure(
            message: 'Setlist "${setlist.id}" belongs to another account.',
          ),
        );
      }
      // A setlist never changes between personal and organization.
      final organizationId = existing != null
          ? existing.organizationId
          : setlist.organizationId;
      final denied = _writeDenied(organizationId);
      if (denied != null) return Left(denied);

      final localOnly = setlist.id.startsWith(localOnlyIdPrefix);
      final accountId = existing != null
          ? existing.accountId
          : (localOnly ? null : account);

      final companion = SetlistsCompanion(
        id: Value(setlist.id),
        title: Value(setlist.title),
        description: Value(setlist.description),
        eventDate: Value(setlist.eventDate),
        itemsJson: Value(
          jsonEncode(setlist.items.map((i) => i.toJson()).toList()),
        ),
        tagsJson: Value(jsonEncode(setlist.tags)),
        createdAt: Value(setlist.createdAt),
        updatedAt: Value(setlist.updatedAt),
        organizationId: Value(organizationId),
        isDirty: Value(accountId != null),
        deletedAt: const Value(null),
        remoteUpdatedAt: Value(existing?.remoteUpdatedAt),
        accountId: Value(accountId),
        editedAtMs: Value(SyncPolicy.nextEditMs(existing?.editedAtMs)),
      );

      await db.into(db.setlists).insertOnConflictUpdate(companion);
      return Right(setlist.copyWith(organizationId: organizationId));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save setlist "${setlist.id}": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteSetlist(String id) async {
    try {
      final account = _account;
      final row =
          await (db.select(db.setlists)
                ..where((t) => t.id.equals(id) & _visible(t, account)))
              .getSingleOrNull();
      if (row == null) {
        return Left(CacheFailure(message: 'Setlist with ID "$id" not found.'));
      }
      final denied = _writeDenied(row.organizationId);
      if (denied != null) return Left(denied);

      if (row.remoteUpdatedAt == null) {
        await (db.delete(db.setlists)..where((t) => t.id.equals(id))).go();
      } else {
        await (db.update(db.setlists)..where((t) => t.id.equals(id))).write(
          SetlistsCompanion(
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
          message: 'Failed to delete setlist "$id": $e',
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<Setlist>> watchAllSetlists() {
    return watchForAccount(
      _session,
      (account) =>
          (db.select(db.setlists)
                ..where((t) => _visible(t, account))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .watch()
              .map((rows) => rows.map(setlistFromRow).toList()),
    );
  }
}
