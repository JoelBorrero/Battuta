/// "My organizations" on the Profile page: every organization I belong to
/// with my role and instruments, and a menu per row (edit my instruments,
/// organization settings, leave).
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/profile/presentation/providers/profile_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/instruments_editor_sheet.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _OrganizationAction { instruments, settings, leave }

class MyOrganizationsSection extends ConsumerWidget {
  const MyOrganizationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final organizations = ref.watch(myOrganizationsProvider);
    final active = ref.watch(activeOrganizationProvider);
    final list = organizations.value ?? const <Organization>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.profileMyOrganizations,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: brand.inkMuted,
            ),
          ),
        ),
        if (list.isEmpty && !organizations.isLoading)
          DecoratedBox(
            key: const ValueKey('profile_no_organizations'),
            decoration: brand.cardDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noOrganizationsYet,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.noOrganizationInvitesNote,
                    style: TextStyle(color: brand.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('profile_join_org_btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                    icon: const Icon(Icons.link),
                    label: Text(l10n.joinWithLinkAction),
                    onPressed: () => joinWithPastedInvite(context),
                  ),
                ],
              ),
            ),
          ),
        for (final organization in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrganizationCard(
              organization: organization,
              isActive: organization.id == active?.id,
            ),
          ),
      ],
    );
  }
}

class _OrganizationCard extends ConsumerWidget {
  const _OrganizationCard({required this.organization, required this.isActive});

  final Organization organization;
  final bool isActive;

  /// Whether the organization is still one of mine (it can vanish while a
  /// menu or dialog is open: archived, or I was removed).
  bool _stillMine(WidgetRef ref) =>
      (ref.read(myOrganizationsProvider).value ?? const <Organization>[]).any(
        (o) => o.id == organization.id,
      );

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _OrganizationAction action,
    OrganizationMember? membership,
  ) async {
    if (!_stillMine(ref)) return;
    switch (action) {
      case _OrganizationAction.instruments:
        if (membership == null) return;
        final saved = await showInstrumentsEditorSheet(
          context,
          member: membership,
          organizationName: organization.name,
        );
        if (saved != true || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profileInstrumentsSaved,
            ),
          ),
        );
      case _OrganizationAction.settings:
        await context.push(AppRoutes.organizationSettings(organization.id));
      case _OrganizationAction.leave:
        await _leave(context, ref);
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveOrganizationAction),
        content: Text(l10n.leaveOrganizationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_leave_org_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.leaveOrganizationAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted || !_stillMine(ref)) return;
    final result = await ref
        .read(profileActionsProvider)
        .leave(organization.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(backendErrorMessage(l10n, failure))),
      ),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final membership = ref.watch(myMembershipProvider(organization.id)).value;
    final instruments = membership?.instruments ?? const <String>[];

    return Container(
      key: ValueKey('profile_org_${organization.id}'),
      decoration: brand.cardDecoration(selected: isActive),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref
              .read(activeOrganizationSelectionProvider.notifier)
              .select(organization.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Tag(
                              organization.isAdmin
                                  ? l10n.adminRole
                                  : l10n.memberRoleLabel,
                              color: organization.isAdmin
                                  ? brand.accentInk
                                  : brand.inkMuted,
                              highlighted: organization.isAdmin,
                            ),
                            if (isActive)
                              _Tag(
                                l10n.profileActiveOrganizationBadge,
                                key: ValueKey(
                                  'profile_org_active_${organization.id}',
                                ),
                                color: brand.accentInk,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (instruments.isEmpty)
                          Text(
                            l10n.profileNoInstruments,
                            style: TextStyle(
                              fontSize: 12,
                              color: brand.inkMuted,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final instrument in instruments)
                                _Tag(
                                  TeamRole.fromInstrument(instrument)
                                          ?.localizedShortName(context) ??
                                      instrument,
                                  color: brand.inkMuted,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<_OrganizationAction>(
                  key: ValueKey('profile_org_menu_${organization.id}'),
                  tooltip: l10n.profileOrganizationOptionsTooltip,
                  icon: const Icon(Icons.more_vert, size: 20),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                    maxWidth: 280,
                  ),
                  onSelected: (action) =>
                      _onAction(context, ref, action, membership),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _OrganizationAction.instruments,
                      enabled: membership != null,
                      child: Text(l10n.profileEditInstruments),
                    ),
                    if (organization.isAdmin)
                      PopupMenuItem(
                        value: _OrganizationAction.settings,
                        child: Text(l10n.profileOrganizationOpenSettings),
                      ),
                    PopupMenuItem(
                      value: _OrganizationAction.leave,
                      enabled: !organization.isAdmin,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.leaveOrganizationAction,
                            style: organization.isAdmin
                                ? null
                                : TextStyle(color: theme.colorScheme.error),
                          ),
                          if (organization.isAdmin)
                            Text(
                              l10n.profileLeaveAdminHint,
                              key: ValueKey(
                                'profile_leave_hint_${organization.id}',
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
    this.text, {
    required this.color,
    this.highlighted = false,
    super.key,
  });

  final String text;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? brand.accentWash : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted ? brand.accent : color.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
