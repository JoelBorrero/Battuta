/// Settings "Account" section: a row that opens my profile, or the sign-in
/// and create-account rows when signed out.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return ListTile(
      key: const ValueKey('supabase_account_tile'),
      leading: PersonAvatar(
        name: displayName,
        avatarPath: profile?.avatarPath,
        size: 40,
        ring: true,
      ),
      title: Text(displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        profile != null ? '@${profile.username}' : user.email,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.profile),
    );
  }
}
