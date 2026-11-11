/// Settings of one organization: name, my role, quota, leaving and the
/// archive flow (which every admin has to approve and cannot be undone from
/// the app).
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/repositories/organization_repository.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_settings_providers.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrganizationSettingsPage extends ConsumerWidget {
  const OrganizationSettingsPage({required this.organizationId, super.key});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final organization = ref.watch(organizationByIdProvider(organizationId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgSettingsTitle)),
      body: organization.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StageEmptyState(
          icon: Icons.error_outline,
          tone: Theme.of(context).colorScheme.error,
          title: l10n.orgSettingsNotFound,
          message: backendErrorMessage(l10n, error),
        ),
        data: (org) => org == null
            ? StageEmptyState(
                icon: Icons.groups_outlined,
                title: l10n.orgSettingsNotFound,
              )
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _SettingsBody(organization: org),
                ),
              ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brand = BattutaBrand.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(BattutaSpace.lg),
      children: [
        _Section(
          children: [
            Text(
              organization.name,
              key: const ValueKey('org_settings_name'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: brand.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BattutaSpace.sm),
            Wrap(
              spacing: BattutaSpace.sm,
              runSpacing: BattutaSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.orgSettingsYourRole,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
                _RoleBadge(admin: organization.isAdmin),
              ],
            ),
            if (organization.isAdmin && !organization.isArchived) ...[
              const SizedBox(height: BattutaSpace.md),
              OutlinedButton.icon(
                key: const ValueKey('org_rename_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.orgSettingsRenameAction),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _RenameDialog(organization: organization),
                ),
              ),
            ],
          ],
        ),
        if (organization.isArchived) ...[
          const SizedBox(height: BattutaSpace.md),
          _Section(
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: brand.inkMuted),
                  const SizedBox(width: BattutaSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.orgSettingsArchivedNotice,
                      key: const ValueKey('org_archived_notice'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        if (organization.isAdmin) ...[
          const SizedBox(height: BattutaSpace.md),
          _QuotaSection(organizationId: organization.id),
        ],
        if (!organization.isArchived) ...[
          const SizedBox(height: BattutaSpace.md),
          _LeaveSection(organization: organization),
        ],
        if (organization.isAdmin && !organization.isArchived) ...[
          const SizedBox(height: BattutaSpace.md),
          _ArchiveSection(organization: organization),
        ],
        const SizedBox(height: BattutaSpace.xl),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children, this.title, this.tone});

  final String? title;
  final Color? tone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BattutaSpace.lg),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BattutaRadius.mdAll,
        border: Border.all(color: tone ?? brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tone ?? brand.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BattutaSpace.sm),
          ],
          ...children,
        ],
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
          key: const ValueKey('org_settings_role'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: admin ? brand.accentInk : brand.inkMuted,
          ),
        ),
      ),
    );
  }
}

// ── Rename ─────────────────────────────────────────────────────────────────

