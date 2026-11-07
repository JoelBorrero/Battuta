/// Battuta — Team Members Provider.
///
/// Manages the band and worship team roster, scheduling statuses,
/// and vocal/instrument assignments.
library;

import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamMembersProvider =
    NotifierProvider<TeamMembersNotifier, List<TeamMember>>(
      TeamMembersNotifier.new,
    );

/// Manages the currently active team member ID acting within the app session.
/// Defaults to 'member-1' (Sarah Jenkins - Admin).
class CurrentMemberIdNotifier extends Notifier<String?> {
  CurrentMemberIdNotifier([this._initialId = 'member-1']);
  final String? _initialId;

  @override
  String? build() => _initialId;

  void setMemberId(String? id) => state = id;
}

final currentMemberIdProvider =
    NotifierProvider<CurrentMemberIdNotifier, String?>(
      CurrentMemberIdNotifier.new,
    );

/// Resolves the currently active [TeamMember] entity.
final currentMemberProvider = Provider<TeamMember?>((ref) {
  final memberId = ref.watch(currentMemberIdProvider);
  if (memberId == null) return null;
  final members = ref.watch(teamMembersProvider);
  return members.cast<TeamMember?>().firstWhere(
    (m) => m?.id == memberId,
    orElse: () => null,
  );
});

/// Whether the currently active user has administrator permissions.
/// Returns true if the member has `isAdmin == true`, or if no members are configured (fail-safe).
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final members = ref.watch(teamMembersProvider);
  if (members.isEmpty) return true; // Fail-safe: empty roster allows configuration
  final current = ref.watch(currentMemberProvider);
  if (current == null) return true; // Fail-safe: fallback to admin
  return current.isAdmin;
});

class TeamMembersNotifier extends Notifier<List<TeamMember>> {
  @override
  List<TeamMember> build() {
    return _initialSampleMembers();
  }

  void addMember(TeamMember member) {
    state = [...state, member];
  }

  void updateMember(TeamMember updated) {
    state = [
      for (final m in state)
        if (m.id == updated.id) updated else m,
    ];
  }

  void removeMember(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void cycleAvailability(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            availability: switch (m.availability) {
              AvailabilityStatus.available => AvailabilityStatus.scheduled,
              AvailabilityStatus.scheduled => AvailabilityStatus.unavailable,
              AvailabilityStatus.unavailable => AvailabilityStatus.available,
            },
          )
        else
          m,
    ];
  }

  static List<TeamMember> _initialSampleMembers() {
    return const [
      TeamMember(
        id: 'member-1',
        name: 'Sarah Jenkins',
        roles: [TeamRole.leadVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.scheduled,
        notes: 'Available for 1st service',
        email: 'sarah.j@worship.org',
        isAdmin: true,
        groupIds: ['group-alpha', 'group-beta'],
      ),
      TeamMember(
        id: 'member-2',
        name: 'David Chen',
        roles: [TeamRole.acousticGuitar, TeamRole.backingVocal],
        vocalRange: VocalTessitura.tenor,
        availability: AvailabilityStatus.scheduled,
        notes: 'Leading acoustic set & harmony vocals',
        email: 'david.c@worship.org',
        groupIds: ['group-alpha', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-3',
        name: 'Marcus Miller',
        roles: [TeamRole.bass],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Brought 5-string bass',
        email: 'marcus.m@worship.org',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-4',
        name: 'Elena Rostova',
        roles: [TeamRole.keys, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Main synth & alto vocals',
        email: 'elena.r@worship.org',
        groupIds: ['group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-5',
        name: 'James Wilson',
        roles: [TeamRole.drums],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'In-ear click track master',
        email: 'james.w@worship.org',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-6',
        name: 'Mateo Rodriguez',
        roles: [TeamRole.electricGuitar, TeamRole.backingVocal],
        vocalRange: VocalTessitura.baritone,
        availability: AvailabilityStatus.unavailable,
        notes: 'Traveling this Sunday',
        email: 'mateo.r@worship.org',
        groupIds: ['group-alpha'],
      ),
    ];
  }
}
