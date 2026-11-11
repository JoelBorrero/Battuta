/// Tells a signed-out person that an invite link is waiting for an account.
library;

import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingInviteNote extends ConsumerWidget {
  const PendingInviteNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pendingInviteTokenProvider) == null) {
      return const SizedBox.shrink();
    }
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        key: const ValueKey('pending_invite_note'),
        decoration: brand.cardDecoration(selected: true),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.mail_outline, color: brand.accentInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocalizations.of(context)!.joinPendingNote),
              ),
              TextButton(
                key: const ValueKey('pending_invite_dismiss_btn'),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                onPressed: () =>
                    ref.read(pendingInviteTokenProvider.notifier).clear(),
                child: Text(AppLocalizations.of(context)!.joinPendingDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
