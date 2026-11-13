/// Settings "Account" section: a row that opens my profile, or the sign-in
/// and create-account rows when signed out.
library;

import 'package:battuta/app/design_system/design_system.dart';
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
      final brand = BattutaBrand.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StageRow(
            key: const ValueKey('supabase_account_tile'),
            icon: Icons.person_outline,
            label: l10n.accountSignInTile,
            subtitle: l10n.notSignedInOffline,
            onTap: () => context.push(AppRoutes.signIn),
          ),
          Divider(height: 1, thickness: 1, color: brand.border),
          StageRow(
            key: const ValueKey('account_create_tile'),
            icon: Icons.person_add_alt_outlined,
            label: l10n.welcomeCreateAccount,
            onTap: () => context.push(AppRoutes.createAccount),
          ),
        ],
      );
    }

    final profile = ref.watch(myProfileProvider).value;
    final displayName = profile?.displayName ?? user.displayName ?? user.email;

    return StageRow(
      key: const ValueKey('supabase_account_tile'),
      leading: PersonAvatar(
        name: displayName,
        avatarPath: profile?.avatarPath,
        size: 32,
        ring: true,
      ),
      label: displayName,
      subtitle: profile != null ? '@${profile.username}' : user.email,
      onTap: () => context.push(AppRoutes.profile),
    );
  }
}
