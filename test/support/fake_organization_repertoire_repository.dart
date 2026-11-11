import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repertoire_repository.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory [OrganizationRepertoireRepository] for widget tests.
class FakeOrganizationRepertoireRepository
    implements OrganizationRepertoireRepository {
  FakeOrganizationRepertoireRepository({
    List<RepertoireEntry> entries = const [],
    this.candidates = const [],
  }) : _entries = [...entries];

  final List<RepertoireEntry> _entries;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// What `searchCandidates` finds.
  List<RepertoireCandidate> candidates;

  /// When set, the next call fails with it (then it is cleared).
  Failure? nextFailure;

  /// Names of the calls made, in order.
  final List<String> calls = [];

  Either<Failure, T>? _failed<T>() {
    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return left(failure);
  }

  void setEntries(List<RepertoireEntry> entries) {
    _entries
      ..clear()
      ..addAll(entries);
    _changes.add(null);
  }

  Stream<List<RepertoireEntry>> _watch(bool Function(RepertoireEntry) where) {
    late final StreamController<List<RepertoireEntry>> controller;
    StreamSubscription<void>? sub;
    void emit() => controller.add([
      for (final entry in _entries)
        if (where(entry)) entry,
    ]);
    controller = StreamController<List<RepertoireEntry>>(
      onListen: () {
        emit();
        sub = _changes.stream.listen((_) => emit());
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<List<RepertoireEntry>> watchRepertoire(String organizationId) =>
      _watch((e) => e.organizationId == organizationId);

  @override
  Stream<List<RepertoireEntry>> watchAllRepertoire() => _watch((_) => true);

  @override
  Future<Either<Failure, Unit>> refreshRepertoire(String organizationId) async {
    calls.add('refresh:$organizationId');
    return right(unit);
  }

  @override
  Future<Either<Failure, RepertoireEntry>> addToRepertoire(
    String organizationId,
    RepertoireCandidate candidate,
  ) async {
    calls.add('add:$organizationId:${candidate.versionId}');
    if (_failed<RepertoireEntry>() case final f?) return f;
    final entry = candidate.toEntry(organizationId, addedBy: 'u-me');
    _entries.add(entry);
    _changes.add(null);
    return right(entry);
  }

  @override
  Future<Either<Failure, Unit>> removeFromRepertoire(
    String organizationId,
    String versionId,
  ) async {
    calls.add('remove:$organizationId:$versionId');
    if (_failed<Unit>() case final f?) return f;
    _entries.removeWhere(
      (e) => e.organizationId == organizationId && e.versionId == versionId,
    );
    _changes.add(null);
    return right(unit);
  }

  @override
  Future<Either<Failure, List<RepertoireCandidate>>> searchCandidates(
    String organizationId,
    String query,
  ) async {
    calls.add('search:$organizationId:$query');
    if (_failed<List<RepertoireCandidate>>() case final f?) return f;
    final q = query.trim().toLowerCase();
    return right([
      for (final c in candidates)
        if (c.isVisibleTo(organizationId) &&
            (q.isEmpty ||
                c.title.toLowerCase().contains(q) ||
                c.artist.toLowerCase().contains(q)))
          c,
    ]);
  }
}

Failure offlineFailure() => BackendErrorCode.offline.failure();
