/// The inbox: invitations addressed to me, then the notifications created by
/// the backend, newest first. Works offline from the cache.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/presentation/notifications/notification_presenter.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/invitation_card.dart';
import 'package:battuta/features/team/presentation/providers/calendar_providers.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(organizationRepositoryProvider)
        .markNotificationsRead();
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text(backendErrorMessage(l10n, failure))),
      ),
      (_) {},
    );
  }

  Future<void> _open(AppNotification notification) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final scrollDuration = BattutaMotion.resolve(context, BattutaMotion.bar);
    final repository = ref.read(organizationRepositoryProvider);

    if (!notification.isRead) {
      // Not awaited: offline the write can take seconds to fail, and the
      // notification simply stays unread.
      unawaited(repository.markNotificationsRead([notification.id]));
    }

    final target = notificationTarget(notification);
    final orgId =
        notification.organizationId ??
        notification.payload['organization_id'] as String?;
    if (destinationNeedsOrganization(target.destination) && orgId != null) {
      final mine = ref.read(myOrganizationsProvider).value ?? const [];
      if (!mine.any((o) => o.id == orgId)) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.inboxOrganizationGone)),
        );
        return;
      }
      await ref.read(activeOrganizationSelectionProvider.notifier).select(orgId);
    }

    switch (target.destination) {
      case NotificationDestination.invitations:
        if (_scroll.hasClients) {
          await _scroll.animateTo(
            0,
            duration: scrollDuration,
            curve: BattutaMotion.downbeat,
          );
        }
      case NotificationDestination.roster:
        ref.read(teamTabRequestProvider.notifier).request(TeamTab.roster);
        router.go(AppRoutes.team);
      case NotificationDestination.organization:
        // Archive notifications: the organization's settings, where the
        // request is answered.
        if (orgId != null) {
          await router.push(AppRoutes.organizationSettings(orgId));
        }
      case NotificationDestination.calendar:
        ref.read(teamTabRequestProvider.notifier).request(TeamTab.calendar);
        router.go(AppRoutes.team);
      case NotificationDestination.song:
        router.go(AppRoutes.songDetail(target.versionId!));
      case NotificationDestination.songPage:
        await router.push(AppRoutes.songPage(target.songId!));
      case NotificationDestination.mergeRequest:
        await router.push(AppRoutes.mergeRequest(target.requestId!));
      case NotificationDestination.repertoire:
        router.go(AppRoutes.repertoire);
      case NotificationDestination.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final invitations = ref.watch(pendingMyInvitationsProvider);
    final notifications = [
      ...(ref.watch(notificationsProvider).value ?? const <AppNotification>[]),
    ]..sort(_newestFirst);
    final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
    final unread = notifications.where((n) => !n.isRead).length;
    final now = ref.watch(calendarClockProvider)();

    String? organizationName(String id) {
      for (final o in organizations) {
        if (o.id == id) return o.name;
      }
      return null;
    }

    Widget body;
    if (!signedIn) {
      body = StageEmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.inboxTitle,
        message: l10n.inboxSignInMessage,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: () => context.push(AppRoutes.signIn),
            child: Text(l10n.welcomeSignIn),
          ),
        ],
      );
    } else if (invitations.isEmpty && notifications.isEmpty) {
      body = StageEmptyState(
        key: const ValueKey('inbox_empty'),
        icon: Icons.inbox_outlined,
        title: l10n.inboxEmptyTitle,
        message: l10n.inboxEmptyMessage,
      );
    } else {
      final rows = <Widget Function(BuildContext)>[
        if (invitations.isNotEmpty) ...[
          (_) => _SectionTitle(l10n.inboxInvitationsTitle),
          for (final invitation in invitations)
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InvitationCard(invitation: invitation),
            ),
        ],
        if (notifications.isNotEmpty)
          (_) => _SectionTitle(l10n.inboxUpdatesTitle),
      ];
      body = ListView.builder(
        key: const ValueKey('inbox_list'),
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: rows.length + notifications.length,
        itemBuilder: (context, index) {
          if (index < rows.length) return rows[index](context);
          final notification = notifications[index - rows.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NotificationTile(
              notification: notification,
              sentence: notificationSentence(
                l10n,
                notification,
                organizationName: organizationName,
              ),
              time: relativeTime(l10n, notification.createdAt, now: now),
              onTap: () => _open(notification),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inboxTitle),
        actions: [
          if (unread > 0)
            Flexible(
              child: TextButton(
                key: const ValueKey('inbox_mark_all_read_btn'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: _markAllRead,
                child: Text(
                  l10n.inboxMarkAllRead,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }

  static int _newestFirst(AppNotification a, AppNotification b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.sentence,
    required this.time,
    required this.onTap,
  });

  final AppNotification notification;
  final String sentence;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final unread = !notification.isRead;

    return BattutaPressable(
      builder: (context, pressed) => DecoratedBox(
        key: ValueKey('notification_${notification.id}'),
        decoration: unread
            ? brand
                  .cardDecoration(pressed: pressed)
                  .copyWith(color: pressed ? brand.cardRaised : brand.accentWash)
            : brand.cardDecoration(pressed: pressed),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: SizedBox.square(
                    dimension: 8,
                    child: DecoratedBox(
                      key: unread
                          ? ValueKey('notification_unread_${notification.id}')
                          : null,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: unread ? brand.accent : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sentence,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: unread ? FontWeight.w600 : null,
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: brand.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
