/// Joins an organization with an invite token (`/join/<token>`), then shows
/// the Roster. Failures stay on this page with a readable reason.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/pending_invite_provider.dart';
import 'package:battuta/features/settings/presentation/widgets/account_section.dart';
import 'package:battuta/features/team/presentation/providers/team_tab_request_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({required this.token, super.key});

  final String token;

  @override
  ConsumerState<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends ConsumerState<JoinPage> {
  String? _error;
  bool _joining = true;

  /// A token that waited for sign-in asks before joining; a link opened while
  /// signed in joins right away.
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _confirming = ref.read(pendingInviteTokenProvider) == widget.token;
    Future(() {
      if (!mounted) return;
      // The token is spent now: a pending copy must not send us back here.
      ref.read(pendingInviteTokenProvider.notifier).clear();
      if (!_confirming) _join();
    });
  }

  void _confirm() {
    setState(() => _confirming = false);
    _join();
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    final result = await ref
        .read(organizationRepositoryProvider)
        .joinWithInviteLink(widget.token);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await result.fold(
      (failure) async => setState(() {
        _joining = false;
        _error = backendErrorMessage(l10n, failure);
      }),
      (member) async {
        // Already a member also lands here (the server is idempotent).
        await ref
            .read(activeOrganizationSelectionProvider.notifier)
            .select(member.organizationId);
        if (!mounted) return;
        ref.read(teamTabRequestProvider.notifier).request(TeamTab.roster);
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(l10n.joinSuccessSnack)));
        context.go(AppRoutes.team);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_confirming) {
      final account =
          ref.watch(myProfileProvider).value?.username ??
          ref.watch(currentUserProvider)?.email ??
          '';
      return Scaffold(
        appBar: AppBar(title: Text(l10n.joinTitle)),
        body: StageEmptyState(
          key: const ValueKey('join_confirm'),
          icon: Icons.group_add_outlined,
          title: l10n.joinConfirmTitle,
          message: l10n.joinConfirmMessage(account),
          actions: [
            FilledButton(
              key: const ValueKey('join_confirm_btn'),
              style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: _confirm,
              child: Text(l10n.joinConfirmAction),
            ),
            OutlinedButton(
              key: const ValueKey('join_cancel_btn'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: () => context.go(AppRoutes.initial),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinTitle)),
      body: _error == null
          ? Center(
              key: const ValueKey('join_progress'),
              child: _joining
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.joinJoining),
                      ],
                    )
                  : const SizedBox.shrink(),
            )
          : StageEmptyState(
              key: const ValueKey('join_error'),
              icon: Icons.link_off,
              title: l10n.joinFailedTitle,
              message: _error,
              tone: Theme.of(context).colorScheme.error,
              actions: [
                FilledButton(
                  key: const ValueKey('join_retry_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 48),
                  ),
                  onPressed: _join,
                  child: Text(l10n.joinRetry),
                ),
                OutlinedButton(
                  key: const ValueKey('join_back_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 48),
                  ),
                  onPressed: () => context.go(AppRoutes.initial),
                  child: Text(l10n.joinBackToApp),
                ),
              ],
            ),
    );
  }
}
