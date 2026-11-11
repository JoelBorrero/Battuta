/// Discover: public versions shared by other musicians. Search by title or
/// artist, open one to read it, or fork it into my library. Online only.
library;

import 'dart:async';

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/version_owner_text.dart';
import 'package:battuta/features/sharing/domain/entities/song_sharing.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/fork_version_flow.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({
    this.debounce = const Duration(milliseconds: 350),
    this.pageSize = 30,
    super.key,
  });

  final Duration debounce;
  final int pageSize;

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  Failure? _error;
  String? _openError;
  List<SongVersionListing> _results = const [];
  final Set<String> _opening = {};

  @override
  void initState() {
    super.initState();
    if (ref.read(currentAccountIdProvider) != null) {
      _search();
    } else {
      _loading = false;
    }
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
      _openError = null;
    });
    final result = await ref
        .read(songSharingRepositoryProvider)
        .searchPublicVersions(_query.text, limit: widget.pageSize);
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) {
          _error = failure;
          _results = const [];
          _hasMore = false;
        },
        (found) {
          _results = found;
          _hasMore = found.length >= widget.pageSize;
        },
      );
    });
  }

  Future<void> _loadMore() async {
    final request = _request;
    setState(() => _loadingMore = true);
    final result = await ref
        .read(songSharingRepositoryProvider)
        .searchPublicVersions(
          _query.text,
          limit: widget.pageSize,
          offset: _results.length,
        );
    if (!mounted || request != _request) return;
    setState(() {
      _loadingMore = false;
      result.fold((failure) => _error = failure, (found) {
        final known = {for (final r in _results) r.versionId};
        _results = [
          ..._results,
          for (final r in found)
            if (!known.contains(r.versionId)) r,
        ];
        _hasMore = found.length >= widget.pageSize;
      });
    });
  }

  Future<void> _open(SongVersionListing listing) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    setState(() {
      _opening.add(listing.versionId);
      _openError = null;
    });
    final result = await ref
        .read(songSharingRepositoryProvider)
        .openVersion(listing.versionId);
    if (!mounted) return;
    setState(() => _opening.remove(listing.versionId));
    result.fold(
      (failure) => setState(() => _openError = _message(l10n, failure)),
      (_) {
        ref.invalidate(repertoireProvider);
        unawaited(router.push(AppRoutes.songDetail(listing.versionId)));
      },
    );
  }

  String _message(AppLocalizations l10n, Object failure) =>
      failure is Failure && failure.errorCode == BackendErrorCode.offline
      ? l10n.discoverNeedsInternet
      : backendErrorMessage(l10n, failure);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final me = ref.watch(currentAccountIdProvider);

    Widget body;
    if (me == null) {
      body = StageEmptyState(
        key: const ValueKey('discover_sign_in'),
        icon: Icons.explore_outlined,
        title: l10n.discoverTitle,
        message: l10n.discoverSignIn,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: () => context.push(AppRoutes.signIn),
            child: Text(l10n.welcomeSignIn),
          ),
        ],
      );
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _results.isEmpty) {
      body = StageEmptyState(
        key: const ValueKey('discover_error'),
        icon: Icons.cloud_off_outlined,
        title: l10n.discoverTitle,
        message: _message(l10n, _error!),
        tone: theme.colorScheme.error,
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: _search,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      );
    } else if (_results.isEmpty) {
      body = StageEmptyState(
        key: const ValueKey('discover_empty'),
        icon: Icons.explore_outlined,
        title: l10n.discoverTitle,
        message: l10n.discoverEmpty,
      );
    } else {
      body = ListView.separated(
        key: const ValueKey('discover_list'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _results.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == _results.length) {
            return Align(
              child: OutlinedButton(
                key: const ValueKey('discover_load_more'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.discoverLoadMore),
              ),
            );
          }
          final listing = _results[index];
          final mine = listing.ownerId == me;
          return DecoratedBox(
            key: ValueKey('discover_${listing.versionId}'),
            decoration: brand.cardDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: BattutaPressable(
                    onTap: _opening.contains(listing.versionId)
                        ? null
                        : () => _open(listing),
                    semanticLabel: l10n.versionOpenTooltip(listing.title),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              [
                                if (listing.artist.isNotEmpty) listing.artist,
                                listing.label,
                                listing.key,
                                mine
                                    ? l10n.versionYours
                                    : ownedByText(l10n, listing),
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: brand.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_opening.contains(listing.versionId))
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    key: ValueKey('discover_fork_${listing.versionId}'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    tooltip: l10n.forkTooltip(listing.label),
                    icon: Icon(Icons.call_split, color: brand.accentInk),
                    onPressed: () => forkVersionFlow(
                      context,
                      ref,
                      versionId: listing.versionId,
                      sourceLabel: listing.label,
                      cachedSource: _cachedSong(listing.versionId),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoverTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (me != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    l10n.discoverHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    key: const ValueKey('discover_search_field'),
                    controller: _query,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: l10n.discoverSearchLabel,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
              if (_openError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    _openError!,
                    key: const ValueKey('discover_open_error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Song? _cachedSong(String versionId) {
    for (final song in ref.read(repertoireProvider).value ?? const <Song>[]) {
      if (song.id == versionId) return song;
    }
    return null;
  }
}
