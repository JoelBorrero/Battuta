/// "My organizations" on the Profile page: every organization I belong to
/// with my role and instruments. Tapping a card opens the organization
/// profile; a menu per card switches to it, edits my instruments, opens its
/// settings or leaves it.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/profile/presentation/providers/profile_providers.dart';
import 'package:battuta/features/profile/presentation/widgets/instruments_editor_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/organization_logo.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _OrganizationAction { switchTo, instruments, settings, leave }

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
        // The heading and the link share a line when they fit, and stack
        // when the window is narrow or the translation is long.
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Text(
                  l10n.profileMyOrganizations,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (list.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: TextButton(
                    key: const ValueKey('profile_join_link_btn'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: brand.accentInk,
                    ),
                    onPressed: () => joinWithPastedInvite(context),
                    child: Text(
                      l10n.joinWithLinkAction,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
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
            padding: const EdgeInsets.only(bottom: 8),
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
      case _OrganizationAction.switchTo:
        await ref
            .read(activeOrganizationSelectionProvider.notifier)
            .select(organization.id);
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
    final instrumentsText = instruments.isEmpty
        ? l10n.profileNoInstruments
        : instruments
              .map(
                (i) => TeamRole.fromInstrument(i)?.localizedName(context) ?? i,
              )
              .join(' · ');

    return Semantics(
      selected: isActive,
      child: Container(
        key: ValueKey('profile_org_${organization.id}'),
        decoration: brand.cardDecoration(selected: isActive),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(AppRoutes.organization(organization.id)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    OrganizationLogo(logoPath: organization.logoPath),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  organization.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _Tag(
                                organization.isAdmin
                                    ? l10n.adminRole.toUpperCase()
                                    : l10n.memberRoleLabel.toUpperCase(),
                                color: organization.isAdmin
                                    ? brand.accentInk
                                    : brand.inkMuted,
                                highlighted: organization.isAdmin,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            instrumentsText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: brand.inkMuted,
                            ),
                          ),
                        ],
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
                          value: _OrganizationAction.switchTo,
                          enabled: !isActive,
                          child: Text(l10n.profileSwitchToOrganization),
                        ),
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
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.color, this.highlighted = false});

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
