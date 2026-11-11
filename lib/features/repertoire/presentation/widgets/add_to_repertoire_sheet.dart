/// Admin picker: search the versions visible to an organization (shared with
/// it, or public) and add them to its repertoire.
library;

import 'dart:async';

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/battuta_brand.dart';
import 'package:battuta/app/theme/battuta_tokens.dart';
import 'package:battuta/features/organizations/domain/entities/organization.dart';
import 'package:battuta/features/organizations/domain/entities/repertoire.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/organizations/presentation/providers/organization_data_providers.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/repertoire/presentation/widgets/version_owner_text.dart';
import 'package:battuta/features/sync/presentation/providers/cloud_sync_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAddToRepertoireSheet(
  BuildContext context,
  Organization organization,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => AddToRepertoireSheet(organization: organization),
);

class AddToRepertoireSheet extends ConsumerStatefulWidget {
  const AddToRepertoireSheet({
    required this.organization,
    this.debounce = const Duration(milliseconds: 350),
    super.key,
  });

  final Organization organization;
  final Duration debounce;

  @override
  ConsumerState<AddToRepertoireSheet> createState() =>
      _AddToRepertoireSheetState();
}

class _AddToRepertoireSheetState extends ConsumerState<AddToRepertoireSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  bool _loading = true;
  Object? _error;
  String? _addError;
  List<RepertoireCandidate> _candidates = const [];
  final Set<String> _adding = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, _search);
  }

  Future<void> _search() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(organizationRepertoireRepositoryProvider)
        .searchCandidates(widget.organization.id, _query.text);
    // A newer search (or closing the sheet) makes this answer stale.
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) {
          _error = failure;
          _candidates = const [];
        },
        (found) => _candidates = found,
      );
    });
  }

  Future<void> _add(RepertoireCandidate candidate) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _adding.add(candidate.versionId);
      _addError = null;
    });
    final result = await ref
        .read(organizationRepertoireRepositoryProvider)
        .addToRepertoire(widget.organization.id, candidate);
    if (!mounted) return;
    setState(() {
      _adding.remove(candidate.versionId);
      result.fold(
        (failure) => _addError = backendErrorMessage(l10n, failure),
        (_) {},
      );
    });
    if (result.isRight()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addedToRepertoireDone(candidate.title))),
      );
      // Pull the version so the entry opens; offline it waits for the next sync.
      unawaited(ref.read(cloudSyncProvider.notifier).triggerSync());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final me = ref.watch(currentAccountIdProvider);
    final inRepertoire = {
      for (final entry
          in ref
                  .watch(organizationRepertoireProvider(widget.organization.id))
                  .value ??
              const <RepertoireEntry>[])
        entry.versionId,
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.repertoirePickerTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  key: const ValueKey('picker_search_field'),
                  controller: _query,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.repertoirePickerSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              if (_addError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _addError!,
                    key: const ValueKey('picker_add_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                backendErrorMessage(l10n, _error!),
                                key: const ValueKey('picker_error'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _search,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _candidates.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.repertoirePickerEmpty,
                            key: const ValueKey('picker_empty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _candidates.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = _candidates[index];
                          final added = inRepertoire.contains(
                            candidate.versionId,
                          );
                          final mine = candidate.ownerId == me;
                          return ConstrainedBox(
                            key: ValueKey('candidate_${candidate.versionId}'),
                            constraints: const BoxConstraints(minHeight: 56),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: BattutaSpace.sm,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          candidate.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          [
                                            if (candidate.artist.isNotEmpty)
                                              candidate.artist,
                                            candidate.label,
                                            candidate.key,
                                            mine
                                                ? l10n.repertoirePickerYours
                                                : ownedByText(l10n, candidate),
                                          ].join(' · '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: brand.inkMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (added)
                                  Text(
                                    l10n.repertoirePickerAdded,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: brand.accentInk),
                                  )
                                else
                                  IconButton(
                                    key: ValueKey(
                                      'add_candidate_${candidate.versionId}',
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    tooltip: l10n.repertoirePickerAddTooltip(
                                      candidate.title,
                                    ),
                                    icon: _adding.contains(candidate.versionId)
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            Icons.add_circle_outline,
                                            color: brand.accentInk,
                                          ),
                                    onPressed:
                                        _adding.contains(candidate.versionId)
                                        ? null
                                        : () => _add(candidate),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
