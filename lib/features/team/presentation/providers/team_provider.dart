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
        role: TeamRole.leadVocal,
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.scheduled,
        notes: 'Available for 1st service',
        email: 'sarah.j@worship.org',
      ),
      TeamMember(
        id: 'member-2',
        name: 'David Chen',
        role: TeamRole.acousticGuitar,
        vocalRange: VocalTessitura.tenor,
        availability: AvailabilityStatus.scheduled,
        notes: 'Leading acoustic set',
        email: 'david.c@worship.org',
      ),
      TeamMember(
        id: 'member-3',
        name: 'Marcus Miller',
        role: TeamRole.bass,
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Brought 5-string bass',
        email: 'marcus.m@worship.org',
      ),
      TeamMember(
        id: 'member-4',
        name: 'Elena Rostova',
        role: TeamRole.keys,
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Main synth & pads',
        email: 'elena.r@worship.org',
      ),
      TeamMember(
        id: 'member-5',
        name: 'James Wilson',
        role: TeamRole.drums,
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'In-ear click track master',
        email: 'james.w@worship.org',
      ),
      TeamMember(
        id: 'member-6',
        name: 'Mateo Rodriguez',
        role: TeamRole.electricGuitar,
        vocalRange: VocalTessitura.baritone,
        availability: AvailabilityStatus.unavailable,
        notes: 'Traveling this Sunday',
        email: 'mateo.r@worship.org',
      ),
    ];
  }
}

