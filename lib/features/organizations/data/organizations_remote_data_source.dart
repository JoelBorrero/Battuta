/// Thin Supabase calls for organizations, members, bands, invites, archiving
/// and notifications. RPC names and columns follow `supabase/README.md`.
///
/// Every method throws a typed `Failure` (see `BackendErrorCode`); the
/// repository turns that into an `Either`.
library;

import 'dart:async';

import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

enum BackendChangeType { insert, update, delete, resync }

/// A realtime change of one table (or [BackendChangeType.resync] after a
/// reconnect, meaning "refresh everything").
class BackendChange {
  const BackendChange({
    required this.table,
    required this.type,
    this.record = const {},
    this.oldRecord = const {},
  });

  const BackendChange.resync()
    : table = '',
      type = BackendChangeType.resync,
      record = const {},
      oldRecord = const {};

  final String table;
  final BackendChangeType type;
  final Map<String, dynamic> record;
  final Map<String, dynamic> oldRecord;
}

abstract interface class OrganizationsRemoteDataSource {
  /// The id of the signed-in user, or `null`.
  String? get currentUserId;

  // Organizations
  Future<List<Organization>> myOrganizations({bool includeArchived = false});
  Future<Organization> createOrganization(String name);
  Future<Organization> renameOrganization(String organizationId, String name);
  Future<OrganizationQuota> organizationQuota(String organizationId);
  Future<void> leaveOrganization(String organizationId);

  // Members
  Future<List<OrganizationMember>> fetchMembers(String organizationId);
  Future<List<OrganizationMember>> fetchMyMemberships();
  Future<OrganizationMember> updateMusicianProfile(
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  });
  Future<OrganizationMember> setMemberRole(
    String memberId,
    OrganizationRole role,
  );
  Future<void> removeMember(String memberId);

  // Bands
  Future<List<Band>> fetchBands(String organizationId);
  Future<Band> createBand(Band band);
  Future<Band> updateBand(Band band);
  Future<void> deleteBand(String bandId);
  Future<List<BandMember>> fetchBandMembers(String organizationId);
  Future<BandMember> addBandMember({
    required String organizationId,
    required String bandId,
    required String memberId,
  });
  Future<void> removeBandMember(String bandMemberId);

  // Invites
  Future<List<InviteLink>> fetchInviteLinks(String organizationId);
  Future<InviteLink> createInviteLink(
    String organizationId, {
    String? bandId,
    Duration expiresIn = const Duration(days: 7),
    int? maxUses,
  });
  Future<InviteLink> revokeInviteLink(String linkId);
  Future<OrganizationMember> joinWithInviteLink(String token);
  Future<List<Invitation>> fetchInvitations(String organizationId);
  Future<List<Invitation>> fetchMyInvitations();
  Future<Invitation> inviteUserByUsername(
    String organizationId,
    String username, {
    String? bandId,
  });
  Future<Invitation> respondToInvitation(String invitationId, bool accept);
  Future<Invitation> cancelInvitation(String invitationId);
  Future<List<UserProfile>> searchProfiles(String query);

  // Archiving
  Future<ArchiveRequest?> fetchArchiveRequest(String organizationId);
  Future<Organization> requestOrganizationArchive(String organizationId);
  Future<Organization> approveOrganizationArchive(String organizationId);
  Future<Organization> cancelOrganizationArchive(String organizationId);

  // Notifications
  Future<List<AppNotification>> fetchNotifications({int limit = 100});
  Future<int> markNotificationsRead([List<String>? ids]);

  /// Realtime changes of the tables the app caches. Emits
  /// [BackendChangeType.resync] when the connection came back.
  Stream<BackendChange> changes();
}

