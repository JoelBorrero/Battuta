/// My profile: account details (editable name and username), my
/// organizations, sign out and deactivate.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/profile/presentation/widgets/deactivate_dialog.dart';
import 'package:battuta/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/my_organizations_section.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ProfileMenuAction { deactivate }

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(authControllerProvider.notifier);
    // Back to the app first: a signed-out Profile would redirect to sign-in.
    GoRouter.maybeOf(context)?.go(AppRoutes.initial);
    await controller.signOut();
  }

  Future<void> _edit(BuildContext context, UserProfile profile) async {
    final saved = await showEditProfileSheet(context, profile: profile);
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(myProfileProvider).value;

    if (user == null) {
      // Signed out (or deactivated) while open: the router sends the user
      // away; nothing to show meanwhile.
      return Scaffold(appBar: AppBar(title: Text(l10n.profileTitle)));
    }

    final name = profile?.displayName ?? user.displayName ?? user.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          PopupMenuButton<_ProfileMenuAction>(
            key: const ValueKey('profile_menu_btn'),
            tooltip: l10n.profileMoreTooltip,
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onSelected: (_) => confirmDeactivateAccount(
              context,
              ref,
              confirmWord: profile?.username ?? user.email,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const ValueKey('profile_deactivate_item'),
                value: _ProfileMenuAction.deactivate,
                child: Text(
                  l10n.accountDeactivateAction,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DecoratedBox(
                decoration: brand.cardDecoration(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(name: name, size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  key: const ValueKey('profile_name'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (profile != null)
                                  Text(
                                    '@${profile.username}',
                                    key: const ValueKey('profile_username'),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: brand.inkMuted),
                                  ),
                                Text(
                                  user.email,
                                  key: const ValueKey('profile_email'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: brand.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const ValueKey('profile_edit_btn'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(44, 48),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l10n.profileEditAction),
                          onPressed: profile == null
                              ? null
                              : () => _edit(context, profile),
                        ),
                      ),
                      if (profile == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileLoadingEditHint,
                          key: const ValueKey('profile_edit_hint'),
                          style: TextStyle(fontSize: 12, color: brand.inkMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const MyOrganizationsSection(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('profile_sign_out_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.signOut),
                onPressed: () => _signOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
