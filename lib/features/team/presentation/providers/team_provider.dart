/// Battuta — Team Members Provider.
///
/// Manages the band and worship team roster, scheduling statuses,
/// and vocal/instrument assignments.
library;

import 'package:battuta/core/services/demo_mode_provider.dart';
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
  final List<TeamMember> _userMembers = [];

  @override
  List<TeamMember> build() {
    final isDemo = ref.watch(demoModeProvider);
    if (isDemo) {
      final userIds = _userMembers.map((m) => m.id).toSet();
      return [
        ..._userMembers,
        ..._initialSampleMembers().where((s) => !userIds.contains(s.id)),
      ];
    }
    return List.unmodifiable(_userMembers);
  }

  void addMember(TeamMember member) {
    _userMembers.add(member);
    ref.invalidateSelf();
  }

  void updateMember(TeamMember updated) {
    final idx = _userMembers.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _userMembers[idx] = updated;
    }
    state = [
      for (final m in state)
        if (m.id == updated.id) updated else m,
    ];
  }

  void removeMember(String id) {
    _userMembers.removeWhere((m) => m.id != id);
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
        name: 'Joel',
        roles: [TeamRole.keys, TeamRole.synth],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.scheduled,
        notes: 'Piano, Synthesizer & Worship Director',
        email: 'joel@battuta.music',
        isAdmin: true,
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-2',
        name: 'Raúl',
        roles: [TeamRole.acousticGuitar],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.scheduled,
        notes: 'Acoustic guitar rhythm & fingerpicking',
        email: 'raul@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-3',
        name: 'Pipe',
        roles: [TeamRole.bass],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Electric bass groove & fundamentals',
        email: 'pipe@battuta.music',
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-4',
        name: 'Jose',
        roles: [TeamRole.drums],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Drums & rhythm section lock',
        email: 'jose@battuta.music',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-5',
        name: 'Amparito',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.scheduled,
        notes: 'Lead voice & vocal harmony direction',
        email: 'amparito@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-6',
        name: 'Andrés',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.tenor,
        availability: AvailabilityStatus.available,
        notes: 'Tenor vocal harmonies',
        email: 'andres@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-7',
        name: 'Anita García',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Soprano lead & vocal support',
        email: 'anita.garcia@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-8',
        name: 'Daniel',
        roles: [TeamRole.bass, TeamRole.drums, TeamRole.sound],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Multi-instrumentalist: Bass, Drums & Front of House Sound',
        email: 'daniel@battuta.music',
        isAdmin: true,
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-9',
        name: 'Daniela',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Soprano backing vocals',
        email: 'daniela@battuta.music',
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-10',
        name: 'Diego',
        roles: [TeamRole.drums, TeamRole.synth, TeamRole.keys],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Drums, Synth pads & auxiliary keys',
        email: 'diego@battuta.music',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-11',
        name: 'Epsa',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Lead voice & vocal harmonies',
        email: 'epsa@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-12',
        name: 'Humberto',
        roles: [TeamRole.keys, TeamRole.backingVocal],
        vocalRange: VocalTessitura.baritone,
        availability: AvailabilityStatus.available,
        notes: 'Piano, keyboards & vocal support',
        email: 'humberto@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-13',
        name: 'Jeimy',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Chorus vocals',
        email: 'jeimy@battuta.music',
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-14',
        name: 'Juanse',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.tenor,
        availability: AvailabilityStatus.available,
        notes: 'Tenor lead & vocal direction',
        email: 'juanse@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-15',
        name: 'July',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Soprano lead & chorus harmonies',
        email: 'july@battuta.music',
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-16',
        name: 'Laura',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Lead voice & vocal harmonies',
        email: 'laura@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-17',
        name: 'Mile',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Alto lead & backing voice',
        email: 'mile@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-18',
        name: 'Mona',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Vocal lead & chorus',
        email: 'mona@battuta.music',
        isAdmin: true,
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-19',
        name: 'Monica',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Chorus vocals',
        email: 'monica@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-20',
        name: 'Nico',
        roles: [TeamRole.electricGuitar],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Lead electric guitar & ambient textures',
        email: 'nico@battuta.music',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-21',
        name: 'P. Henry',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.baritone,
        availability: AvailabilityStatus.available,
        notes: 'Lead vocals & pastoral guidance',
        email: 'henry@battuta.music',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-22',
        name: 'Ricardo',
        roles: [TeamRole.acousticGuitar, TeamRole.leadVocal, TeamRole.backingVocal, TeamRole.keys],
        vocalRange: VocalTessitura.tenor,
        availability: AvailabilityStatus.scheduled,
        notes: 'Acoustic guitar, Lead voice, Piano',
        email: 'ricardo@battuta.music',
        isAdmin: true,
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
      TeamMember(
        id: 'member-23',
        name: 'Samu García',
        roles: [TeamRole.keys],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Piano & keyboard arrangements',
        email: 'samu.garcia@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-24',
        name: 'Samu Saldaña',
        roles: [TeamRole.drums],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Drums & percussion',
        email: 'samu.saldana@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-25',
        name: 'Sandra',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Alto lead & chorus',
        email: 'sandra@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-26',
        name: 'Sara',
        roles: [TeamRole.leadVocal, TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Soprano lead & chorus',
        email: 'sara@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-27',
        name: 'Saris',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.soprano,
        availability: AvailabilityStatus.available,
        notes: 'Soprano chorus harmonies',
        email: 'saris@battuta.music',
        groupIds: ['group-gamma'],
      ),
      TeamMember(
        id: 'member-28',
        name: 'Vicky',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Alto chorus',
        email: 'vicky@battuta.music',
        groupIds: ['group-alpha'],
      ),
      TeamMember(
        id: 'member-29',
        name: 'Zulma',
        roles: [TeamRole.backingVocal],
        vocalRange: VocalTessitura.alto,
        availability: AvailabilityStatus.available,
        notes: 'Alto chorus harmonies',
        email: 'zulma@battuta.music',
        groupIds: ['group-beta'],
      ),
      TeamMember(
        id: 'member-30',
        name: 'Margarita',
        roles: [TeamRole.sound],
        vocalRange: VocalTessitura.none,
        availability: AvailabilityStatus.available,
        notes: 'Ingeniera de Sonido / Front of House Audio',
        email: 'margarita@battuta.music',
        groupIds: ['group-alpha', 'group-beta', 'group-gamma'],
      ),
    ];
  }
}
