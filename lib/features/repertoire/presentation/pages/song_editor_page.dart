/// Song editor page — create or edit a song's metadata and sections.
///
/// Provides a form-based interface for editing song properties and
/// managing the section/chord structure.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A form page for creating or editing a song.
///
/// When [songId] is null, operates in creation mode.
/// When [songId] is provided, loads existing data for editing.
class SongEditorPage extends ConsumerWidget {
  /// Creates a [SongEditorPage].
  ///
  /// Pass [songId] to edit an existing song, or leave null to create a new one.
  const SongEditorPage({this.songId, super.key});

  /// The ID of the song to edit, or null for creating a new song.
  final String? songId;

  bool get _isEditing => songId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'New Song'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: save song via provider
            },
            child: const Text('Save'),
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
                Icons.edit_note,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Editing: $songId' : 'Create New Song',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Song editor form coming with\n'
                'domain model integration.',
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

