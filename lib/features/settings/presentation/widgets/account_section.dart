/// Settings "Account" section: profile, sign out, deactivate, or sign in.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/account_notice_provider.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The signed-in account's public profile (`null` offline or signed out).
final myProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  if (ref.watch(currentUserProvider.select((u) => u?.id)) == null) return null;
  try {
    return await ref.watch(authRepositoryProvider).fetchMyProfile();
  } catch (_) {
    return null;
  }
});

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Column(
        children: [
          ListTile(
            key: const ValueKey('supabase_account_tile'),
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.accountSignInTile),
            subtitle: Text(l10n.notSignedInOffline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.signIn),
          ),
          ListTile(
            key: const ValueKey('account_create_tile'),
            leading: const Icon(Icons.person_add_alt_outlined),
            title: Text(l10n.welcomeCreateAccount),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.createAccount),
          ),
        ],
      );
    }

    final profile = ref.watch(myProfileProvider).value;
    final displayName = profile?.displayName ?? user.displayName ?? user.email;

    return Column(
      children: [
        ListTile(
          key: const ValueKey('supabase_account_tile'),
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(displayName, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (profile != null) '@${profile.username}',
              user.email,
            ].join(' · '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('account_sign_out_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.signOut),
              ),
              TextButton(
                key: const ValueKey('account_deactivate_btn'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmDeactivate(
                  context,
                  ref,
                  confirmWord: profile?.username ?? user.email,
                ),
                child: Text(l10n.accountDeactivateAction),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref, {
    required String confirmWord,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeactivateDialog(confirmWord: confirmWord),
    );
    if (confirmed != true || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(authRepositoryProvider).deactivateAccount();
      ref.read(accountNoticeProvider.notifier).show(AccountNotice.deactivated);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(backendErrorMessage(l10n, error))));
    }
  }
}

class _DeactivateDialog extends StatefulWidget {
  const _DeactivateDialog({required this.confirmWord});

  final String confirmWord;

  @override
  State<_DeactivateDialog> createState() => _DeactivateDialogState();
}

class _DeactivateDialogState extends State<_DeactivateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _controller.text.trim() == widget.confirmWord;
    return AlertDialog(
      title: Text(l10n.accountDeactivateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.accountDeactivateExplanation),
            const SizedBox(height: 12),
            Text(l10n.accountDeactivateTypeToConfirm(widget.confirmWord)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('deactivate_confirm_field'),
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('deactivate_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.accountDeactivateAction),
        ),
      ],
    );
  }
}
