import 'package:battuta/core/services/supabase_client_manager.dart';
import 'package:battuta/features/sync/data/demo_cloud_sync_service.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoCloudSyncService Tests', () {
    test('memberIdToUuid converts member-1 to member-30 to deterministic UUIDs', () {
      final uuid1 = DemoCloudSyncService.memberIdToUuid('member-1');
      expect(uuid1, equals('00000000-0000-0000-0001-000000000001'));

      final uuid30 = DemoCloudSyncService.memberIdToUuid('member-30');
      expect(uuid30, equals('00000000-0000-0000-0001-000000000030'));
    });

    test('uuidToMemberId converts deterministic UUIDs back to member-X format', () {
      final id1 = DemoCloudSyncService.uuidToMemberId('00000000-0000-0000-0001-000000000001');
      expect(id1, equals('member-1'));

      final id30 = DemoCloudSyncService.uuidToMemberId('00000000-0000-0000-0001-000000000030');
      expect(id30, equals('member-30'));
    });

    test('pullDemoMembers returns null safely when unconfigured without crashing', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      final result = await service.pullDemoMembers();
      expect(result, isNull);
    });

    test('pullDemoGroups returns null safely when unconfigured', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      final result = await service.pullDemoGroups();
      expect(result, isNull);
    });

    test('pullDemoEvents returns null safely when unconfigured', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      final result = await service.pullDemoEvents();
      expect(result, isNull);
    });

    test('pushDemoMember returns false safely when unconfigured', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      const member = TeamMember(id: 'member-1', name: 'Joel', isAdmin: true);
      final result = await service.pushDemoMember(member);
      expect(result, isFalse);
    });

    test('pushDemoGroup returns false safely when unconfigured', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      const group = TeamGroup(id: 'group-alpha', name: 'Ensamble 1');
      final result = await service.pushDemoGroup(group);
      expect(result, isFalse);
    });

    test('pushDemoEvent returns false safely when unconfigured', () async {
      final service = DemoCloudSyncService(clientManager: SupabaseClientManager());
      final event = ServiceEvent(
        id: 'event-1',
        title: 'Sunday Worship',
        dateTime: DateTime(2026, 11, 15, 10, 0),
      );
      final result = await service.pushDemoEvent(event);
      expect(result, isFalse);
    });
  });
}
