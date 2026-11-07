/// Battuta — Team Groups Provider.
///
/// Manages worship sub-teams, arrangements, and musician groupings
/// (e.g. Band Alpha, Band Beta, Youth Team) where members rotate together.
library;

import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamGroupsProvider =
    NotifierProvider<TeamGroupsNotifier, List<TeamGroup>>(
      TeamGroupsNotifier.new,
    );

class TeamGroupsNotifier extends Notifier<List<TeamGroup>> {
  @override
  List<TeamGroup> build() {
    return _initialSampleGroups();
  }

  void addGroup(TeamGroup group) {
    state = [...state, group];
  }

  void updateGroup(TeamGroup updated) {
    state = [
      for (final g in state)
        if (g.id == updated.id) updated else g,
    ];
  }

  void removeGroup(String id) {
    state = state.where((g) => g.id != id).toList();
  }

  static List<TeamGroup> _initialSampleGroups() {
    return const [
      TeamGroup(
        id: 'group-alpha',
        name: 'Band Alpha (Contemporary)',
        description: 'Primary Sunday morning full rhythm section & vocal team',
        colorValue: 0xFFE5A93C, // Stage amber
      ),
      TeamGroup(
        id: 'group-beta',
        name: 'Band Beta (Acoustic)',
        description: 'Acoustic-driven arrangement with piano & vocal harmonies',
        colorValue: 0xFF4A90E2, // Stage blue
      ),
      TeamGroup(
        id: 'group-gamma',
        name: 'Youth Band',
        description: 'Youth night and midweek praise team',
        colorValue: 0xFF50E3C2, // Stage teal
      ),
    ];
  }
}

/// Helper provider to get members belonging to a specific group ID.
final membersInGroupFamily =
    Provider.family<List<TeamMember>, ({String groupId, List<TeamMember> members})>(
  (ref, arg) {
    return arg.members.where((m) => m.groupIds.contains(arg.groupId)).toList();
  },
);
