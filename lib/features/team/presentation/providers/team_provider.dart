/// Battuta — Team roster on real data.
///
/// Adapts the members of the active organization (organizations feature) to
/// the [TeamMember] presentation model, filtered by the active band, and
/// exposes the roster edits. Every write goes through the organization
/// repository; nothing is applied optimistically.
library;

import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Band;

/// Maps an organization member to the roster model.
TeamMember toTeamMember(
  OrganizationMember member, {
  required String? currentAccountId,
  List<String> bandIds = const [],
}) => TeamMember(
  id: member.id,
  userId: member.userId,
  username: member.username,
  avatarPath: member.avatarPath,
  name: _displayName(member),
  instruments: member.instruments,
  minPitch: member.minPitch,
  maxPitch: member.maxPitch,
  notes: member.notes,
  isAdmin: member.isAdmin,
  isMe: currentAccountId != null && member.userId == currentAccountId,
  groupIds: bandIds,
);

String _displayName(OrganizationMember member) {
  final name = member.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  return member.username ?? member.userId;
}

/// Active members of the active organization that belong to the active band
/// (everyone when no band is selected), as roster entries.
final teamMembersProvider = Provider<List<TeamMember>>((ref) {
  final members = ref.watch(activeMembersProvider).value ?? const [];
  final bandMembers = ref.watch(activeBandMembersProvider).value ?? const [];
  final activeBandId = ref.watch(activeBandIdProvider);
  final me = ref.watch(currentAccountIdProvider);

  final bandsOf = <String, List<String>>{};
  for (final link in bandMembers) {
    bandsOf.putIfAbsent(link.memberId, () => []).add(link.bandId);
  }

  return [
    for (final member in members)
      if (member.isActive &&
          (activeBandId == null ||
              (bandsOf[member.id]?.contains(activeBandId) ?? false)))
        toTeamMember(
          member,
          currentAccountId: me,
          bandIds: bandsOf[member.id] ?? const [],
        ),
  ];
});

/// Bands of the active organization.
final teamGroupsProvider = Provider<List<TeamGroup>>(
  (ref) => [
    for (final band in ref.watch(activeBandsProvider).value ?? const <Band>[])
      TeamGroup(
        id: band.id,
        name: band.name,
        description: band.description,
        colorValue: band.colorValue,
      ),
  ],
);

/// The step of [RosterActions.saveMember] that failed after the member
/// profile had already been written.
enum MemberSaveStep { role, bands }

/// Why [RosterActions.saveMember] failed. [step] is set when earlier writes
/// went through (the changes were saved partly); `null` when nothing was.
class MemberSaveFailure {
  const MemberSaveFailure(this.cause, {this.step});

  final Failure cause;
  final MemberSaveStep? step;
}

/// The roster writes. Each returns the first failure, `Right(unit)` on success.
class RosterActions {
  const RosterActions(this._ref);

  final Ref _ref;

  String? get _organizationId => _ref.read(activeOrganizationIdProvider);

  Either<Failure, Unit> _noOrganization() =>
      left(const ValidationFailure(message: 'No active organization.'));

  /// Saves what changed in [edited] compared with [original]. Members can
  /// only change their own musician profile; role and bands are admin edits
  /// (the server refuses them otherwise).
  Future<Either<MemberSaveFailure, Unit>> saveMember({
    required TeamMember original,
    required List<TeamRole> roles,
    required VocalTessitura tessitura,
    required String notes,
    required bool isAdmin,
    required Set<String> bandIds,
    required bool canEditRoleAndBands,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) {
      return left(
        const MemberSaveFailure(
          ValidationFailure(message: 'No active organization.'),
        ),
      );
    }
    final repository = _ref.read(organizationRepositoryProvider);

    final instruments = original.instrumentsFor(roles);
    final tessituraChanged = tessitura != original.vocalRange;
    final profile = await repository.updateMusicianProfile(
      organizationId,
      original.id,
      instruments: instruments,
      // null leaves the stored value alone, '' clears it.
      minPitch: tessituraChanged ? (tessitura.minPitch ?? '') : null,
      maxPitch: tessituraChanged ? (tessitura.maxPitch ?? '') : null,
      notes: notes.trim(),
    );
    if (profile case Left(value: final failure)) {
      return left(MemberSaveFailure(failure));
    }

    if (!canEditRoleAndBands) return right(unit);

    if (isAdmin != original.isAdmin) {
      final role = await repository.setMemberRole(
        organizationId,
        original.id,
        isAdmin ? OrganizationRole.admin : OrganizationRole.member,
      );
      if (role case Left(value: final failure)) {
        return left(MemberSaveFailure(failure, step: MemberSaveStep.role));
      }
    }

    final links =
        _ref.read(activeBandMembersProvider).value ?? const <BandMember>[];
    final current = {
      for (final link in links)
        if (link.memberId == original.id) link.bandId: link,
    };
    for (final bandId in bandIds.difference(current.keys.toSet())) {
      final added = await repository.addBandMember(
        organizationId,
        bandId,
        original.id,
      );
      if (added case Left(value: final failure)) {
        return left(MemberSaveFailure(failure, step: MemberSaveStep.bands));
      }
    }
    for (final entry in current.entries) {
      if (bandIds.contains(entry.key)) continue;
      final removed = await repository.removeBandMember(
        organizationId,
        entry.value.id,
      );
      if (removed case Left(value: final failure)) {
        return left(MemberSaveFailure(failure, step: MemberSaveStep.bands));
      }
    }
    return right(unit);
  }

  Future<Either<Failure, Unit>> removeMember(TeamMember member) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    return _ref
        .read(organizationRepositoryProvider)
        .removeMember(organizationId, member.id);
  }

  Future<Either<Failure, Unit>> createBand(
    String name, {
    String? description,
    required int colorValue,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _ref
        .read(organizationRepositoryProvider)
        .createBand(
          organizationId,
          name,
          description: description,
          colorValue: colorValue,
        );
    return result.map((_) => unit);
  }

  Future<Either<Failure, Unit>> updateBand(TeamGroup group) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _ref
        .read(organizationRepositoryProvider)
        .updateBand(
          Band(
            id: group.id,
            organizationId: organizationId,
            name: group.name,
            description: group.description,
            colorValue: group.colorValue,
          ),
        );
    return result.map((_) => unit);
  }

  Future<Either<Failure, Unit>> deleteBand(String bandId) async {
    final organizationId = _organizationId;
    if (organizationId == null) return _noOrganization();
    final result = await _ref
        .read(organizationRepositoryProvider)
        .deleteBand(organizationId, bandId);
    if (result.isRight() && _ref.read(activeBandIdProvider) == bandId) {
      _ref.read(activeBandIdProvider.notifier).select(null);
    }
    return result;
  }
}

final rosterActionsProvider = Provider<RosterActions>(RosterActions.new);
