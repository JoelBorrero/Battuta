/// Battuta — Team Groups Provider.
///
/// Manages worship sub-teams, arrangements, and musician groupings
/// (e.g. Band Alpha, Band Beta, Youth Team) where members rotate together.
library;

import 'package:battuta/core/services/demo_mode_provider.dart';
import 'package:battuta/features/sync/data/demo_cloud_sync_service.dart';
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
      Future.microtask(() => _initDemoCloudSync());
      return [..._userGroups, ..._initialSampleGroups()];
    }
    return List.unmodifiable(_userGroups);
  }

  Future<void> _initDemoCloudSync() async {
    final syncService = ref.read(demoCloudSyncServiceProvider);
    final remoteGroups = await syncService.pullDemoGroups();
    if (remoteGroups != null && remoteGroups.isNotEmpty) {
      final Map<String, TeamGroup> merged = {
        for (final g in state) g.id: g,
      };
      for (final rg in remoteGroups) {
        merged[rg.id] = rg;
      }
      state = merged.values.toList();
    }
  }

  void addGroup(TeamGroup group) {
    _userGroups.add(group);
    ref.invalidateSelf();
    if (ref.read(demoModeProvider)) {
      ref.read(demoCloudSyncServiceProvider).pushDemoGroup(group);
    }
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
    if (ref.read(demoModeProvider)) {
      ref.read(demoCloudSyncServiceProvider).pushDemoGroup(updated);
    }
  }

  void removeGroup(String id) {
    _userGroups.removeWhere((g) => g.id != id);
    state = state.where((g) => g.id != id).toList();
  }

  static List<TeamGroup> _initialSampleGroups() {
    return const [
      TeamGroup(
        id: 'group-alpha',
        name: 'Ensamble 1',
        description: 'Primer ensamble de alabanza y adoración',
        colorValue: 0xFFE5A93C, // Stage amber
      ),
      TeamGroup(
        id: 'group-beta',
        name: 'Ensamble 2',
        description: 'Segundo ensamble de alabanza y adoración',
        colorValue: 0xFF4A90E2, // Stage blue
      ),
      TeamGroup(
        id: 'group-gamma',
        name: 'Ensamble 3',
        description: 'Tercer ensamble de alabanza y adoración',
        colorValue: 0xFF50E3C2, // Stage teal
      ),
    ];
  }
}
