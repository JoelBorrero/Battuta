/// Battuta — Team Groups Provider.
///
/// Manages worship sub-teams, arrangements, and musician groupings
/// (e.g. Band Alpha, Band Beta, Youth Team) where members rotate together.
library;

import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamGroupsProvider =
    NotifierProvider<TeamGroupsNotifier, List<TeamGroup>>(
      TeamGroupsNotifier.new,
    );

class TeamGroupsNotifier extends Notifier<List<TeamGroup>> {
  final List<TeamGroup> _userGroups = [];

  @override
  List<TeamGroup> build() {
    final isDemo = ref.watch(demoModeProvider);
    if (isDemo) {
      return [..._userGroups, ..._initialSampleGroups()];
    }
    return List.unmodifiable(_userGroups);
  }

  void addGroup(TeamGroup group) {
    _userGroups.add(group);
    ref.invalidateSelf();
  }

  void updateGroup(TeamGroup updated) {
    final idx = _userGroups.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _userGroups[idx] = updated;
    }
    state = [
      for (final g in state)
        if (g.id == updated.id) updated else g,
    ];
  }

  void removeGroup(String id) {
    _userGroups.removeWhere((g) => g.id != id);
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
