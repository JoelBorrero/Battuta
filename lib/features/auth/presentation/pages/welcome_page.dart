/// First-launch screen: sign in, create an account or continue offline.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/app_entry_provider.dart';
import 'package:battuta/features/auth/presentation/widgets/pending_invite_note.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:battuta/features/organizations/presentation/widgets/paste_invite_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notice = ref.watch(accountNoticeProvider);
    const buttonSize = Size.fromHeight(48);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BattutaWordmark(height: 40)),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (notice == AccountNotice.deactivated) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.accountDeactivatedNotice,
                      key: const ValueKey('welcome_deactivated_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const PendingInviteNote(),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('welcome_sign_in_btn'),
                    style: FilledButton.styleFrom(minimumSize: buttonSize),
                    onPressed: () => context.push(AppRoutes.signIn),
                    child: Text(l10n.welcomeSignIn),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('welcome_create_account_btn'),
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    onPressed: () => context.push(AppRoutes.createAccount),
                    child: Text(l10n.welcomeCreateAccount),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const ValueKey('welcome_continue_offline_btn'),
                    style: TextButton.styleFrom(minimumSize: buttonSize),
                    onPressed: () async {
                      ref.read(accountNoticeProvider.notifier).clear();
                      ref.read(pendingInviteTokenProvider.notifier).clear();
                      await ref.read(offlineChoiceProvider.notifier).choose();
                    },
                    child: Text(l10n.welcomeContinueOffline),
                  ),
                  TextButton.icon(
                    key: const ValueKey('welcome_paste_invite_btn'),
                    style: TextButton.styleFrom(minimumSize: buttonSize),
                    icon: const Icon(Icons.link),
                    label: Text(l10n.joinWithLinkAction),
                    onPressed: () async {
                      final token = await showPasteInviteDialog(context);
                      if (token != null) {
                        ref.read(pendingInviteTokenProvider.notifier).set(token);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeOfflineNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
