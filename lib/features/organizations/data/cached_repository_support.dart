/// Shared helpers of the cache-first repositories.
library;

import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:fpdart/fpdart.dart' hide Band;

mixin CachedRepositorySupport {
  AccountSession get session;
  OrganizationsLocalCache get cache;

  /// Runs [body] for the signed-in account and converts every error to a
  /// `Left`. Signed out -> `notSignedIn`.
  ///
  /// If the account changes while [body] runs, its cache writes are dropped
  /// by the cache itself (see `OrganizationsLocalCache.currentAccount`). An
  /// `account_deactivated` failure signs the user out and clears the cache.
  Future<Result<T>> guard<T>(Future<T> Function(String accountId) body) async {
    final accountId = session.userId;
    if (accountId == null) {
      return left(
        BackendErrorCode.notSignedIn.failure(message: 'Sign in first.'),
      );
    }
    try {
      return right(await cache.runFetch(() => body(accountId)));
    } catch (e, st) {
      final failure = mapBackendError(e, st);
      // Only the account that made the request is signed out: a stale failure
      // arriving after a switch must not end the new account's session.
      if (failure.errorCode == BackendErrorCode.accountDeactivated &&
          session.userId == accountId) {
        await handleDeactivation();
      }
      return left(failure);
    }
  }

  /// Ends the session of a deactivated account and drops its cache.
  Future<void> handleDeactivation() async {
    try {
      await session.signOut();
    } catch (_) {
      // Clearing the cache below still happens.
    }
    await cache.clearAllExcept(null);
  }

  /// Cache stream of [kind]; refreshes in the background when first listened.
  /// Follows the session: it switches to the new account's cache when the
  /// account changes and is empty while signed out.
  Stream<List<T>> watchCached<T>(
    String kind,
    T Function(Map<String, dynamic>) fromJson, {
    String? scopeId,
    Future<void> Function()? refresh,
    int Function(T a, T b)? sort,
  }) {
    late final StreamController<List<T>> controller;
    StreamSubscription<List<T>>? inner;
    StreamSubscription<String?>? outer;
    var bound = false;
    String? boundId;

    Future<void> bind(String? id) async {
      if (bound && id == boundId) return;
      bound = true;
      boundId = id;
      await inner?.cancel();
      inner = null;
      if (id == null) {
        controller.add(const []);
        return;
      }
      if (refresh != null) unawaited(refresh());
      inner = cache.watch<T>(id, kind, fromJson, scopeId: scopeId).listen((
        rows,
      ) {
        if (sort != null) rows.sort(sort);
        controller.add(rows);
      }, onError: controller.addError);
    }

    controller = StreamController<List<T>>(
      onListen: () {
        outer = session.userIdChanges.listen(bind);
        bind(session.userId);
      },
      onCancel: () async {
        await outer?.cancel();
        await inner?.cancel();
      },
    );
    return controller.stream;
  }

  /// Fails fast with `organization_archived` when the cached organization is
  /// archived (archived organizations are read-only).
  Future<Failure?> archivedFailure(
    String accountId,
    String organizationId,
  ) async {
    final org = await cache.readOne(
      accountId,
      CacheKind.organization,
      organizationId,
      Organization.fromJson,
    );
    if (org != null && org.isArchived) {
      return BackendErrorCode.organizationArchived.failure(
        message: 'This organization is archived and read-only.',
      );
    }
    return null;
  }

  /// Like [guard], but a write to an archived organization fails before
  /// reaching the network.
  Future<Result<T>> guardWrite<T>(
    String organizationId,
    Future<T> Function(String accountId) body,
  ) async {
    final accountId = session.userId;
    if (accountId != null) {
      final archived = await archivedFailure(accountId, organizationId);
      if (archived != null) return left(archived);
    }
    return guard(body);
  }
}