class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog({required this.organization});

  final Organization organization;

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  late final _name = TextEditingController(text: widget.organization.name);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
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
        .renameOrganization(widget.organization.id, name);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (_) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.orgSettingsRenamed)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.orgSettingsRenameTitle),
      content: SingleChildScrollView(
        child: TextField(
          key: const ValueKey('org_rename_field'),
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saving ? null : _save(),
          decoration: InputDecoration(
            labelText: l10n.organizationNameLabel,
            errorText: _error,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('org_rename_confirm'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

// ── Quota ──────────────────────────────────────────────────────────────────

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 10 || unit == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

class _QuotaSection extends ConsumerWidget {
  const _QuotaSection({required this.organizationId});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quota = ref.watch(organizationQuotaProvider(organizationId));
    return _Section(
      title: l10n.orgSettingsQuotaTitle,
      children: [
        quota.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(
            key: const ValueKey('org_quota_unavailable'),
            error is Failure && error.errorCode == BackendErrorCode.offline
                ? l10n.orgSettingsQuotaUnavailable
                : backendErrorMessage(l10n, error),
          ),
          data: (q) => Column(
            key: const ValueKey('org_quota'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.orgSettingsQuotaTier(q.tier)),
              Text(l10n.orgSettingsQuotaCredits(q.monthlyGeminiCreditsLimit)),
              Text(
                l10n.orgSettingsQuotaStorage(_formatBytes(q.maxStorageBytes)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Leave ──────────────────────────────────────────────────────────────────

class _LeaveSection extends ConsumerWidget {
  const _LeaveSection({required this.organization});

  final Organization organization;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
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
            key: const ValueKey('org_leave_confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.leaveOrganizationAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(organizationRepositoryProvider)
        .leaveOrganization(organization.id);
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text(backendErrorMessage(l10n, failure))),
      ),
      (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.orgSettingsLeaveDone)),
        );
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(AppRoutes.repertoire);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return _Section(
      children: [
        if (organization.isAdmin) ...[
          Text(
            l10n.orgSettingsLeaveHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: BattutaBrand.of(context).inkMuted,
            ),
          ),
          const SizedBox(height: BattutaSpace.md),
        ],
        OutlinedButton.icon(
          key: const ValueKey('org_leave_btn'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 48),
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
          ),
          icon: const Icon(Icons.logout),
          label: Text(l10n.leaveOrganizationAction),
          onPressed: () => _leave(context, ref),
        ),
      ],
    );
  }
}

// ── Archive ────────────────────────────────────────────────────────────────

/// Asks the user to type [expected] before an action that cannot be undone.
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String expected,
  required String actionLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _TypedConfirmDialog(
      title: title,
      body: body,
      expected: expected,
      actionLabel: actionLabel,
    ),
  );
  return confirmed ?? false;
}

class _TypedConfirmDialog extends StatefulWidget {
  const _TypedConfirmDialog({
    required this.title,
    required this.body,
    required this.expected,
    required this.actionLabel,
  });

  final String title;
  final String body;
  final String expected;
  final String actionLabel;

  @override
  State<_TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<_TypedConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches =>
      _controller.text.trim().toLowerCase() ==
      widget.expected.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('archive_confirm_field'),
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.orgArchiveTypeToConfirm(widget.expected),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('archive_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _ArchiveSection extends ConsumerStatefulWidget {
  const _ArchiveSection({required this.organization});

  final Organization organization;

  @override
  ConsumerState<_ArchiveSection> createState() => _ArchiveSectionState();
}

class _ArchiveSectionState extends ConsumerState<_ArchiveSection> {
  bool _busy = false;

  Future<void> _run(
    Future<Result<Organization>> Function() call,
    String Function(AppLocalizations l10n, Organization result) done,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.fold(
            (failure) => backendErrorMessage(l10n, failure),
            (org) => done(l10n, org),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmThen(
    Future<Result<Organization>> Function() call,
    String Function(AppLocalizations l10n, Organization result) done,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showTypedConfirmDialog(
      context,
      title: l10n.orgArchiveConfirmTitle(widget.organization.name),
      body: l10n.orgArchiveConfirmBody,
      expected: widget.organization.name,
      actionLabel: l10n.orgArchiveConfirmAction,
    );
    if (!confirmed || !mounted) return;
    await _run(call, done);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final org = widget.organization;
    final repository = ref.read(organizationRepositoryProvider);
    final request = ref.watch(organizationArchiveRequestProvider(org.id)).value;
    final members =
        ref.watch(organizationMembersProvider(org.id)).value ?? const [];
    final me = ref.watch(currentAccountIdProvider);
    final admins = [
      for (final member in members)
        if (member.isAdmin && member.isActive) member,
    ];
    String nameOf(String? userId) {
      for (final member in members) {
        if (member.userId == userId) {
          return member.displayName ?? member.username ?? '?';
        }
      }
      return '?';
    }

    String archivedMessage(AppLocalizations l10n, Organization result) =>
        result.isArchived
        ? l10n.orgArchiveDone
        : (request == null
              ? l10n.orgArchiveRequestSent
              : l10n.orgArchiveApprovedDone);

    return _Section(
      title: l10n.orgArchiveSection,
      tone: theme.colorScheme.error,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: BattutaSpace.sm),
            Expanded(
              child: Text(
                l10n.orgArchiveWarning,
                key: const ValueKey('org_archive_warning'),
                style: theme.textTheme.bodyMedium?.copyWith(color: brand.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: BattutaSpace.md),
        if (request == null)
          FilledButton.icon(
            key: const ValueKey('org_archive_request_btn'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 48),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(l10n.orgArchiveRequestAction),
            onPressed: _busy
                ? null
                : () => _confirmThen(
                    () => repository.requestArchive(org.id),
                    archivedMessage,
                  ),
          )
        else ...[
          Text(
            l10n.orgArchiveRequestedBy(nameOf(request.requestedBy)),
            style: theme.textTheme.labelLarge?.copyWith(color: brand.ink),
          ),
          const SizedBox(height: BattutaSpace.sm),
          Text(
            l10n.orgArchiveApprovalsTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: brand.inkMuted,
            ),
          ),
          const SizedBox(height: BattutaSpace.xs),
          for (final admin in admins)
            Padding(
              key: ValueKey('archive_approval_${admin.userId}'),
              padding: const EdgeInsets.symmetric(vertical: BattutaSpace.xs),
              child: Row(
                children: [
                  Icon(
                    request.isApprovedBy(admin.userId)
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    size: 18,
                    color: request.isApprovedBy(admin.userId)
                        ? brand.accentInk
                        : brand.inkMuted,
                  ),
                  const SizedBox(width: BattutaSpace.sm),
                  Expanded(
                    child: Text(
                      admin.displayName ?? admin.username ?? '?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: BattutaSpace.sm),
                  Text(
                    request.isApprovedBy(admin.userId)
                        ? l10n.orgArchiveApproved
                        : l10n.orgArchivePending,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: brand.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: BattutaSpace.md),
          Wrap(
            spacing: BattutaSpace.sm,
            runSpacing: BattutaSpace.sm,
            children: [
              if (me != null && !request.isApprovedBy(me))
                FilledButton(
                  key: const ValueKey('org_archive_approve_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _confirmThen(
                          () => repository.approveArchive(org.id),
                          archivedMessage,
                        ),
                  child: Text(l10n.orgArchiveApproveAction),
                ),
              OutlinedButton(
                key: const ValueKey('org_archive_cancel_btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => repository.cancelArchive(org.id),
                        (l10n, _) => l10n.orgArchiveCancelledDone,
                      ),
                child: Text(l10n.orgArchiveCancelAction),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
