/// Battuta — Demo Cloud Sync Service.
///
/// Coordinates cloud synchronization and live Supabase Realtime broadcasting
/// for Demo Mode across multiple devices, ensuring all devices running in Demo Mode
/// see synchronized team members, ensembles, and rehearsal schedules in real time.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/core/utils/logger.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Dedicated UUID for the global Battuta Demo Worship Team workspace.
const String kDemoTeamId = '00000000-0000-0000-0000-000000000001';

/// Provider for [DemoCloudSyncService].
final demoCloudSyncServiceProvider = Provider<DemoCloudSyncService>((ref) {
  final clientManager = ref.watch(supabaseClientManagerProvider);
  return DemoCloudSyncService(clientManager: clientManager);
});

class DemoCloudSyncService {
  DemoCloudSyncService({required this.clientManager});

  final SupabaseClientManager clientManager;
  supa.RealtimeChannel? _realtimeChannel;

  supa.SupabaseClient? get _client => clientManager.client;

  /// Helper converting `member-X` string IDs to deterministic UUIDs.
  static String memberIdToUuid(String memberId) {
    if (memberId.startsWith('member-')) {
      final num = int.tryParse(memberId.replaceFirst('member-', '')) ?? 0;
      return '00000000-0000-0000-0001-${num.toString().padLeft(12, '0')}';
    }
    return memberId;
  }

