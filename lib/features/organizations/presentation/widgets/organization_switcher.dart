/// Organization and band switcher plus the create-organization dialog.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/paste_invite_dialog.dart';
import 'package:battuta/features/profile/presentation/widgets/organization_logo.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// App bar title: the active organization (tap to switch).
class OrganizationSwitcherButton extends ConsumerWidget {
  const OrganizationSwitcherButton({this.fallbackTitle, super.key});

  /// Shown when there is no active organization.
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(activeOrganizationProvider);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final title = organization?.name ?? fallbackTitle ?? l10n.worshipTeamTitle;

    if (!signedIn) {
      return Text(title, overflow: TextOverflow.ellipsis);
    }
    return InkWell(
      key: const ValueKey('org_switcher_btn'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => showOrganizationSwitcher(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

Future<void> showOrganizationSwitcher(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SwitcherSheet(),
    );

class _SwitcherSheet extends ConsumerWidget {
  const _SwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final organizations = ref.watch(myOrganizationsProvider).value ?? const [];
    final active = ref.watch(activeOrganizationProvider);
    final bands = ref.watch(activeBandsProvider).value ?? const [];
    final activeBandId = ref.watch(activeBandIdProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.organizationsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (organizations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noOrganizationsYet),
              ),
            for (final organization in organizations)
              ListTile(
                key: ValueKey('org_item_${organization.id}'),
                minVerticalPadding: 8,
                contentPadding: EdgeInsets.zero,
                selected: organization.id == active?.id,
                selectedColor: BattutaBrand.of(context).ink,
                leading: OrganizationLogo(
                  logoPath: organization.logoPath,
                  size: 40,
                  ring: organization.id == active?.id,
                ),
                title: Text(
                  organization.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _RoleBadge(admin: organization.isAdmin),
                onTap: () {
                  ref
                      .read(activeOrganizationSelectionProvider.notifier)
                      .select(organization.id);
                },
              ),
            if (active != null) ...[
              const Divider(),
              Text(
                l10n.bandsLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const ValueKey('switcher_all_bands'),
                    label: Text(l10n.allBandsLabel),
                    selected: activeBandId == null,
                    onSelected: (_) =>
                        ref.read(activeBandIdProvider.notifier).select(null),
                  ),
                  for (final band in bands)
                    ChoiceChip(
                      key: ValueKey('switcher_band_${band.id}'),
                      avatar: CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(band.colorValue),
                      ),
                      label: Text(band.name),
                      selected: activeBandId == band.id,
                      onSelected: (_) => ref
                          .read(activeBandIdProvider.notifier)
                          .select(band.id),
                    ),
                ],
              ),
            ],
            if (active != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('switcher_settings_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                icon: const Icon(Icons.tune),
                label: Text(l10n.orgSettingsTooltip),
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(AppRoutes.organizationSettings(active.id));
                },
              ),
            ],
            const Divider(),
            OutlinedButton.icon(
              key: const ValueKey('create_org_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              icon: const Icon(Icons.add),
              label: Text(l10n.createOrganizationAction),
              onPressed: () async {
                Navigator.of(context).pop();
                await showCreateOrganizationDialog(context);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('switcher_join_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              icon: const Icon(Icons.link),
              label: Text(l10n.joinWithLinkAction),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final token = await showPasteInviteDialog(context);
                if (token == null || !context.mounted) return;
                navigator.pop();
                GoRouter.of(context).go(AppRoutes.join(token));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.admin});

  final bool admin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: admin ? brand.accentWash : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: admin ? brand.accent : brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          admin ? l10n.adminRole : l10n.memberRoleLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: admin ? brand.accentInk : brand.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Asks for a name and creates the organization; the new one becomes active.
Future<void> showCreateOrganizationDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _CreateOrganizationDialog(),
    );

class _CreateOrganizationDialog extends ConsumerStatefulWidget {
  const _CreateOrganizationDialog();

  @override
  ConsumerState<_CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState
    extends ConsumerState<_CreateOrganizationDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.backendErrorInvalidName);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(organizationRepositoryProvider)
        .createOrganization(name);
    if (!mounted) return;
    await result.fold(
      (failure) async => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (Organization created) async {
        await ref
            .read(activeOrganizationSelectionProvider.notifier)
            .select(created.id);
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.createOrganizationAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('org_name_field'),
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saving ? null : _create(),
              decoration: InputDecoration(
                labelText: l10n.organizationNameLabel,
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('org_create_confirm_btn'),
          onPressed: _saving ? null : _create,
          child: Text(l10n.createOrganizationAction),
        ),
      ],
    );
  }
}

/// Asks for an invite link or code and opens its join page (signed-in users).
Future<void> joinWithPastedInvite(BuildContext context) async {
  final token = await showPasteInviteDialog(context);
  if (token == null || !context.mounted) return;
  GoRouter.of(context).go(AppRoutes.join(token));
}
