/// The Roster tab: members and bands of the active organization.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/organization_switcher.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:battuta/features/team/domain/entities/team_group.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/team_provider.dart';
import 'package:battuta/features/team/presentation/widgets/bands_sheet.dart';
import 'package:battuta/features/team/presentation/widgets/member_edit_dialog.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Band;
import 'package:go_router/go_router.dart';

enum _RosterFilter { all, vocals, band }

class RosterView extends ConsumerStatefulWidget {
  const RosterView({super.key});

  @override
  ConsumerState<RosterView> createState() => _RosterViewState();
}

class _RosterViewState extends ConsumerState<RosterView> {
  _RosterFilter _filter = _RosterFilter.all;

  String _filterLabel(_RosterFilter filter, AppLocalizations l10n) =>
      switch (filter) {
        _RosterFilter.all => l10n.filterAll,
        _RosterFilter.vocals => l10n.filterVocals,
        _RosterFilter.band => l10n.filterBand,
      };

  Future<void> _remove(TeamMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.removeMemberConfirm(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm_remove_member_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(rosterActionsProvider).removeMember(member);
    _report(result, l10n.removedMemberSuccess(member.name));
  }

  void _report(Either<Failure, Unit> result, String? success) {
    final l10n = AppLocalizations.of(context)!;
    final message = result.fold(
      (failure) => backendErrorMessage(l10n, failure),
      (_) => success,
    );
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final signedIn = ref.watch(currentAccountIdProvider) != null;
    final organization = ref.watch(activeOrganizationProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    final members = ref.watch(teamMembersProvider);
    final groups = ref.watch(teamGroupsProvider);
    final activeBandId = ref.watch(activeBandIdProvider);

    if (!signedIn) {
      return StageEmptyState(
        icon: Icons.groups_outlined,
        title: l10n.rosterSignInTitle,
        message: l10n.rosterSignInMessage,
        actions: [
          FilledButton(
            key: const ValueKey('roster_sign_in_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: () => context.push(AppRoutes.signIn),
            child: Text(l10n.welcomeSignIn),
          ),
        ],
      );
    }

    if (organization == null) {
      return StageEmptyState(
        icon: Icons.groups_outlined,
        title: l10n.noOrganizationsYet,
        message: l10n.noOrganizationInvitesNote,
        actions: [
          FilledButton.icon(
            key: const ValueKey('empty_create_org_btn'),
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            icon: const Icon(Icons.add),
            label: Text(l10n.createOrganizationAction),
            onPressed: () => showCreateOrganizationDialog(context),
          ),
          OutlinedButton.icon(
            key: const ValueKey('empty_join_org_btn'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
            icon: const Icon(Icons.link),
            label: Text(l10n.joinWithLinkAction),
            onPressed: () => joinWithPastedInvite(context),
          ),
        ],
      );
    }

    final visible = members.where((m) {
      return switch (_filter) {
        _RosterFilter.all => true,
        _RosterFilter.vocals =>
          m.hasVocalRole || m.vocalRange != VocalTessitura.none,
        _RosterFilter.band => m.hasInstrumentRole,
      };
    }).toList();

    final groupMap = {for (final g in groups) g.id: g};
    final activeGroup = groupMap[activeBandId];
    final groupTitle =
        '${activeGroup?.name ?? l10n.rosterEveryone} · ${visible.length}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final filter in _RosterFilter.values)
              StageFilterPill(
                key: ValueKey('filter_chip_${filter.name}'),
                label: _filterLabel(filter, l10n),
                selected: _filter == filter,
                onTap: () => setState(() => _filter = filter),
              ),
            for (final group in groups)
              StageFilterPill(
                key: ValueKey('filter_chip_group_${group.id}'),
                label: group.name,
                dot: Color(group.colorValue),
                selected: activeBandId == group.id,
                onTap: () => ref
                    .read(activeBandIdProvider.notifier)
                    .select(activeBandId == group.id ? null : group.id),
              ),
          ],
        ),
        StageSectionHeader(
          title: groupTitle,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
          trailing: isAdmin
              ? IconButton(
                  key: const ValueKey('manage_bands_btn'),
                  constraints: const BoxConstraints(
                    minWidth: BattutaSpace.minTouchTarget,
                    minHeight: BattutaSpace.minTouchTarget,
                  ),
                  color: brand.accentInk,
                  icon: const Icon(Icons.layers_outlined, size: 20),
                  tooltip: l10n.manageBandsAction,
                  onPressed: () => showBandsSheet(context),
                )
              : null,
        ),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                activeBandId == null
                    ? l10n.noMembersInRoster
                    : l10n.noMembersMatchFilter,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text(l10n.noMembersMatchFilter)),
          )
        else
          StageGroup(
            margin: EdgeInsets.zero,
            children: [
              for (final member in visible)
                _MemberRow(
                  member: member,
                  groupMap: groupMap,
                  canEdit: isAdmin || member.isMe,
                  canRemove: isAdmin && !member.isMe,
                  onEdit: () => MemberEditDialog.show(
                    context,
                    member: member,
                    groups: groups,
                    isAdmin: isAdmin,
                  ),
                  onRemove: () => _remove(member),
                ),
            ],
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.groupMap,
    required this.canEdit,
    required this.canRemove,
    required this.onEdit,
    required this.onRemove,
  });

