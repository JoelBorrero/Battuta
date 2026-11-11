/// Cache-first implementation of [OrganizationRepertoireRepository].
library;

import 'dart:async';

import 'package:battuta/features/organizations/data/cached_repository_support.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repertoire_repository.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:fpdart/fpdart.dart';

class OrganizationRepertoireRepositoryImpl
    with CachedRepositorySupport
    implements OrganizationRepertoireRepository {
  OrganizationRepertoireRepositoryImpl({
    required this.remote,
    required this.cache,
    required this.session,
  });

  final OrganizationRepertoireRemoteDataSource remote;
  @override
  final OrganizationsLocalCache cache;
  @override
  final AccountSession session;

  static int _byTitle(RepertoireEntry a, RepertoireEntry b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());

  @override
  Stream<List<RepertoireEntry>> watchRepertoire(String organizationId) =>
      watchCached<RepertoireEntry>(
        CacheKind.repertoire,
        RepertoireEntry.fromJson,
        scopeId: organizationId,
        refresh: () async {
          await refreshRepertoire(organizationId);
        },
        sort: _byTitle,
      );

  @override
  Stream<List<RepertoireEntry>> watchAllRepertoire() =>
      watchCached<RepertoireEntry>(
        CacheKind.repertoire,
        RepertoireEntry.fromJson,
        sort: _byTitle,
      );

  static String _key(String organizationId, String versionId) =>
      '$organizationId|$versionId';

  @override
  Future<Result<Unit>> refreshRepertoire(String organizationId) =>
      guard((accountId) async {
        final entries = await remote.fetchRepertoire(organizationId);
        await cache.replaceAll(
          accountId,
          CacheKind.repertoire,
          entries.map(
            (e) => (id: _key(e.organizationId, e.versionId), json: e.toJson()),
          ),
          scopeId: organizationId,
        );
        return unit;
      });

  @override
  Future<Result<RepertoireEntry>> addToRepertoire(
    String organizationId,
    RepertoireCandidate candidate,
  ) => guardWrite(organizationId, (accountId) async {
    await remote.addToRepertoire(organizationId, candidate.versionId);
    final entry = candidate.toEntry(organizationId, addedBy: accountId);
    await cache.upsert(
      accountId,
      CacheKind.repertoire,
      _key(organizationId, candidate.versionId),
      entry.toJson(),
      scopeId: organizationId,
    );
    return entry;
  });

  @override
  Future<Result<Unit>> removeFromRepertoire(
    String organizationId,
    String versionId,
  ) => guardWrite(organizationId, (accountId) async {
    await remote.removeFromRepertoire(organizationId, versionId);
    await cache.remove(
      accountId,
      CacheKind.repertoire,
      _key(organizationId, versionId),
    );
    return unit;
  });

  @override
  Future<Result<List<RepertoireCandidate>>> searchCandidates(
    String organizationId,
    String query,
  ) => guard((accountId) async {
    // The server filters visibility; read every page, then put mine first.
    const pageSize = 100;
    final found = <RepertoireCandidate>[];
    for (var offset = 0; ; offset += pageSize) {
      final page = await remote.searchCandidates(
        organizationId,
        query.trim(),
        limit: pageSize,
        offset: offset,
      );
      found.addAll(page);
      if (page.length < pageSize) break;
    }
    // Mine first, then by title.
    final sorted = [...found]
      ..sort((a, b) {
        final mineA = a.ownerId == accountId ? 0 : 1;
        final mineB = b.ownerId == accountId ? 0 : 1;
        if (mineA != mineB) return mineA - mineB;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return sorted;
  });
}