  /// Helper converting deterministic UUIDs back to `member-X` format.
  static String uuidToMemberId(String uuid) {
    if (uuid.startsWith('00000000-0000-0000-0001-')) {
      final numPart = uuid.substring('00000000-0000-0000-0001-'.length);
      final num = int.tryParse(numPart) ?? 0;
      return 'member-$num';
    }
    return uuid;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULL DEMO DATA FROM SUPABASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pulls all demo team members from Supabase.
  Future<List<TeamMember>?> pullDemoMembers() async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('team_members')
          .select()
          .eq('is_demo', true)
          .timeout(const Duration(seconds: 6));

      final list = (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapRowToMember)
          .whereType<TeamMember>()
          .toList();

      AppLogger.info('DemoCloudSync: pulled ${list.length} demo members');
      return list;
    } on SocketException catch (e) {
      AppLogger.info('DemoCloudSync: network offline ($e)');
      return null;
    } catch (e) {
      AppLogger.info('DemoCloudSync: table not present or pull skipped: $e');
      return null;
    }
  }

  /// Pulls all demo ensembles/groups from Supabase.
  Future<List<TeamGroup>?> pullDemoGroups() async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('team_groups')
          .select()
          .eq('is_demo', true)
          .timeout(const Duration(seconds: 6));

      final list = (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => TeamGroup(
                id: row['id'] as String,
                name: row['name'] as String? ?? 'Group',
                description: row['description'] as String?,
                colorValue: (row['color_value'] as num?)?.toInt() ?? 0xFFE5A93C,
              ))
          .toList();

      AppLogger.info('DemoCloudSync: pulled ${list.length} demo groups');
      return list;
    } catch (e) {
      AppLogger.info('DemoCloudSync: group pull skipped: $e');
      return null;
    }
  }

  /// Pulls all demo calendar events from Supabase.
  Future<List<ServiceEvent>?> pullDemoEvents() async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('calendar_events')
          .select()
          .eq('is_demo', true)
          .timeout(const Duration(seconds: 6));

      final list = (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapRowToEvent)
          .whereType<ServiceEvent>()
          .toList();

      AppLogger.info('DemoCloudSync: pulled ${list.length} demo events');
      return list;
    } catch (e) {
      AppLogger.info('DemoCloudSync: event pull skipped: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUSH DEMO MUTATIONS TO SUPABASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pushes a demo member change to Supabase.
  Future<bool> pushDemoMember(TeamMember member) async {
    final client = _client;
    if (client == null) return false;

    try {
      final payload = {
        'id': memberIdToUuid(member.id),
        'team_id': kDemoTeamId,
        'name': member.name,
        'roles': member.roles.map((r) => r.name).toList(),
        'status': member.availability.name,
        'is_admin': member.isAdmin,
        'group_ids': member.groupIds,
        'notes': member.notes,
        'email': member.email,
        'is_demo': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client
          .from('team_members')
          .upsert(payload)
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (e) {
      AppLogger.info('DemoCloudSync: push member skipped: $e');
      return false;
    }
  }

  /// Pushes a demo ensemble/group change to Supabase.
  Future<bool> pushDemoGroup(TeamGroup group) async {
    final client = _client;
    if (client == null) return false;

    try {
      final payload = {
        'id': group.id,
        'team_id': kDemoTeamId,
        'name': group.name,
        'description': group.description,
        'color_value': group.colorValue,
        'is_demo': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client
          .from('team_groups')
          .upsert(payload)
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (e) {
      AppLogger.info('DemoCloudSync: push group skipped: $e');
      return false;
    }
  }

  /// Pushes a demo calendar event change to Supabase.
  Future<bool> pushDemoEvent(ServiceEvent event) async {
    final client = _client;
    if (client == null) return false;

    try {
      final assignmentsJson = jsonEncode([
        for (final a in event.assignments)
          {
            'memberId': a.memberId,
            'role': a.role.name,
            'status': a.status.name,
          }
      ]);

      final payload = {
        'id': event.id,
        'team_id': kDemoTeamId,
        'title': event.title,
        'date_time': event.dateTime.toUtc().toIso8601String(),
        'location': event.location,
        'notes': event.notes,
        'assignments_json': assignmentsJson,
        'is_demo': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client
          .from('calendar_events')
          .upsert(payload)
          .timeout(const Duration(seconds: 6));
      return true;
    } catch (e) {
      AppLogger.info('DemoCloudSync: push event skipped: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REALTIME MULTI-DEVICE SUBSCRIPTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subscribes to Supabase Realtime for live changes across demo devices.
  void subscribeToRealtime({
    void Function(TeamMember member)? onMemberUpdated,
    void Function(TeamGroup group)? onGroupUpdated,
    void Function(ServiceEvent event)? onEventUpdated,
  }) {
    final client = _client;
    if (client == null) return;

    // Dispose any previous channel
    _realtimeChannel?.unsubscribe();

    try {
      _realtimeChannel = client.channel('public:demo_team_sync');

      // Listen for team member changes
      _realtimeChannel?.onPostgresChanges(
        event: supa.PostgresChangeEvent.all,
        schema: 'public',
        table: 'team_members',
        filter: const supa.PostgresChangeFilter(
          type: supa.PostgresChangeFilterType.eq,
          column: 'is_demo',
          value: true,
        ),
        callback: (payload) {
          final row = payload.newRecord;
          if (row.isNotEmpty) {
            final member = _mapRowToMember(row);
            if (member != null && onMemberUpdated != null) {
              onMemberUpdated(member);
            }
          }
        },
      );

      // Listen for calendar event changes
      _realtimeChannel?.onPostgresChanges(
        event: supa.PostgresChangeEvent.all,
        schema: 'public',
        table: 'calendar_events',
        filter: const supa.PostgresChangeFilter(
          type: supa.PostgresChangeFilterType.eq,
          column: 'is_demo',
          value: true,
        ),
        callback: (payload) {
          final row = payload.newRecord;
          if (row.isNotEmpty) {
            final event = _mapRowToEvent(row);
            if (event != null && onEventUpdated != null) {
              onEventUpdated(event);
            }
          }
        },
      );

      // Listen for group changes
      _realtimeChannel?.onPostgresChanges(
        event: supa.PostgresChangeEvent.all,
        schema: 'public',
        table: 'team_groups',
        filter: const supa.PostgresChangeFilter(
          type: supa.PostgresChangeFilterType.eq,
          column: 'is_demo',
          value: true,
        ),
        callback: (payload) {
          final row = payload.newRecord;
          if (row.isNotEmpty && onGroupUpdated != null) {
            onGroupUpdated(TeamGroup(
              id: row['id'] as String,
              name: row['name'] as String? ?? 'Group',
              description: row['description'] as String?,
              colorValue: (row['color_value'] as num?)?.toInt() ?? 0xFFE5A93C,
            ));
          }
        },
      );

      _realtimeChannel?.subscribe();
      AppLogger.info('DemoCloudSync: subscribed to live demo realtime channel');
    } catch (e) {
      AppLogger.info('DemoCloudSync: realtime setup skipped: $e');
    }
  }

  /// Unsubscribes from the realtime channel when demo mode is disabled.
  void unsubscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE DESERIALIZERS
  // ═══════════════════════════════════════════════════════════════════════════

  TeamMember? _mapRowToMember(Map<String, dynamic> row) {
    try {
      final rawId = row['id'] as String? ?? '';
      final memberId = uuidToMemberId(rawId);
      final rawRoles = row['roles'];
      final List<TeamRole> roles = [];
      if (rawRoles is List) {
        for (final r in rawRoles) {
          final str = r.toString();
          final role = TeamRole.values.where((v) => v.name == str).firstOrNull;
          if (role != null) roles.add(role);
        }
      }
      if (roles.isEmpty) roles.add(TeamRole.keys);

      final rawStatus = row['status'] as String? ?? 'available';
      final status = AvailabilityStatus.values
          .where((s) => s.name == rawStatus)
          .firstOrNull ?? AvailabilityStatus.available;

      final rawGroups = row['group_ids'];
      final List<String> groupIds = [];
      if (rawGroups is List) {
        for (final g in rawGroups) {
          groupIds.add(g.toString());
        }
      }

      return TeamMember(
        id: memberId,
        name: row['name'] as String? ?? 'Member',
        roles: roles,
        availability: status,
        isAdmin: row['is_admin'] as bool? ?? false,
        groupIds: groupIds,
        notes: row['notes'] as String?,
        email: row['email'] as String?,
      );
    } catch (e) {
      AppLogger.error('Failed to parse member row: $e');
      return null;
    }
  }

  ServiceEvent? _mapRowToEvent(Map<String, dynamic> row) {
    try {
      final id = row['id'] as String? ?? '';
      final title = row['title'] as String? ?? 'Service';
      final dateTime = DateTime.tryParse(row['date_time']?.toString() ?? '') ??
          DateTime.now();
      final location = row['location'] as String? ?? 'Sanctuary';
      final notes = row['notes'] as String?;

      final List<ServiceAssignment> assignments = [];
      final rawAssignments = row['assignments_json'];
      if (rawAssignments is String && rawAssignments.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawAssignments);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                final memberId = item['memberId']?.toString() ?? '';
                final roleStr = item['role']?.toString() ?? '';
                final statusStr = item['status']?.toString() ?? '';

                final role = TeamRole.values
                    .where((r) => r.name == roleStr)
                    .firstOrNull ?? TeamRole.leadVocal;
                final status = AssignmentStatus.values
                    .where((s) => s.name == statusStr)
                    .firstOrNull ?? AssignmentStatus.confirmed;

                assignments.add(ServiceAssignment(
                  memberId: memberId,
                  role: role,
                  status: status,
                ));
              }
            }
          }
        } catch (_) {}
      }

      return ServiceEvent(
        id: id,
        title: title,
        dateTime: dateTime,
        location: location,
        notes: notes,
        assignments: assignments,
      );
    } catch (e) {
      AppLogger.error('Failed to parse event row: $e');
      return null;
    }
  }
}
