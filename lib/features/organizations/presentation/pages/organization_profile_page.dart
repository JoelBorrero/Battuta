/// The profile of one of my organizations: logo, description, stats, bands,
/// a members preview and the next service. Admins also get the logo camera,
/// Invite, Edit profile and Manage controls; the settings (role, quota,
/// leave, archive) stay one tap away behind the gear.
library;

import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/core/services/profile_image_picker.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_profile_providers.dart';
import 'package:battuta/features/organizations/presentation/widgets/edit_organization_profile_sheet.dart';
import 'package:battuta/features/organizations/presentation/widgets/invite_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/change_photo_sheet.dart';
import 'package:battuta/features/profile/presentation/widgets/organization_logo.dart';
import 'package:battuta/features/profile/presentation/widgets/person_avatar.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/team/domain/entities/service_event.dart';
import 'package:battuta/features/team/domain/entities/team_member.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:battuta/features/team/presentation/widgets/bands_sheet.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide Band;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrganizationProfilePage extends ConsumerWidget {
  const OrganizationProfilePage({required this.organizationId, super.key});

  final String organizationId;

  /// Makes this organization the active one, which the invite and bands
  /// sheets work on.
  Future<void> _activate(WidgetRef ref) => ref
      .read(activeOrganizationSelectionProvider.notifier)
      .select(organizationId);

  Future<void> _changeLogo(
    BuildContext context,
    WidgetRef ref,
    Organization organization,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(organizationRepositoryProvider);
    Future<Either<Failure, Unit>> save(jpeg) async =>
        (await repository.setOrganizationLogo(
          organization.id,
          jpeg,
        )).map((_) => unit);
    Future<Either<Failure, Unit>> remove() async =>
        (await repository.removeOrganizationLogo(organization.id))
            .map((_) => unit);

    final result = await showChangePhotoSheet(
      context,
      shape: PhotoShape.square,
      bucket: PhotoBucket.organizationLogos,
      title: l10n.photoSheetLogoTitle,
      subtitle: l10n.photoSheetLogoSubtitle,
      currentPath: organization.logoPath,
      onSave: save,
      onRemove: remove,
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

  Future<void> _edit(BuildContext context, Organization organization) async {
    final saved = await showEditOrganizationProfileSheet(
      context,
      organization: organization,
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.organizationProfileSaved),
      ),
    );
  }

  void _openTeam(BuildContext context, WidgetRef ref, TeamTab tab) {
    _activate(ref);
    ref.read(teamTabRequestProvider.notifier).request(tab);
    context.go(AppRoutes.team);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(organizationByIdProvider(organizationId));
    final organizations = ref.watch(myOrganizationsProvider);

    if (organization == null) {
      // Loading, or no longer mine (left, removed, archived).
      return Scaffold(
        appBar: AppBar(title: Text(l10n.organizationProfileTitle)),
        body: Center(
          child: organizations.hasValue
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.organizationNotFound,
                    key: const ValueKey('org_profile_not_found'),
                    textAlign: TextAlign.center,
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    final isAdmin = organization.isAdmin;
    final members = ref
        .watch(organizationMembersProvider(organizationId))
        .value;
    final bands = ref.watch(organizationBandsProvider(organizationId)).value;
    final songCount = ref
        .watch(organizationRepertoireProvider(organizationId))
        .value
        ?.length;
    final nextService = ref.watch(
      organizationNextServiceProvider(organizationId),
    );
    final activeMembers = [
      for (final m in members ?? const <OrganizationMember>[])
        if (m.isActive) m,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.organizationProfileTitle),
        actions: [
          IconButton(
            key: const ValueKey('org_profile_settings_btn'),
            tooltip: l10n.orgSettingsTooltip,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                context.push(AppRoutes.organizationSettings(organization.id)),
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
              _HeaderCard(
                organization: organization,
                memberCount: members == null ? null : activeMembers.length,
                bandCount: bands?.length,
                songCount: songCount,
                onChangeLogo: () => _changeLogo(context, ref, organization),
                onInvite: () async {
                  await _activate(ref);
                  if (context.mounted) await showInviteSheet(context);
                },
                onEdit: () => _edit(context, organization),
              ),
              _SectionHeader(
                title: l10n.bandsLabel,
                actionLabel: isAdmin ? l10n.organizationManageAction : null,
                actionKey: const ValueKey('org_profile_manage_bands'),
                onAction: () async {
                  await _activate(ref);
                  if (context.mounted) await showBandsSheet(context);
                },
              ),
              _BandChips(bands: bands ?? const []),
              _SectionHeader(
                title: l10n.organizationMembersHeading,
                actionLabel: l10n.organizationSeeAll(activeMembers.length),
                actionKey: const ValueKey('org_profile_see_all'),
                onAction: () => _openTeam(context, ref, TeamTab.roster),
              ),
              _MembersPreview(members: members ?? const []),
              Padding(
                padding: const EdgeInsets.only(top: 26, bottom: 10),
                child: Text(
                  l10n.organizationNextUp,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _NextUpCard(
                service: nextService,
                bands: bands ?? const [],
                onTap: () => _openTeam(context, ref, TeamTab.calendar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.organization,
    required this.memberCount,
    required this.bandCount,
    required this.songCount,
    required this.onChangeLogo,
    required this.onInvite,
    required this.onEdit,
  });

  final Organization organization;
  final int? memberCount;
  final int? bandCount;
  final int? songCount;
  final VoidCallback onChangeLogo;
  final VoidCallback onInvite;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final isAdmin = organization.isAdmin;
    final description = organization.description?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  children: [
                    OrganizationLogo(
                      key: const ValueKey('org_profile_logo'),
                      logoPath: organization.logoPath,
                      size: 96,
                      ring: true,
                    ),
                    if (isAdmin && !organization.isArchived)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Tooltip(
                          message: l10n.organizationLogoChangeTooltip,
                          child: Semantics(
                            button: true,
                            label: l10n.organizationLogoChangeTooltip,
                            child: GestureDetector(
                              key: const ValueKey('org_profile_logo_btn'),
                              behavior: HitTestBehavior.opaque,
                              onTap: onChangeLogo,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: brand.accent,
                                  border: Border.all(
                                    color: brand.card,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 18,
                                  color: brand.onAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization.name,
                      key: const ValueKey('org_profile_name'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 6),
                      Container(
                        key: const ValueKey('org_profile_admin_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: brand.accentWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.organizationYouAreAdmin,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: brand.accentInk,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              key: const ValueKey('org_profile_description'),
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: brand.inkMuted,
              ),
            ),
          ] else if (isAdmin) ...[
            const SizedBox(height: 16),
            Text(
              l10n.organizationAddDescription,
              key: const ValueKey('org_profile_description_hint'),
              style: TextStyle(fontSize: 15, height: 1.45, color: brand.inkDim),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InsetStat(
                  key: const ValueKey('org_profile_stat_members'),
                  value: memberCount,
                  label: l10n.organizationStatMembers,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsetStat(
                  key: const ValueKey('org_profile_stat_bands'),
                  value: bandCount,
                  label: l10n.bandsLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsetStat(
                  key: const ValueKey('org_profile_stat_songs'),
                  value: songCount,
                  label: l10n.organizationStatSongs,
                ),
              ),
            ],
          ),
          if (isAdmin && !organization.isArchived) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('org_profile_invite_btn'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                    label: Text(l10n.inviteAction),
                    onPressed: onInvite,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('org_profile_edit_btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.profileEditAction),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InsetStat extends StatelessWidget {
  const _InsetStat({required this.value, required this.label, super.key});

  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.cardRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null ? '–' : '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 13, color: brand.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionKey,
    required this.onAction,
    this.actionLabel,
  });

  final String title;
  final String? actionLabel;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              key: actionKey,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: brand.accentInk,
              ),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          else
            const SizedBox(height: 44),
        ],
      ),
    );
  }
}

class _BandChips extends StatelessWidget {
  const _BandChips({required this.bands});

  final List<Band> bands;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    if (bands.isEmpty) {
      return Text(
        l10n.organizationNoBands,
        key: const ValueKey('org_profile_no_bands'),
        style: TextStyle(color: brand.inkMuted),
      );
    }
    return Wrap(
      key: const ValueKey('org_profile_bands'),
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final band in bands)
          Container(
            height: 36,
            padding: const EdgeInsets.only(left: 10, right: 14),
            decoration: BoxDecoration(
              color: brand.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: brand.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(band.colorValue),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    band.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MembersPreview extends StatelessWidget {
  const _MembersPreview({required this.members});

  final List<OrganizationMember> members;

  static String _nameOf(OrganizationMember m) {
    final name = m.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return m.username ?? m.userId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);

    // Active admins, then the other active members, then deactivated ones.
    int rank(OrganizationMember m) => !m.isActive ? 2 : (m.isAdmin ? 0 : 1);
    final sorted = [...members]
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0
            ? byRank
            : _nameOf(a).toLowerCase().compareTo(_nameOf(b).toLowerCase());
      });
    final shown = sorted.take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('org_profile_members'),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: brand.border),
            _MemberRow(member: shown[i], name: _nameOf(shown[i]), l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.name,
    required this.l10n,
  });

  final OrganizationMember member;
  final String name;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final deactivated = !member.isActive;
    final detail = deactivated
        ? l10n.organizationMemberDeactivated
        : member.instruments.isNotEmpty
        ? member.instruments
              .map(
                (i) => TeamRole.fromInstrument(i)?.localizedName(context) ?? i,
              )
              .join(' · ')
        : (member.username == null ? '' : '@${member.username}');

    return ConstrainedBox(
      key: ValueKey('org_profile_member_${member.id}'),
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            PersonAvatar(
              name: name,
              avatarPath: member.avatarPath,
              size: 42,
              ring: member.isAdmin && !deactivated,
              deactivated: deactivated,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: deactivated ? brand.inkMuted : brand.ink,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: brand.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (member.isAdmin && !deactivated) ...[
              const SizedBox(width: 8),
              Text(
                l10n.adminRole,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brand.accentInk,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.service,
    required this.bands,
    required this.onTap,
  });

  final ServiceEvent? service;
  final List<Band> bands;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final service = this.service;

    final decoration = BoxDecoration(
      color: brand.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: brand.border),
    );

    if (service == null) {
      return Container(
        key: const ValueKey('org_profile_no_upcoming'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: Text(
          l10n.organizationNoUpcoming,
          style: TextStyle(color: brand.inkMuted),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    final date = service.dateTime;
    Band? band;
    for (final b in bands) {
      if (b.id == service.bandId) band = b;
    }
    final detail = [
      DateFormat.Hm(locale).format(date),
      ?band?.name,
      if (band == null && (service.location ?? '').isNotEmpty)
        service.location!,
    ].join(' · ');

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const ValueKey('org_profile_next_up'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 60,
                decoration: BoxDecoration(
                  color: brand.cardRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E(locale).format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: brand.accentInk,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: brand.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: brand.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
