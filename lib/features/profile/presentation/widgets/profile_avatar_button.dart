/// The avatar shown in the top bar of every tab: opens my profile, or the
/// sign-in page when there is no account.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Up to two initials of [name] (first letters of its first two words), or
/// `?` when there is none.
String initialsOf(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
  return letters.isEmpty ? '?' : letters;
}

/// A round avatar with the initials of [name] (a person icon when [name] is
/// `null`) and an accent ring.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({this.name, this.size = 32, super.key});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final name = this.name;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: brand.accentWash,
        border: Border.all(color: brand.accent, width: size >= 48 ? 2 : 1.5),
      ),
      child: name == null
          ? Icon(Icons.person_outline, size: size * 0.6, color: brand.accentInk)
          : Text(
              initialsOf(name),
              maxLines: 1,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: brand.accentInk,
              ),
            ),
    );
  }
}

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

    return IconButton(
      key: const ValueKey('profile_avatar_btn'),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      tooltip: user == null
          ? (l10n?.accountSignInTile ?? 'Sign in')
          : (l10n?.profileAvatarTooltip ?? 'Profile'),
      icon: ProfileAvatar(name: name),
      onPressed: () =>
          context.push(user == null ? AppRoutes.signIn : AppRoutes.profile),
    );
  }
}
