/// Invitations addressed to me: a card with Accept / Decline, and the banner
/// that shows the first one on the Team page.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/notification.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A pending invitation with Accept / Decline. Accepting switches the active
/// organization to the one that invited me.
class InvitationCard extends ConsumerStatefulWidget {
  const InvitationCard({required this.invitation, super.key});

  final Invitation invitation;

  @override
  ConsumerState<InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<InvitationCard> {
  bool _busy = false;

  Future<void> _respond({required bool accept}) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final invitation = widget.invitation;
    // Read every handle before the first await: on Accept the card can leave
    // the tree before the response arrives, and `ref` is unusable after that.
    final repository = ref.read(organizationRepositoryProvider);
    final notifications =
        ref.read(notificationsProvider).value ?? const <AppNotification>[];
    final selection = ref.read(activeOrganizationSelectionProvider.notifier);
    setState(() => _busy = true);
    final result = await repository.respondToInvitation(
      invitation,
      accept: accept,
    );
    if (mounted) setState(() => _busy = false);
    await result.fold(
      (failure) async {
        messenger?.showSnackBar(
          SnackBar(content: Text(backendErrorMessage(l10n, failure))),
        );
      },
      (_) async {
        // The server leaves the invitation notification unread: mark it so
        // the inbox badge does not keep counting an answered invitation.
        final stale = [
          for (final n in notifications)
            if (!n.isRead &&
                n.type == NotificationType.invitation &&
                n.payload['invitation_id'] == invitation.id)
              n.id,
        ];
        if (stale.isNotEmpty) {
          await repository.markNotificationsRead(stale);
        }
        if (accept) {
          await selection.select(invitation.organizationId);
        }
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? l10n.invitationAcceptedSnack(
                      invitation.organizationName ??
                          l10n.invitationOrganizationFallback,
                    )
                  : l10n.invitationDeclinedSnack,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final invitation = widget.invitation;
    final name =
        invitation.organizationName ?? l10n.invitationOrganizationFallback;

    return DecoratedBox(
      key: ValueKey('invitation_card_${invitation.id}'),
      decoration: brand.cardDecoration(selected: true),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: brand.accentInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.invitationFrom(name),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: ValueKey('invitation_accept_${invitation.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: _busy ? null : () => _respond(accept: true),
                  child: Text(l10n.invitationAccept),
                ),
                OutlinedButton(
                  key: ValueKey('invitation_decline_${invitation.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: _busy ? null : () => _respond(accept: false),
                  child: Text(l10n.invitationDecline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The newest pending invitation on top of the Team page, with a link to the
/// inbox when there are more. Renders nothing without invitations.
class InvitationsBanner extends ConsumerWidget {
  const InvitationsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMyInvitationsProvider);
    if (pending.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      key: const ValueKey('invitations_banner'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvitationCard(invitation: pending.first),
          if (pending.length > 1)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('invitations_see_all_btn'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: () => context.push(AppRoutes.inbox),
                child: Text(l10n.invitationSeeAll(pending.length)),
              ),
            ),
        ],
      ),
    );
  }
}
