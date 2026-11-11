/// The inbox icon with its unread badge, shown in the app bar of every tab.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Hidden in local mode (the inbox needs an account).
class InboxButton extends ConsumerWidget {
  const InboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentAccountIdProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(inboxBadgeCountProvider);

    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppTheme.stageRed,
      offset: const Offset(-4, 4),
      child: IconButton(
        key: const ValueKey('inbox_btn'),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(count > 0 ? Icons.inbox : Icons.inbox_outlined),
        tooltip: count > 0 ? l10n.inboxTooltipUnread(count) : l10n.inboxTooltip,
        onPressed: () => context.push(AppRoutes.inbox),
      ),
    );
  }
}
