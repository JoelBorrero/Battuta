/// Bottom sheet of the setlist detail page that appends songs to the setlist.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Opens the sheet listing [available] songs; tapping one calls [onPick] and
/// closes the sheet. [libraryIsEmpty] picks the empty-state wording.
Future<void> showAddSongsToSetlistSheet(
  BuildContext context, {
  required List<Song> available,
  required bool libraryIsEmpty,
  required void Function(Song song, int index) onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddSongsToSetlistSheet(
      available: available,
      libraryIsEmpty: libraryIsEmpty,
      onPick: onPick,
    ),
  );
}

class AddSongsToSetlistSheet extends StatelessWidget {
  const AddSongsToSetlistSheet({
    required this.available,
    required this.libraryIsEmpty,
    required this.onPick,
    super.key,
  });

  final List<Song> available;
  final bool libraryIsEmpty;
  final void Function(Song song, int index) onPick;

  static String? _meta(Song song) {
    final meta = [
      if (song.artist.trim().isNotEmpty) song.artist.trim(),
      if (song.tempo > 0) song.tempoLabel,
    ].join(' · ');
    return meta.isEmpty ? null : meta;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = BattutaBrand.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BattutaSpace.lg,
            BattutaSpace.md,
            BattutaSpace.lg,
            BattutaSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StageSectionHeader(
                title: l10n?.addSongToSetlist ?? 'Add Song to Setlist',
                padding: const EdgeInsets.only(bottom: BattutaSpace.sm),
              ),
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BattutaSpace.xl,
                  ),
                  child: Text(
                    libraryIsEmpty
                        ? (l10n?.noSongsInRepertoireYet ??
                              'No songs in repertoire yet. Create or load sample songs.')
                        : (l10n?.allSongsAlreadyInSetlist ??
                              'All songs are already in this setlist.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: brand.inkMuted),
                  ),
                )
              else
                StageCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < available.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: brand.border),
                        StageRow(
                          key: ValueKey('add_song_${available[i].id}'),
                          label: available[i].title,
                          subtitle: _meta(available[i]),
                          leading: StageKeyPill(available[i].key),
                          trailing: Padding(
                            padding: const EdgeInsets.only(
                              left: BattutaSpace.sm,
                            ),
                            child: Icon(
                              Icons.add_circle,
                              size: 24,
                              color: brand.accentInk,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            onPick(available[i], i);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