  final TeamMember member;
  final Map<String, TeamGroup> groupMap;
  final bool canEdit;
  final bool canRemove;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final hasMenu = canEdit || canRemove;

    final instruments = [
      for (final role in member.roles) role.localizedShortName(context),
      if (member.vocalRange != VocalTessitura.none)
        member.vocalRange.rangeLabel,
    ].join(', ');
    final bands = [
      for (final id in member.groupIds)
        if (groupMap[id] case final group?) group.name,
    ].join(', ');
    final notes = member.notes;

    Widget muted(String text, {Key? key, int maxLines = 1}) => Text(
      text,
      key: key,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, color: brand.inkMuted),
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          children: [
            PersonAvatar(
              name: member.name,
              avatarPath: member.avatarPath,
              size: 40,
              ring: member.isMe,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: brand.ink,
                          ),
                        ),
                      ),
                      if (member.isMe) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${l10n.youBadge})',
                          key: ValueKey('you_badge_${member.id}'),
                          style: TextStyle(fontSize: 13, color: brand.inkMuted),
                        ),
                      ],
                      if (member.isAdmin) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          key: ValueKey('admin_badge_${member.id}'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: brand.accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            child: Text(
                              l10n.adminRole.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: brand.accentInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (instruments.isNotEmpty) muted(instruments),
                  if (bands.isNotEmpty)
                    muted(bands, key: ValueKey('member_bands_${member.id}')),
                  if (notes != null && notes.isNotEmpty)
                    muted(notes, maxLines: 2),
                ],
              ),
            ),
            if (hasMenu)
              PopupMenuButton<String>(
                key: ValueKey('member_menu_${member.id}'),
                constraints: const BoxConstraints(minWidth: 44),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 20, color: brand.inkMuted),
                tooltip: l10n.memberOptionsTooltip,
                onSelected: (value) => switch (value) {
                  'edit' => onEdit(),
                  'remove' => onRemove(),
                  _ => null,
                },
                itemBuilder: (_) => [
                  if (canEdit)
                    PopupMenuItem(value: 'edit', child: Text(l10n.editMember)),
                  if (canRemove)
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(
                        l10n.removeMember,
                        style: TextStyle(color: brand.danger),
                      ),
                    ),
                ],
              )
            else
              const SizedBox(width: 10),
          ],
        ),
      ),
    );

    return KeyedSubtree(
      key: ValueKey('member_card_${member.id}'),
      child: canEdit
          ? BattutaPressable(
              onTap: onEdit,
              pressedScale: 0.995,
              semanticLabel: member.name,
              child: content,
            )
          : content,
    );
  }
}
