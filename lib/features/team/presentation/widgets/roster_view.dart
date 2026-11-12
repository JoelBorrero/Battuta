/// The Roster tab: members and bands of the active organization.
library;

import 'package:battuta/app/design_system/components/stage_empty_state.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/invite_sheet.dart';
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
    final theme = Theme.of(context);
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        DecoratedBox(
          decoration: brand.cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    count: '${members.length}',
                    label: l10n.totalRoster,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    count: '${members.where((m) => m.isAdmin).length}',
                    label: l10n.adminsLabel,
                    color: brand.accentInk,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    count: '${groups.length}',
                    label: l10n.bandsLabel,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (isAdmin)
              OutlinedButton.icon(
                key: const ValueKey('invite_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                label: Text(l10n.inviteAction),
                onPressed: () => showInviteSheet(context),
              ),
            if (isAdmin)
              OutlinedButton.icon(
                key: const ValueKey('manage_bands_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.layers_outlined, size: 18),
                label: Text(l10n.manageBandsAction),
                onPressed: () => showBandsSheet(context),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _RosterFilter.values)
              FilterChip(
                key: ValueKey('filter_chip_${filter.name}'),
                label: Text(_filterLabel(filter, l10n)),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
            for (final group in groups)
              FilterChip(
                key: ValueKey('filter_chip_group_${group.id}'),
                avatar: CircleAvatar(
                  radius: 5,
                  backgroundColor: Color(group.colorValue),
                ),
                label: Text(group.name),
                selected: activeBandId == group.id,
                onSelected: (on) => ref
                    .read(activeBandIdProvider.notifier)
                    .select(on ? group.id : null),
              ),
          ],
        ),
        const SizedBox(height: 12),
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
          for (final member in visible)
            _MemberCard(
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
        const SizedBox(height: 64),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
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
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    Widget tag(String text, Color color, {Key? key}) => DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

    final hasMenu = canEdit || canRemove;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: brand.cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: ValueKey('member_card_${member.id}'),
          onTap: canEdit ? onEdit : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: PersonAvatar(
            name: member.name,
            avatarPath: member.avatarPath,
            size: 40,
            ring: member.isAdmin,
          ),
          title: Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (member.username != null)
                Text(
                  '@${member.username}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: brand.inkMuted, fontSize: 12),
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (member.isMe)
                    tag(
                      l10n.youBadge,
                      theme.colorScheme.primary,
                      key: ValueKey('you_badge_${member.id}'),
                    ),
                  if (member.isAdmin)
                    tag(
                      l10n.adminRole,
                      brand.accentInk,
                      key: ValueKey('admin_badge_${member.id}'),
                    ),
                  for (final role in member.roles)
                    tag(role.localizedName(context), brand.inkMuted),
                  if (member.vocalRange != VocalTessitura.none)
                    tag(member.vocalRange.rangeLabel, brand.accentInk),
                  for (final groupId in member.groupIds)
                    if (groupMap[groupId] case final group?)
                      tag(
                        group.name,
                        Color(group.colorValue),
                        key: ValueKey(
                          'member_group_badge_${member.id}_$groupId',
                        ),
                      ),
                ],
              ),
              if (member.notes != null && member.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  member.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: brand.inkMuted),
                ),
              ],
            ],
          ),
          trailing: hasMenu
              ? PopupMenuButton<String>(
                  key: ValueKey('member_menu_${member.id}'),
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: l10n.memberOptionsTooltip,
                  onSelected: (value) => switch (value) {
                    'edit' => onEdit(),
                    'remove' => onRemove(),
                    _ => null,
                  },
                  itemBuilder: (_) => [
                    if (canEdit)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.editMember),
                      ),
                    if (canRemove)
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          l10n.removeMember,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.count,
    required this.label,
    required this.color,
  });

  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        count,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
    ],
  );
}
