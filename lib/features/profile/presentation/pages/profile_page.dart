/// My profile: photo, name, instruments, stats, my organizations, app
/// settings and sign out. Deactivating the account is in the app bar menu.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/core/services/profile_image_picker.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/profile/presentation/providers/profile_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/change_photo_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/deactivate_dialog.dart';
import 'package:battuta/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/my_organizations_section.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_banner.dart';
import 'package:battuta/features/profile/presentation/widgets/profile_stat_tile.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
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

  Future<void> _changePhoto(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(authControllerProvider.notifier);
    final result = await showChangePhotoSheet(
      context,
      shape: PhotoShape.circle,
      bucket: PhotoBucket.avatars,
      title: l10n.photoSheetPersonTitle,
      subtitle: l10n.photoSheetPersonSubtitle,
      currentPath: profile?.avatarPath,
      onSave: controller.setMyAvatar,
      onRemove: () => controller.setMyAvatar(null),
    );
    if (result == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == PhotoSheetResult.removed
              ? l10n.photoRemoved
              : l10n.photoUpdated,
        ),
      ),
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
    final instruments = ref.watch(myInstrumentsProvider);
    final organizationCount =
        ref.watch(myOrganizationsProvider).value?.length ?? 0;

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              // The banner is 132 px tall; the 120 px avatar hangs 60 px below
              // it, so the stack is as tall as both together.
              SizedBox(
                height: 192,
                child: Stack(
                  children: [
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 132,
                      child: ProfileBanner(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: brand.canvas,
                                  border: Border.all(
                                    color: brand.accent,
                                    width: 2,
                                  ),
                                ),
                                child: GestureDetector(
                                  key: const ValueKey('profile_photo'),
                                  onTap: () =>
                                      _changePhoto(context, ref, profile),
                                  child: PersonAvatar(
                                    name: name,
                                    avatarPath: profile?.avatarPath,
                                    size: 104,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 4,
                                child: _CameraButton(
                                  key: const ValueKey('profile_photo_btn'),
                                  tooltip: l10n.photoChangeTooltip,
                                  onPressed: () =>
                                      _changePhoto(context, ref, profile),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                key: const ValueKey('profile_name'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile == null
                    ? user.email
                    : '@${profile.username} · ${user.email}',
                key: const ValueKey('profile_handle'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: brand.inkMuted),
              ),
              if (instruments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  key: const ValueKey('profile_instruments'),
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final instrument in instruments)
                      _InstrumentChip(
                        TeamRole.fromInstrument(instrument)
                                ?.localizedName(context) ??
                            instrument,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile_edit_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: brand.inkMuted),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatTile(
                      key: const ValueKey('profile_stat_organizations'),
                      value: '$organizationCount',
                      label: l10n.profileStatOrganizations,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ProfileStatTile(
                      key: const ValueKey('profile_stat_versions'),
                      value: '${ref.watch(myVersionCountProvider)}',
                      label: l10n.profileStatVersions,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ProfileStatTile(
                      key: const ValueKey('profile_stat_upcoming'),
                      value: '${ref.watch(myUpcomingCountProvider)}',
                      label: l10n.profileStatUpcoming,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const MyOrganizationsSection(),
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: brand.cardDecoration(),
                child: Column(
                  children: [
                    _LinkRow(
                      key: const ValueKey('profile_app_settings_row'),
                      icon: Icons.settings_outlined,
                      label: l10n.profileAppSettings,
                      showChevron: true,
                      onTap: () => context.go(AppRoutes.settings),
                    ),
                    Divider(height: 1, thickness: 1, color: brand.border),
                    _LinkRow(
                      key: const ValueKey('profile_sign_out_btn'),
                      icon: Icons.logout,
                      label: l10n.signOut,
                      onTap: () => _signOut(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.profileDeactivateHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: brand.inkDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brand.accent,
              border: Border.all(color: brand.canvas, width: 3),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 20,
              color: brand.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 16)),
              ),
              if (showChevron)
                Icon(Icons.chevron_right, size: 20, color: brand.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
