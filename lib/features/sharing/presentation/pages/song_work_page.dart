/// A song (the work) and every version of it I can see. Opened from the inbox
/// (a copy of my version, an accepted merge) and from the merge screens.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_versions_section.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SongWorkPage extends ConsumerWidget {
  const SongWorkPage({required this.songWorkId, super.key});

  final String songWorkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final work = ref.watch(songWorkProvider(songWorkId));
    // A merged-away song shows the surviving one.
    final workId = work.value?.id ?? songWorkId;
    final cached = <Song>[
      for (final song in ref.watch(repertoireProvider).value ?? const <Song>[])
        if (song.songWorkId == workId || song.songWorkId == songWorkId) song,
    ];
    final title =
        work.value?.title ?? (cached.isEmpty ? null : cached.first.title);
    final artist =
        work.value?.artist ?? (cached.isEmpty ? '' : cached.first.artist);

    return Scaffold(
      appBar: AppBar(title: Text(title ?? l10n.songPageTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (title != null)
                Text(
                  title,
                  key: const ValueKey('song_page_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (artist.isNotEmpty)
                Text(
                  artist,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
              if (work.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.songPageNeedsInternet,
                    key: const ValueKey('song_page_offline'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: brand.inkMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SongVersionsSection(
                songWorkId: workId,
                title: l10n.versionsAllTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
