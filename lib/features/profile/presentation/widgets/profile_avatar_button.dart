/// The avatar shown in the top bar of every tab: opens my profile, or the
/// sign-in page when there is no account.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab pages run without localizations in some widget tests.
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final profile = user == null ? null : ref.watch(myProfileProvider).value;
    final name = user == null
        ? null
        : (profile?.displayName ?? user.displayName ?? user.email);

    // The last action in the app bar: keep it off the screen edge.
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: IconButton(
        key: const ValueKey('profile_avatar_btn'),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        tooltip: user == null
            ? (l10n?.accountSignInTile ?? 'Sign in')
            : (l10n?.profileAvatarTooltip ?? 'Profile'),
        icon: PersonAvatar(
          name: name,
          avatarPath: profile?.avatarPath,
          ring: true,
        ),
        onPressed: () =>
            context.push(user == null ? AppRoutes.signIn : AppRoutes.profile),
      ),
    );
  }
}