class SupabaseOrganizationsRemoteDataSource extends SupabaseGateway
    implements OrganizationsRemoteDataSource {
  SupabaseOrganizationsRemoteDataSource(super.clientProvider);

  static const _memberSelect =
      '*, profiles(username, display_name, avatar_url)';

  static List<Map<String, dynamic>> _rows(Object? data) =>
      (data as List).cast<Map<String, dynamic>>();

  static Map<String, dynamic> _row(Object? data) {
    // RPCs returning a composite sometimes come back as a one element list.
    if (data is List) return (data.single as Map).cast<String, dynamic>();
    return (data as Map).cast<String, dynamic>();
  }

  // ---- Organizations -------------------------------------------------------

  @override
  Future<List<Organization>> myOrganizations({bool includeArchived = false}) =>
      run((c, _) async {
        final data = await c.rpc(
          'my_organizations',
          params: {'p_include_archived': includeArchived},
        );
        return _rows(data).map(Organization.fromJson).toList();
      });

  @override
  Future<Organization> createOrganization(String name) => run((c, _) async {
    final data = await c.rpc('create_organization', params: {'p_name': name});
    return Organization.fromJson(_row(data));
  });

  @override
  Future<Organization> renameOrganization(String organizationId, String name) =>
      run((c, _) async {
        final data = await c
            .from('organizations')
            .update({'name': name})
            .eq('id', organizationId)
            .select()
            .single();
        return Organization.fromJson(data);
      });

  @override
  Future<OrganizationQuota> organizationQuota(String organizationId) =>
      run((c, _) async {
        final data = await c.rpc(
          'organization_quota',
          params: {'p_org': organizationId},
        );
        return OrganizationQuota.fromJson(_row(data));
      });

  @override
  Future<void> leaveOrganization(String organizationId) => run((c, _) async {
    await c.rpc(
      'leave_organization',
      params: {'p_organization_id': organizationId},
    );
  });

  // ---- Members -------------------------------------------------------------

  @override
  Future<List<OrganizationMember>> fetchMembers(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('organization_members')
            .select(_memberSelect)
            .eq('organization_id', organizationId);
        return _rows(data).map(OrganizationMember.fromJson).toList();
      });

  @override
  Future<List<OrganizationMember>> fetchMyMemberships() => run((c, uid) async {
    final data = await c
        .from('organization_members')
        .select(_memberSelect)
        .eq('user_id', uid);
    return _rows(data).map(OrganizationMember.fromJson).toList();
  });

  @override
  Future<OrganizationMember> updateMusicianProfile(
    String memberId, {
    List<String>? instruments,
    String? minPitch,
    String? maxPitch,
    String? notes,
  }) => run((c, _) async {
    // null = leave unchanged, empty string = clear.
    Object? text(String v) => v.trim().isEmpty ? null : v.trim();
    final values = <String, dynamic>{
      'instruments': ?instruments,
      if (minPitch != null) 'min_pitch': text(minPitch),
      if (maxPitch != null) 'max_pitch': text(maxPitch),
      if (notes != null) 'notes': text(notes),
    };
    final data = await c
        .from('organization_members')
        .update(values)
        .eq('id', memberId)
        .select(_memberSelect)
        .single();
    return OrganizationMember.fromJson(data);
  });

  @override
  Future<OrganizationMember> setMemberRole(
    String memberId,
    OrganizationRole role,
  ) => run((c, _) async {
    final data = await c.rpc(
      'set_member_role',
      params: {'p_member_id': memberId, 'p_role': role.name},
    );
    return OrganizationMember.fromJson(_row(data));
  });

  @override
  Future<void> removeMember(String memberId) => run((c, _) async {
    await c.rpc('remove_member', params: {'p_member_id': memberId});
  });

  // ---- Bands ---------------------------------------------------------------

  @override
  Future<List<Band>> fetchBands(String organizationId) => run((c, _) async {
    final data = await c
        .from('bands')
        .select()
        .eq('organization_id', organizationId);
    return _rows(data).map(Band.fromJson).toList();
  });

  @override
  Future<Band> createBand(Band band) => run((c, _) async {
    final data = await c
        .from('bands')
        .insert({
          'id': band.id,
          'organization_id': band.organizationId,
          'name': band.name,
          'description': band.description,
          'color_value': band.colorValue,
        })
        .select()
        .single();
    return Band.fromJson(data);
  });

  @override
  Future<Band> updateBand(Band band) => run((c, _) async {
    final data = await c
        .from('bands')
        .update({
          'name': band.name,
          'description': band.description,
          'color_value': band.colorValue,
        })
        .eq('id', band.id)
        .select()
        .single();
    return Band.fromJson(data);
  });

  @override
  Future<void> deleteBand(String bandId) => run((c, _) async {
    await c.from('bands').delete().eq('id', bandId);
  });

  @override
  Future<List<BandMember>> fetchBandMembers(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('band_members')
            .select()
            .eq('organization_id', organizationId);
        return _rows(data).map(BandMember.fromJson).toList();
      });

  @override
  Future<BandMember> addBandMember({
    required String organizationId,
    required String bandId,
    required String memberId,
  }) => run((c, _) async {
    final data = await c
        .from('band_members')
        .insert({
          'organization_id': organizationId,
          'band_id': bandId,
          'member_id': memberId,
        })
        .select()
        .single();
    return BandMember.fromJson(data);
  });

  @override
  Future<void> removeBandMember(String bandMemberId) => run((c, _) async {
    await c.from('band_members').delete().eq('id', bandMemberId);
  });

  // ---- Invites -------------------------------------------------------------

  @override
  Future<List<InviteLink>> fetchInviteLinks(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('invite_links')
            .select()
            .eq('organization_id', organizationId);
        return _rows(data).map(InviteLink.fromJson).toList();
      });

  @override
  Future<InviteLink> createInviteLink(
    String organizationId, {
    String? bandId,
    Duration expiresIn = const Duration(days: 7),
    int? maxUses,
  }) => run((c, _) async {
    final data = await c.rpc(
      'create_invite_link',
      params: {
        'p_organization_id': organizationId,
        'p_band_id': bandId,
        'p_expires_in': '${expiresIn.inSeconds} seconds',
        'p_max_uses': maxUses,
      },
    );
    return InviteLink.fromJson(_row(data));
  });

  @override
  Future<InviteLink> revokeInviteLink(String linkId) => run((c, _) async {
    final data = await c.rpc(
      'revoke_invite_link',
      params: {'p_link_id': linkId},
    );
    return InviteLink.fromJson(_row(data));
  });

  @override
  Future<OrganizationMember> joinWithInviteLink(String token) =>
      run((c, _) async {
        final data = await c.rpc(
          'join_with_invite_link',
          params: {'p_token': token},
        );
        return OrganizationMember.fromJson(_row(data));
      });

  @override
  Future<List<Invitation>> fetchInvitations(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('invitations')
            .select(
              '*, organizations(name), '
              'invitee:profiles!invited_user_id(username, display_name)',
            )
            .eq('organization_id', organizationId);
        return _rows(data).map(Invitation.fromJson).toList();
      });

  @override
  Future<List<Invitation>> fetchMyInvitations() => run((c, uid) async {
    final data = await c
        .from('invitations')
        .select('*, organizations(name)')
        .eq('invited_user_id', uid);
    return _rows(data).map(Invitation.fromJson).toList();
  });

  @override
  Future<Invitation> inviteUserByUsername(
    String organizationId,
    String username, {
    String? bandId,
  }) => run((c, _) async {
    final data = await c.rpc(
      'invite_user_by_username',
      params: {
        'p_organization_id': organizationId,
        'p_username': username,
        'p_band_id': bandId,
      },
    );
    return Invitation.fromJson(_row(data));
  });

  @override
  Future<Invitation> respondToInvitation(String invitationId, bool accept) =>
      run((c, _) async {
        final data = await c.rpc(
          'respond_to_invitation',
          params: {'p_invitation_id': invitationId, 'p_accept': accept},
        );
        return Invitation.fromJson(_row(data));
      });

  @override
  Future<Invitation> cancelInvitation(String invitationId) => run((c, _) async {
    final data = await c.rpc(
      'cancel_invitation',
      params: {'p_invitation_id': invitationId},
    );
    return Invitation.fromJson(_row(data));
  });

  @override
  Future<List<UserProfile>> searchProfiles(String query) => run((c, _) async {
    final data = await c.rpc('search_profiles', params: {'p_query': query});
    return _rows(data).map(UserProfile.fromJson).toList();
  });

  // ---- Archiving -----------------------------------------------------------

  @override
  Future<ArchiveRequest?> fetchArchiveRequest(String organizationId) =>
      run((c, _) async {
        final data = await c
            .from('organization_archive_requests')
            .select('*, organization_archive_approvals(user_id, approved_at)')
            .eq('organization_id', organizationId)
            .maybeSingle();
        return data == null ? null : ArchiveRequest.fromJson(data);
      });

  @override
  Future<Organization> requestOrganizationArchive(String organizationId) =>
      _archiveRpc('request_organization_archive', organizationId);

  @override
  Future<Organization> approveOrganizationArchive(String organizationId) =>
      _archiveRpc('approve_organization_archive', organizationId);

  @override
  Future<Organization> cancelOrganizationArchive(String organizationId) =>
      _archiveRpc('cancel_organization_archive', organizationId);

  Future<Organization> _archiveRpc(String name, String organizationId) =>
      run((c, _) async {
        final data = await c.rpc(name, params: {'p_org': organizationId});
        return Organization.fromJson(_row(data));
      });

  // ---- Notifications -------------------------------------------------------

  @override
  Future<List<AppNotification>> fetchNotifications({int limit = 100}) =>
      run((c, uid) async {
        final data = await c
            .from('notifications')
            .select()
            .eq('recipient_id', uid)
            .order('created_at', ascending: false)
            .limit(limit);
        return _rows(data).map(AppNotification.fromJson).toList();
      });

  @override
  Future<int> markNotificationsRead([List<String>? ids]) => run((c, _) async {
    final data = await c.rpc('mark_notifications_read', params: {'p_ids': ids});
    return (data as num).toInt();
  });

  // ---- Realtime ------------------------------------------------------------

  static const _realtimeTables = [
    'organization_members',
    'invitations',
    'notifications',
    'calendar_events',
    'event_assignments',
  ];

  @override
  Stream<BackendChange> changes() {
    final client = clientProvider();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const Stream.empty();

    late final StreamController<BackendChange> controller;
    supa.RealtimeChannel? channel;
    var wasDisconnected = false;

    BackendChangeType typeOf(supa.PostgresChangeEvent e) => switch (e) {
      supa.PostgresChangeEvent.insert => BackendChangeType.insert,
      supa.PostgresChangeEvent.update => BackendChangeType.update,
      _ => BackendChangeType.delete,
    };

    controller = StreamController<BackendChange>(
      onListen: () {
        var ch = client.channel('battuta-$userId');
        for (final table in _realtimeTables) {
          ch = ch.onPostgresChanges(
            event: supa.PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              if (controller.isClosed) return;
              controller.add(
                BackendChange(
                  table: table,
                  type: typeOf(payload.eventType),
                  record: payload.newRecord,
                  oldRecord: payload.oldRecord,
                ),
              );
            },
          );
        }
        channel = ch.subscribe((status, error) {
          if (controller.isClosed) return;
          switch (status) {
            case supa.RealtimeSubscribeStatus.subscribed:
              // After a drop, rows may have changed unseen: refresh everything.
              if (wasDisconnected) controller.add(const BackendChange.resync());
              wasDisconnected = false;
            case supa.RealtimeSubscribeStatus.channelError ||
                supa.RealtimeSubscribeStatus.closed ||
                supa.RealtimeSubscribeStatus.timedOut:
              wasDisconnected = true;
          }
        });
      },
      onCancel: () async {
        final ch = channel;
        if (ch != null) await client.removeChannel(ch);
      },
    );
    return controller.stream;
  }
}
