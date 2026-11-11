import 'dart:async';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:flutter_test/flutter_test.dart' show Fake;
import 'package:fpdart/fpdart.dart' hide Band;

/// In-memory [OrganizationRepository] for widget tests: the streams the UI
/// watches, the writes the roster makes, and failures that can be injected.
/// Anything else throws (`Fake`), so a test never silently depends on it.
class FakeOrganizationRepository extends Fake
    implements OrganizationRepository {
  FakeOrganizationRepository({
    List<Organization> organizations = const [],
    List<OrganizationMember> members = const [],
    List<Band> bands = const [],
    List<BandMember> bandMembers = const [],
  }) : _organizations = [...organizations],
       _members = [...members],
       _bands = [...bands],
       _bandMembers = [...bandMembers];

  final List<Organization> _organizations;
  final List<OrganizationMember> _members;
  final List<Band> _bands;
  final List<BandMember> _bandMembers;
  final _changes = StreamController<void>.broadcast(sync: true);

  /// When set, the next write returns this failure (then it is cleared).
  Failure? nextFailure;

  /// Names of the writes made, in order (e.g. `setMemberRole:m2:admin`).
  final List<String> calls = [];

  int _ids = 0;

  void _notify() => _changes.add(null);

  Stream<List<T>> _watch<T>(List<T> Function() read) {
    late StreamController<List<T>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<T>>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  /// Decides a failure per write, by its entry in [calls] (checked first).
  Failure? Function(String call)? failWhen;

  Either<Failure, T>? _failed<T>() {
    final byCall = failWhen?.call(calls.last);
    if (byCall != null) return left(byCall);
    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return left(failure);
  }

  /// Replaces the organizations (as a realtime / refresh update would).
  void setOrganizations(List<Organization> organizations) {
    _organizations
      ..clear()
      ..addAll(organizations);
    _notify();
  }

  void setMembers(List<OrganizationMember> members) {
    _members
      ..clear()
      ..addAll(members);
    _notify();
  }

  @override
  Stream<List<Organization>> watchOrganizations({
    bool includeArchived = false,
  }) => _watch(
    () => [
      for (final o in _organizations)
        if (includeArchived || !o.isArchived) o,
    ],
  );

  @override
  Stream<List<OrganizationMember>> watchMembers(String organizationId) =>
      _watch(
        () => [
          for (final m in _members)
            if (m.organizationId == organizationId) m,
        ],
      );

  @override
  Stream<List<Band>> watchBands(String organizationId) => _watch(
    () => [
      for (final b in _bands)
        if (b.organizationId == organizationId) b,
    ],
  );

  @override
  Stream<List<BandMember>> watchBandMembers(String organizationId) => _watch(
    () => [
      for (final b in _bandMembers)
        if (b.organizationId == organizationId) b,
    ],
  );

  @override
  Future<Either<Failure, Organization>> createOrganization(String name) async {
    calls.add('createOrganization:$name');
    if (_failed<Organization>() case final f?) return f;
    final created = Organization(
      id: 'org-new-${_ids++}',
      name: name,
      myRole: OrganizationRole.admin,
    );
    _organizations.add(created);
    _notify();
    return right(created);
  }

  @override
  Future<Either<Failure, OrganizationMember>> updateMusicianProfile(
    String organizationId,
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  }) async {
    calls.add(
      'updateMusicianProfile:$memberId:${instruments?.join(',')}:'
      '$minPitch:$maxPitch:$notes',
    );
    if (_failed<OrganizationMember>() case final f?) return f;
    final index = _members.indexWhere((m) => m.id == memberId);
    final old = _members[index];
    final updated = OrganizationMember(
      id: old.id,
      organizationId: old.organizationId,
      userId: old.userId,
      role: old.role,
      instruments: instruments ?? old.instruments,
      minPitch: minPitch == null
          ? old.minPitch
          : (minPitch.isEmpty ? null : minPitch),
      maxPitch: maxPitch == null
          ? old.maxPitch
          : (maxPitch.isEmpty ? null : maxPitch),
      notes: notes == null ? old.notes : (notes.isEmpty ? null : notes),
      username: old.username,
      displayName: old.displayName,
    );
    _members[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Either<Failure, OrganizationMember>> setMemberRole(
    String organizationId,
    String memberId,
    OrganizationRole role,
  ) async {
    calls.add('setMemberRole:$memberId:${role.name}');
    if (_failed<OrganizationMember>() case final f?) return f;
    final index = _members.indexWhere((m) => m.id == memberId);
    final old = _members[index];
    final updated = OrganizationMember(
      id: old.id,
      organizationId: old.organizationId,
      userId: old.userId,
      role: role,
      instruments: old.instruments,
      minPitch: old.minPitch,
      maxPitch: old.maxPitch,
      notes: old.notes,
      username: old.username,
      displayName: old.displayName,
    );
    _members[index] = updated;
    _notify();
    return right(updated);
  }

  @override
  Future<Either<Failure, Unit>> removeMember(
    String organizationId,
    String memberId,
  ) async {
    calls.add('removeMember:$memberId');
    if (_failed<Unit>() case final f?) return f;
    _members.removeWhere((m) => m.id == memberId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> leaveOrganization(String organizationId) async {
    calls.add('leaveOrganization:$organizationId');
    if (_failed<Unit>() case final f?) return f;
    _organizations.removeWhere((o) => o.id == organizationId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, Band>> createBand(
    String organizationId,
    String name, {
    String? description,
    int colorValue = Band.defaultColorValue,
  }) async {
    calls.add('createBand:$name');
    if (_failed<Band>() case final f?) return f;
    final band = Band(
      id: 'band-new-${_ids++}',
      organizationId: organizationId,
      name: name,
      description: description,
      colorValue: colorValue,
    );
    _bands.add(band);
    _notify();
    return right(band);
  }

  @override
  Future<Either<Failure, Band>> updateBand(Band band) async {
    calls.add('updateBand:${band.id}:${band.name}');
    if (_failed<Band>() case final f?) return f;
    final index = _bands.indexWhere((b) => b.id == band.id);
    _bands[index] = band;
    _notify();
    return right(band);
  }

  @override
  Future<Either<Failure, Unit>> deleteBand(
    String organizationId,
    String bandId,
  ) async {
    calls.add('deleteBand:$bandId');
    if (_failed<Unit>() case final f?) return f;
    _bands.removeWhere((b) => b.id == bandId);
    _bandMembers.removeWhere((b) => b.bandId == bandId);
    _notify();
    return right(unit);
  }

  @override
  Future<Either<Failure, BandMember>> addBandMember(
    String organizationId,
    String bandId,
    String memberId,
  ) async {
    calls.add('addBandMember:$bandId:$memberId');
    if (_failed<BandMember>() case final f?) return f;
    final link = BandMember(
      id: 'bm-${_ids++}',
      organizationId: organizationId,
      bandId: bandId,
      memberId: memberId,
    );
    _bandMembers.add(link);
    _notify();
    return right(link);
  }

  @override
  Future<Either<Failure, Unit>> removeBandMember(
    String organizationId,
    String bandMemberId,
  ) async {
    calls.add('removeBandMember:$bandMemberId');
    if (_failed<Unit>() case final f?) return f;
    _bandMembers.removeWhere((b) => b.id == bandMemberId);
    _notify();
    return right(unit);
  }
}

/// A backend failure with its typed code, as the repositories return.
Failure backendFailure(BackendErrorCode code) =>
    code.failure(message: code.code);
