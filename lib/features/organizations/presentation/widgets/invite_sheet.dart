/// Admin sheet to invite people: a shareable link with a QR code, or an
/// invitation by username.
library;

import 'dart:async';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/features/auth/domain/entities/user_profile.dart';
import 'package:battuta/features/organizations/domain/entities/invites.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_actions_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/invite_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> showInviteSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => const InviteSheet(),
);

class InviteSheet extends ConsumerWidget {
  const InviteSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(activeOrganizationProvider);
    final isAdmin = ref.watch(isCurrentUserAdminProvider);
    // Members never get the sheet; the backend refuses them anyway.
    if (organization == null || !isAdmin) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.inviteSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      key: const ValueKey('invite_tab_link'),
                      text: l10n.inviteTabLink,
                    ),
                    Tab(
                      key: const ValueKey('invite_tab_username'),
                      text: l10n.inviteTabUsername,
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LinkTab(organization: organization),
                      _UsernameTab(organization: organization),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Link & QR ──────────────────────────────────────────────────────────────

class _LinkTab extends ConsumerStatefulWidget {
  const _LinkTab({required this.organization});

  final Organization organization;

  @override
  ConsumerState<_LinkTab> createState() => _LinkTabState();
}

class _LinkTabState extends ConsumerState<_LinkTab> {
  static const _expiries = [
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
  ];

  Duration _expiry = const Duration(days: 7);
  final _maxUses = TextEditingController();
  String? _bandId;
  String? _selectedId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _maxUses.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    int? maxUses;
    final raw = _maxUses.text.trim();
    if (raw.isNotEmpty) {
      maxUses = int.tryParse(raw);
      if (maxUses == null || maxUses < 1) {
        setState(() => _error = l10n.inviteMaxUsesInvalid);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(organizationRepositoryProvider)
        .createInviteLink(
          widget.organization.id,
          bandId: _bandId,
          expiresIn: _expiry,
          maxUses: maxUses,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      result.fold(
        (failure) => _error = backendErrorMessage(l10n, failure),
        (link) => _selectedId = link.id,
      );
    });
  }

  Future<void> _revoke(InviteLink link) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('invite_revoke_confirm'),
        title: Text(l10n.inviteRevokeConfirmTitle),
        content: Text(l10n.inviteRevokeConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('invite_revoke_cancel_btn'),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('invite_revoke_confirm_btn'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.inviteRevokeAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(organizationRepositoryProvider)
        .revokeInviteLink(widget.organization.id, link.id);
    if (!mounted) return;
    setState(() {
      result.fold(
        (failure) => _error = backendErrorMessage(l10n, failure),
        (_) {
          _error = null;
          if (_selectedId == link.id) _selectedId = null;
        },
      );
    });
  }

  Future<void> _copy(InviteLink link) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: inviteLinkFor(link.token)));
    messenger.showSnackBar(SnackBar(content: Text(l10n.inviteLinkCopied)));
  }

  Future<void> _share(InviteLink link, BuildContext buttonContext) async {
    final l10n = AppLocalizations.of(context)!;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await ref.read(inviteSharerProvider)(
      l10n.inviteShareMessage(
        widget.organization.name,
        inviteLinkFor(link.token),
      ),
      origin: origin,
    );
  }

  String _expiryLabel(AppLocalizations l10n, Duration d) => switch (d.inDays) {
    1 => l10n.inviteExpiry1Day,
    7 => l10n.inviteExpiry7Days,
    _ => l10n.inviteExpiry30Days,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final bands = ref.watch(activeBandsProvider).value ?? const <Band>[];
    final links = ref.watch(inviteLinksProvider(widget.organization.id));
    final now = DateTime.now();
    final active = [
      for (final link in links.value ?? const <InviteLink>[])
        if (link.isUsable(now)) link,
    ];
    InviteLink? selected;
    for (final link in active) {
      if (link.id == _selectedId) selected = link;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.inviteExpiryLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _expiries)
              ChoiceChip(
                key: ValueKey('invite_expiry_${d.inDays}'),
                label: Text(_expiryLabel(l10n, d)),
                selected: _expiry == d,
                onSelected: (_) => setState(() => _expiry = d),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('invite_max_uses_field'),
          controller: _maxUses,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.inviteMaxUsesLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (bands.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BandDropdown(
            bands: bands,
            value: _bandId,
            onChanged: (id) => setState(() => _bandId = id),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const ValueKey('invite_error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('invite_create_link_btn'),
          style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
          icon: const Icon(Icons.add_link),
          label: Text(l10n.inviteCreateLink),
          onPressed: _busy ? null : _create,
        ),
        if (selected != null) ...[
          const SizedBox(height: 16),
          _LinkCard(
            link: selected,
            onCopy: () => _copy(selected!),
            onShare: (ctx) => _share(selected!, ctx),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.inviteActiveLinksTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Text(
            l10n.inviteNoActiveLinks,
            style: TextStyle(color: brand.inkMuted),
          ),
        for (final link in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              key: ValueKey('invite_link_row_${link.id}'),
              decoration: brand.cardDecoration(selected: link.id == _selectedId),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.inviteLinkExpires(
                              DateFormat.yMMMd(
                                l10n.localeName,
                              ).format(link.expiresAt.toLocal()),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            link.maxUses == null
                                ? l10n.inviteLinkUsesUnlimited(link.useCount)
                                : l10n.inviteLinkUsesLimited(
                                    link.useCount,
                                    link.maxUses!,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brand.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton(
                          key: ValueKey('invite_link_show_${link.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () =>
                              setState(() => _selectedId = link.id),
                          child: Text(l10n.inviteShowAction),
                        ),
                        TextButton(
                          key: ValueKey('invite_link_revoke_${link.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () => _revoke(link),
                          child: Text(l10n.inviteRevokeAction),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.onCopy,
    required this.onShare,
  });

  final InviteLink link;
  final VoidCallback onCopy;
  final void Function(BuildContext buttonContext) onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final url = inviteLinkFor(link.token);

    return DecoratedBox(
      key: const ValueKey('invite_link_card'),
      decoration: brand.cardDecoration(selected: true),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.inviteLinkLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(
              url,
              key: const ValueKey('invite_link_text'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('invite_copy_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.inviteCopy),
                  onPressed: onCopy,
                ),
                Builder(
                  builder: (buttonContext) => OutlinedButton.icon(
                    key: const ValueKey('invite_share_btn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(l10n.inviteShare),
                    onPressed: () => onShare(buttonContext),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              // A QR code always needs dark modules on a light ground.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.pureWhiteSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  key: const ValueKey('invite_qr'),
                  data: url,
                  size: 200,
                  padding: const EdgeInsets.all(12),
                  backgroundColor: AppTheme.pureWhiteSurface,
                  semanticsLabel: l10n.inviteQrSemantics,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.inviteQrHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: brand.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandDropdown extends StatelessWidget {
  const _BandDropdown({
    required this.bands,
    required this.value,
    required this.onChanged,
  });

  final List<Band> bands;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String?>(
      key: const ValueKey('invite_band_dropdown'),
      isExpanded: true,
      initialValue: bands.any((b) => b.id == value) ? value : null,
      decoration: InputDecoration(
        labelText: l10n.inviteBandLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(child: Text(l10n.inviteNoBand)),
        for (final band in bands)
          DropdownMenuItem<String?>(
            value: band.id,
            child: Text(band.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Username ───────────────────────────────────────────────────────────────

class _UsernameTab extends ConsumerStatefulWidget {
  const _UsernameTab({required this.organization});

  final Organization organization;

  @override
  ConsumerState<_UsernameTab> createState() => _UsernameTabState();
}

class _UsernameTabState extends ConsumerState<_UsernameTab> {
  static const _minQuery = 3;

  final _query = TextEditingController();
  Timer? _debounce;
  int _searchSeq = 0;
  List<UserProfile> _results = const [];
  bool _searched = false;
  bool _searching = false;
  String? _bandId;
  String? _error;
  final Set<String> _invitedNow = {};
  final Set<String> _busyIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final text = value.trim();
    if (text.length < _minQuery) {
      _searchSeq++;
      setState(() {
        _results = const [];
        _searched = false;
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text));
  }

  Future<void> _search(String text) async {
    final l10n = AppLocalizations.of(context)!;
    final seq = ++_searchSeq;
    setState(() => _searching = true);
    final result = await ref
        .read(organizationRepositoryProvider)
        .searchProfiles(text);
    // A newer search (or a cleared field) supersedes this answer.
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _searching = false;
      _searched = true;
      result.fold(
        (failure) {
          _results = const [];
          _error = backendErrorMessage(l10n, failure);
        },
        (profiles) {
          _results = profiles;
          _error = null;
        },
      );
    });
  }

  Future<void> _invite(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busyIds.add(profile.id);
      _error = null;
    });
    final repository = ref.read(organizationRepositoryProvider);
    final result = await repository.inviteUserByUsername(
      widget.organization.id,
      profile.username,
      bandId: _bandId,
    );
    if (!mounted) return;
    setState(() {
      _busyIds.remove(profile.id);
      result.fold(
        (failure) => _error = backendErrorMessage(l10n, failure),
        (_) => _invitedNow.add(profile.id),
      );
    });
    if (result.isRight()) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.inviteSentSnack(_nameOf(profile))),
        ),
      );
      // Best effort: fills in the invitee's name in the pending list.
      unawaited(repository.refreshInvitations(widget.organization.id));
    }
  }

  Future<void> _cancel(Invitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(organizationRepositoryProvider)
        .cancelInvitation(widget.organization.id, invitation.id);
    if (!mounted) return;
    setState(() {
      result.fold(
        (failure) => _error = backendErrorMessage(l10n, failure),
        (_) => _error = null,
      );
    });
  }

  static String _nameOf(UserProfile p) =>
      p.displayName.trim().isEmpty ? '@${p.username}' : p.displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final bands = ref.watch(activeBandsProvider).value ?? const <Band>[];
    final invitations =
        ref.watch(organizationInvitationsProvider(widget.organization.id)).value ??
        const <Invitation>[];
    final members = ref.watch(activeMembersProvider).value ?? const [];
    final memberIds = {
      for (final m in members)
        if (m.isActive) m.userId,
    };
    final pending = [
      for (final i in invitations)
        if (i.isPending) i,
    ];
    final pendingIds = {for (final i in pending) i.invitedUserId};
    final declinedIds = {
      for (final i in invitations)
        if (i.status == InvitationStatus.declined) i.invitedUserId,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const ValueKey('invite_search_field'),
          controller: _query,
          autocorrect: false,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: l10n.inviteSearchLabel,
            helperText: l10n.inviteSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        if (bands.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BandDropdown(
            bands: bands,
            value: _bandId,
            onChanged: (id) => setState(() => _bandId = id),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const ValueKey('invite_error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (_searching)
          const Center(child: CircularProgressIndicator())
        else if (_searched && _results.isEmpty && _error == null)
          Text(l10n.inviteNoResults, style: TextStyle(color: brand.inkMuted)),
        for (final profile in _results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              key: ValueKey('invite_result_${profile.id}'),
              decoration: brand.cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameOf(profile),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '@${profile.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brand.inkMuted,
                            ),
                          ),
                          if (declinedIds.contains(profile.id) &&
                              !pendingIds.contains(profile.id) &&
                              !_invitedNow.contains(profile.id))
                            Text(
                              l10n.invitePreviouslyDeclined,
                              key: ValueKey('invite_declined_${profile.id}'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: brand.accentInk,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _resultAction(
                      l10n,
                      profile,
                      isMember: memberIds.contains(profile.id),
                      isInvited:
                          pendingIds.contains(profile.id) ||
                          _invitedNow.contains(profile.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.invitePendingTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          Text(l10n.inviteNoPending, style: TextStyle(color: brand.inkMuted)),
        for (final invitation in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              key: ValueKey('invitation_row_${invitation.id}'),
              decoration: brand.cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pendingLabel(l10n, invitation),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      key: ValueKey('invitation_cancel_${invitation.id}'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => _cancel(invitation),
                      child: Text(l10n.inviteCancelAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _pendingLabel(AppLocalizations l10n, Invitation invitation) {
    final name = invitation.inviteeDisplayName?.trim();
    final username = invitation.inviteeUsername;
    if (name != null && name.isNotEmpty) {
      return username == null ? name : '$name (@$username)';
    }
    if (username != null) return '@$username';
    return l10n.inviteInvitedUserFallback;
  }

  Widget _resultAction(
    AppLocalizations l10n,
    UserProfile profile, {
    required bool isMember,
    required bool isInvited,
  }) {
    if (isMember || isInvited) {
      return Text(
        isMember ? l10n.inviteAlreadyMemberLabel : l10n.inviteSentLabel,
        key: ValueKey('invite_state_${profile.id}'),
        style: TextStyle(color: BattutaBrand.of(context).inkMuted),
      );
    }
    return FilledButton(
      key: ValueKey('invite_send_${profile.id}'),
      style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
      onPressed: _busyIds.contains(profile.id) ? null : () => _invite(profile),
      child: Text(l10n.inviteSendAction),
    );
  }
}
