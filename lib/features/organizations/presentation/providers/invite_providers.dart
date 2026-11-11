/// Streams for invite links, invitations and the notifications inbox.
library;

import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invite links of [organizationId] (admins only; the backend hides them
/// from members).
final inviteLinksProvider =
    StreamProvider.family<List<InviteLink>, String>(
      (ref, organizationId) => ref
          .watch(organizationRepositoryProvider)
          .watchInviteLinks(organizationId),
    );

/// Invitations sent by username for [organizationId].
final organizationInvitationsProvider =
    StreamProvider.family<List<Invitation>, String>(
      (ref, organizationId) => ref
          .watch(organizationRepositoryProvider)
          .watchInvitations(organizationId),
    );

/// Invitations addressed to the signed-in user (any status).
final myInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  if (ref.watch(currentAccountIdProvider) == null) {
    return Stream.value(const <Invitation>[]);
  }
  return ref.watch(organizationRepositoryProvider).watchMyInvitations();
});

/// Invitations I can still accept or decline, newest first.
final pendingMyInvitationsProvider = Provider<List<Invitation>>((ref) {
  final all = ref.watch(myInvitationsProvider).value ?? const [];
  return [
    for (final invitation in all)
      if (invitation.isPending) invitation,
  ];
});

/// My notifications, newest first (cache first, works offline).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  if (ref.watch(currentAccountIdProvider) == null) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref.watch(organizationRepositoryProvider).watchNotifications();
});

/// What the inbox button's badge counts: unread notifications plus pending
/// invitations that no unread notification already stands for. An unread
/// invitation notification whose invitation was answered no longer counts.
final inboxBadgeCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  final all = ref.watch(myInvitationsProvider).value ?? const [];
  final pending = ref.watch(pendingMyInvitationsProvider);
  final answered = {
    for (final i in all)
      if (!i.isPending) i.id,
  };
  final unread = [
    for (final n in notifications)
      if (!n.isRead &&
          !(n.type == NotificationType.invitation &&
              answered.contains(n.payload['invitation_id'])))
        n,
  ];
  final announced = {
    for (final n in unread)
      if (n.type == NotificationType.invitation)
        n.payload['invitation_id'] as Object?,
  };
  final unannounced = pending.where((i) => !announced.contains(i.id)).length;
  return unread.length + unannounced;
});
