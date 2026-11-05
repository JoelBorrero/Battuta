/// Song detail page — displays a full song with sections, chords, and metadata.
///
/// This page shows the complete lead sheet view for a single song,
/// including all sections with their chord progressions and lyrics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays the full detail view of a song.
///
/// Receives the song ID via route parameter and loads the song data.
/// Shows:
/// - Song metadata header (title, artist, key, tempo, time signature)
/// - Scrollable list of sections with chord grids and lyrics
/// - Action buttons for edit, transpose, and share
class SongDetailPage extends ConsumerWidget {
  /// Creates a [SongDetailPage] for the given [songId].
  const SongDetailPage({required this.songId, super.key});

  /// The unique identifier of the song to display.
  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // TODO: Load song by ID from provider
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Transpose',
            onPressed: () {
              // TODO: show transpose dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              // TODO: navigate to editor
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Song: $songId',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Full lead sheet view coming with\n'
                'StaffCanvas & chord grid tickets.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

