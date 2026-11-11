/// Song editor page — create or edit a song's metadata and sections.
///
/// Provides a comprehensive form for managing song properties, time signature,
/// tempo with tap-tempo capability, tags, notes, and a dynamic section builder
/// with chord chart parsing, reordering, and lyrics.
library;

import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/sharing/domain/entities/song_suggestion.dart';
import 'package:battuta/features/sharing/presentation/widgets/move_to_song_sheet.dart';
import 'package:battuta/features/sharing/presentation/widgets/sharing_sheet.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_suggestions_panel.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A full-featured form page for creating or editing a song.
///
/// When [songId] is null, operates in creation mode.
/// When [songId] is provided, loads existing data from the database.
/// When [initialSong] is provided, pre-populates fields (e.g. from an import).
class SongEditorPage extends ConsumerStatefulWidget {
  /// Creates a [SongEditorPage].
  const SongEditorPage({this.songId, this.initialSong, super.key});

  /// The ID of the song to edit, or null for creating a new song.
  final String? songId;

  /// Optional initial song to populate fields with (e.g. from an import).
  final Song? initialSong;

  @override
  ConsumerState<SongEditorPage> createState() => _SongEditorPageState();
}

class _SongEditorPageState extends ConsumerState<SongEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _tagInputController;
  late final TextEditingController _notesController;

  String _selectedKey = 'C';
  int _tempo = 120;
  (int, int) _timeSignature = (4, 4);
  List<String> _tags = [];
  final List<_EditableSection> _sections = [];

  bool _initialized = false;
  bool _isSaving = false;
  Song? _originalSong;

  /// The existing song a new version is attached to (picked from the
  /// suggestions); null keeps what was typed as a new song.
  SongSuggestion? _linked;

  // Tap-tempo timestamp tracker
  final List<DateTime> _tapTimestamps = [];

  static const List<(int, int)> _supportedTimeSignatures = [
    (4, 4),
    (3, 4),
    (6, 8),
    (2, 4),
    (5, 4),
    (12, 8),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _artistController = TextEditingController();
    _tagInputController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.initialSong != null) {
      _populateFromSong(widget.initialSong!);
    } else if (widget.songId == null) {
      // Creation mode: seed with a single default verse
      _sections.add(
        _EditableSection(
          id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Verse 1',
          chords: [],
          lyrics: '',
          repeatCount: 1,
        ),
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _tagInputController.dispose();
    _notesController.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  void _populateFromSong(Song song) {
    if (_initialized) return;
    _initialized = true;
    _originalSong = song;

    _titleController.text = song.title;
    _artistController.text = song.artist;
    _selectedKey = song.key;
    _tempo = song.tempo;
    _timeSignature = song.timeSignature;
    _tags = List.from(song.tags);
    _notesController.text = song.notes ?? '';

    _sections.clear();
    for (final s in song.sections) {
      _sections.add(
        _EditableSection(
          id: s.id,
          name: s.name,
          chords: List.from(s.chords),
          lyrics: s.lyrics ?? '',
          rehearsalNotes: s.rehearsalNotes ?? '',
          repeatCount: s.repeatCount,
        ),
      );
    }

    if (_sections.isEmpty) {
      _sections.add(
        _EditableSection(
          id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Verse 1',
          chords: [],
          lyrics: '',
          repeatCount: 1,
        ),
      );
    }
  }

  void _recordTapTempo() {
    final now = DateTime.now();
    _tapTimestamps.add(now);

    // Keep taps from the last 3 seconds only
    _tapTimestamps.removeWhere((t) => now.difference(t).inMilliseconds > 3000);

    if (_tapTimestamps.length >= 2) {
      var totalDeltaMs = 0;
      for (var i = 1; i < _tapTimestamps.length; i++) {
        totalDeltaMs += _tapTimestamps[i]
            .difference(_tapTimestamps[i - 1])
            .inMilliseconds;
      }
      final avgIntervalMs = totalDeltaMs / (_tapTimestamps.length - 1);
      if (avgIntervalMs > 0) {
        final calculatedBpm = (60000 / avgIntervalMs).round().clamp(30, 300);
        setState(() {
          _tempo = calculatedBpm;
        });
      }
    }
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
      });
    }
  }

  _EditableSection? _findPreviousSection(String name, [int? beforeIndex]) {
    final searchLimit = beforeIndex ?? _sections.length;
    final trimmedName = name.trim().toLowerCase();
    if (trimmedName.isEmpty || trimmedName == 'new section') return null;

    for (var i = searchLimit - 1; i >= 0; i--) {
      final s = _sections[i];
      if (s.nameController.text.trim().toLowerCase() == trimmedName) {
        return s;
      }
    }
    return null;
  }

  void _addSection([String defaultName = 'New Section', int? insertIndex]) {
    final l10n = AppLocalizations.of(context);
    final previous = _findPreviousSection(defaultName, insertIndex);

    final newSection = _EditableSection(
      id: 'sec_${DateTime.now().millisecondsSinceEpoch}_${_sections.length}',
      name: defaultName,
      chords: previous != null
          ? previous.chords.map((c) => c.copyWith()).toList()
          : [],
      lyrics: previous?.lyricsController.text ?? '',
      rehearsalNotes: previous?.notesController.text ?? '',
      repeatCount: previous?.repeatCount ?? 1,
    );

    setState(() {
      if (insertIndex != null &&
          insertIndex >= 0 &&
          insertIndex <= _sections.length) {
        _sections.insert(insertIndex, newSection);
      } else {
        _sections.add(newSection);
      }
    });

    if (previous != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.sectionPreloadedNotice(defaultName) ??
                'Pre-loaded chords and lyrics from previous $defaultName',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _duplicateSection(int index) {
    if (index < 0 || index >= _sections.length) return;
    final l10n = AppLocalizations.of(context);
    final source = _sections[index];
    final sectionName = source.nameController.text.trim().isEmpty
        ? 'Section'
        : source.nameController.text.trim();

    final duplicated = source.clone(
      newId: 'sec_${DateTime.now().millisecondsSinceEpoch}_${_sections.length}',
    );

    setState(() {
      _sections.insert(index + 1, duplicated);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.sectionDuplicatedNotice(sectionName) ??
                'Duplicated $sectionName',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copySectionContent(int targetIndex, _EditableSection source) {
    if (targetIndex < 0 || targetIndex >= _sections.length) return;
    final l10n = AppLocalizations.of(context);
    final target = _sections[targetIndex];
    setState(() {
      target.chords = source.chords.map((c) => c.copyWith()).toList();
      target.quickChordsController.text = target.chords
          .map((c) => c.displayLabel)
          .join(' ');
      target.lyricsController.text = source.lyricsController.text;
      target.notesController.text = source.notesController.text;
      target.repeatCount = source.repeatCount;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.sectionPreloadedNotice(source.nameController.text) ??
                'Pre-loaded chords and lyrics from ${source.nameController.text}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeSection(int index) {
    setState(() {
      final removed = _sections.removeAt(index);
      removed.dispose();
    });
  }

  void _moveSection(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _sections.length) return;
    setState(() {
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
  }

  /// Editing depends on ownership, never on the organization role: a new song
  /// or one of mine is editable, a version owned by somebody else is not.
  bool _canEdit(String? accountId) =>
      _originalSong == null || _originalSong!.isEditableBy(accountId);

  /// Title and artist belong to the song: only the person who created it
  /// edits them. Other owners of a version of it see them read-only.
  bool _canEditTitle(String? accountId) =>
      _originalSong == null || _originalSong!.canEditTitleBy(accountId);

  /// A suggestion was picked (or dropped with `null`) for a new version.
  void _onSongPicked(SongSuggestion? song) {
    setState(() {
      _linked = song;
      if (song != null) {
        _titleController.text = song.title;
        _artistController.text = song.artist;
      }
    });
  }

  /// Moves this version to another song and shows the new title and artist.
  Future<void> _moveToAnotherSong(Song original) async {
    final moved = await showMoveToSongSheet(context, original);
    if (moved == null || !mounted) return;
    setState(() {
      _originalSong = moved;
      _titleController.text = moved.title;
      _artistController.text = moved.artist;
    });
  }

  Future<void> _saveSong() async {
    final l10n = AppLocalizations.of(context);
    if (!_canEdit(ref.read(currentAccountIdProvider))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.readOnlyVersionEditorNotice ??
                'Only the owner can edit this version.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final songId =
          widget.songId ?? 'song_${DateTime.now().millisecondsSinceEpoch}';

      final finalSections = <SongSection>[];
      for (var i = 0; i < _sections.length; i++) {
        final sec = _sections[i];
        final name = sec.nameController.text.trim().isEmpty
            ? 'Section ${i + 1}'
            : sec.nameController.text.trim();

        finalSections.add(
          SongSection(
            id: sec.id,
            name: name,
            chords: sec.chords,
            lyrics: sec.lyricsController.text.trim().isEmpty
                ? null
                : sec.lyricsController.text.trim(),
            rehearsalNotes: sec.notesController.text.trim().isEmpty
                ? null
                : sec.notesController.text.trim(),
            repeatCount: sec.repeatCount,
            orderIndex: i,
          ),
        );
      }

      final song = Song(
        id: songId,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        key: _selectedKey,
        tempo: _tempo,
        timeSignature: _timeSignature,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        sections: finalSections,
        createdAt: _originalSong?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        // A new version picked from the suggestions joins that song; an
        // existing one keeps its song (the repository ignores these).
        songWorkId: _linked?.songWorkId,
        songCreatorId: _linked?.createdBy,
      );

      final notifier = ref.read(repertoireProvider.notifier);
      final failure = widget.songId != null
          ? await notifier.updateSong(song)
          : await notifier.addSong(song);
      if (failure != null) {
        if (mounted && l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(backendErrorMessage(l10n, failure))),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.songId != null
                  ? (l10n?.songUpdatedSuccess(song.title) ??
                        'Song "${song.title}" updated successfully')
                  : (l10n?.songCreatedSuccess(song.title) ??
                        'Song "${song.title}" created successfully'),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.failedToSaveSong(e.toString()) ?? 'Failed to save song: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.songId == null) return;
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteSongTitle ?? 'Delete Song'),
        content: Text(
          l10n?.deleteSongConfirm(_titleController.text) ??
              'Are you sure you want to delete "${_titleController.text}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final failure = await ref
          .read(repertoireProvider.notifier)
          .deleteSong(widget.songId!);
      if (failure != null) {
        if (mounted && l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(backendErrorMessage(l10n, failure))),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.songDeletedSuccess ?? 'Song deleted')),
        );
        try {
          context.go('/repertoire');
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEditing = widget.songId != null;

    if (isEditing && !_initialized) {
      final songAsync = ref.watch(songByIdProvider(widget.songId!));
      return songAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: Text(l10n?.editSong ?? 'Edit Song')),
          body: Center(
            child: Text(
              '${l10n?.failedToLoadRepertoire ?? "Error loading song"}: $err',
            ),
          ),
        ),
        data: (song) {
          if (song == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n?.editSong ?? 'Edit Song')),
              body: Center(child: Text(l10n?.songNotFound ?? 'Song not found')),
            );
          }
          _populateFromSong(song);
          return _buildScaffold(theme, isEditing);
        },
      );
    }

    return _buildScaffold(theme, isEditing);
  }

  Widget _buildScaffold(ThemeData theme, bool isEditing) {
    final me = ref.watch(currentAccountIdProvider);
    final canEdit = _canEdit(me);
    final titleLocked = canEdit && !_canEditTitle(me);
    final fieldsLocked = titleLocked || _linked != null;
    final original = _originalSong;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (l10n?.editSong ?? 'Edit Song')
              : (l10n?.newSong ?? 'New Song'),
        ),
        actions: [
          if (isEditing && canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n?.deleteSong ?? 'Delete Song',
              onPressed: _isSaving ? null : _confirmDelete,
            ),
          FilledButton.icon(
            onPressed: (_isSaving || !canEdit) ? null : _saveSong,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(
              canEdit
                  ? (l10n?.save ?? 'Save')
                  : (l10n?.viewOnly ?? 'View Only'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (!canEdit)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.readOnlyVersionEditorNotice ??
                            'Only the owner can edit this version.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Primary Metadata ──
            TextFormField(
              key: const Key('song_title_field'),
              controller: _titleController,
              readOnly: fieldsLocked,
              decoration: InputDecoration(
                helperText: titleLocked ? l10n?.songTitleLockedHint : null,
                helperMaxLines: 3,
                labelText: l10n?.songTitleLabel ?? 'Song Title *',
                hintText: l10n?.songTitleHint ?? 'e.g. Amazing Grace',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n?.songTitleValidation ??
                      'Please enter a song title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('song_artist_field'),
              controller: _artistController,
              readOnly: fieldsLocked,
              decoration: InputDecoration(
                labelText: l10n?.artistComposerLabel ?? 'Artist / Composer *',
                hintText: l10n?.artistComposerHint ?? 'e.g. John Newton',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (val) {
                if (_linked != null) return null;
                if (val == null || val.trim().isEmpty) {
                  return l10n?.artistValidation ??
                      'Please enter an artist or composer';
                }
                return null;
              },
            ),
            if (!isEditing && canEdit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SongSuggestionsPanel(
                  titleController: _titleController,
                  selected: _linked,
                  onSelected: _onSongPicked,
                ),
              ),
            if (original != null &&
                canEdit &&
                me != null &&
                original.ownerId == me)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('editor_sharing_btn'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text(l10n?.sharingButton ?? 'Sharing'),
                      onPressed: () =>
                          showSharingSheet(context, ref, original.id),
                    ),
                    if (original.songWorkId != null)
                      OutlinedButton.icon(
                        key: const ValueKey('editor_move_btn'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(
                          Icons.drive_file_move_outline,
                          size: 18,
                        ),
                        label: Text(
                          l10n?.moveToSongButton ?? 'Move to another song',
                        ),
                        onPressed: () => _moveToAnotherSong(original),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Musical Attributes (Key, Tempo, Meter) ──
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.musicalSetup ?? 'Musical Setup',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Musical Key Selector
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            key: const Key('song_key_dropdown'),
                            isExpanded: true,
                            initialValue:
                                MusicalKey.allKeys.any(
                                  (k) => k.name == _selectedKey,
                                )
                                ? _selectedKey
                                : MusicalKey.cMajor.name,
                            decoration: InputDecoration(
                              labelText: l10n?.keyLabel ?? 'Key',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: MusicalKey.allKeys.map((k) {
                              return DropdownMenuItem(
                                value: k.name,
                                child: Text(
                                  k.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedKey = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time Signature Selector
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<(int, int)>(
                            key: const Key('song_meter_dropdown'),
                            isExpanded: true,
                            initialValue: _timeSignature,
                            decoration: InputDecoration(
                              labelText: l10n?.meterLabel ?? 'Meter',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _supportedTimeSignatures.map((sig) {
                              final (num, den) = sig;
                              return DropdownMenuItem(
                                value: sig,
                                child: Text(
                                  '$num/$den',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _timeSignature = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tempo Stepper & Tap Tempo
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.remove),
                                tooltip: l10n?.decreaseBpm ?? 'Decrease BPM',
                                onPressed: () {
                                  if (_tempo > 30) {
                                    setState(() => _tempo--);
                                  }
                                },
                              ),
                              Expanded(
                                child: Text(
                                  '$_tempo BPM',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add),
                                tooltip: l10n?.increaseBpm ?? 'Increase BPM',
                                onPressed: () {
                                  if (_tempo < 300) {
                                    setState(() => _tempo++);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _recordTapTempo,
                          icon: const Icon(Icons.touch_app),
                          label: Text(l10n?.tapTempo ?? 'Tap Tempo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tags Section ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('song_tag_input'),
                    controller: _tagInputController,
                    decoration: InputDecoration(
                      labelText: l10n?.addTag ?? 'Add Tag',
                      hintText: l10n?.tagHint ?? 'e.g. worship, rock, ballad',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: l10n?.addTag ?? 'Add Tag',
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // ── Notes Section ──
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText:
                    l10n?.notesInstructionsLabel ??
                    'Notes / Performance Instructions',
                hintText:
                    l10n?.notesInstructionsHint ??
                    'e.g. Capo 3rd fret, slow acoustic intro...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Sections Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.songSectionsCount(_sections.length) ??
                      'Song Sections (${_sections.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n?.addSection ?? 'Add Section'),
                  onPressed: () => _addSection(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Section Templates
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    l10n?.quickAdd ?? 'Quick add: ',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  for (final name in [
                    'Intro',
                    'Verse 1',
                    'Verse 2',
                    'Pre-Chorus',
                    'Chorus',
                    'Bridge',
                    'Outro',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: _findPreviousSection(name) != null
                            ? const Icon(
                                Icons.replay,
                                size: 14,
                                color: AppTheme.amberAccent,
                              )
                            : null,
                        label: Text(name),
                        onPressed: () => _addSection(name),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Section Cards
            if (_sections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    l10n?.noSectionsAddedHint ?? 'No sections added. Tap "+ Add Section" to build your song.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sections.length,
                onReorderItem: _moveSection,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return _SectionCard(
                    key: ValueKey(section.id),
                    index: index,
                    totalSections: _sections.length,
                    section: section,
                    onDelete: () => _removeSection(index),
                    onDuplicate: () => _duplicateSection(index),
                    onCopyFrom: (source) => _copySectionContent(index, source),
                    otherSections: _sections
                        .where((s) => s.id != section.id)
                        .toList(),
                    onFindPreviousMatch: (name) =>
                        _findPreviousSection(name, index),
                    onMoveUp: index > 0
                        ? () => _moveSection(index, index - 1)
                        : null,
                    onMoveDown: index < _sections.length - 1
                        ? () => _moveSection(index, index + 1)
                        : null,
                    onChordsUpdated: () => setState(() {}),
                  );
                },
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _EditableSection {
  _EditableSection({
    required this.id,
    required String name,
    required this.chords,
    required String lyrics,
    String rehearsalNotes = '',
    this.repeatCount = 1,
  }) : nameController = TextEditingController(text: name),
       lyricsController = TextEditingController(text: lyrics),
       notesController = TextEditingController(text: rehearsalNotes),
       quickChordsController = TextEditingController(
         text: chords.map((c) => c.displayLabel).join(' '),
       );

  final String id;
  final TextEditingController nameController;
  final TextEditingController lyricsController;
  final TextEditingController notesController;
  final TextEditingController quickChordsController;
  List<ChordCell> chords;
  int repeatCount;

  _EditableSection clone({String? newId, String? newName}) {
    return _EditableSection(
      id: newId ?? 'sec_${DateTime.now().millisecondsSinceEpoch}',
      name: newName ?? nameController.text,
      chords: chords.map((c) => c.copyWith()).toList(),
      lyrics: lyricsController.text,
      rehearsalNotes: notesController.text,
      repeatCount: repeatCount,
    );
  }

  void dispose() {
    nameController.dispose();
    lyricsController.dispose();
    notesController.dispose();
    quickChordsController.dispose();
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required super.key,
    required this.index,
    required this.totalSections,
    required this.section,
    required this.onDelete,
    required this.onDuplicate,
    required this.onCopyFrom,
    required this.otherSections,
    required this.onFindPreviousMatch,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChordsUpdated,
  });

  final int index;
  final int totalSections;
  final _EditableSection section;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<_EditableSection> onCopyFrom;
  final List<_EditableSection> otherSections;
  final _EditableSection? Function(String name) onFindPreviousMatch;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onChordsUpdated;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  @override
  void initState() {
    super.initState();
    widget.section.nameController.addListener(_onNameChanged);
  }

  @override
  void didUpdateWidget(_SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      oldWidget.section.nameController.removeListener(_onNameChanged);
      widget.section.nameController.addListener(_onNameChanged);
    }
  }

  @override
  void dispose() {
    widget.section.nameController.removeListener(_onNameChanged);
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  void _applyQuickChords() {
    final text = widget.section.quickChordsController.text;
    final parsed = ChordParser.parseProgression(text);
    setState(() {
      widget.section.chords = parsed;
    });
    widget.onChordsUpdated();
  }

  void _showAddChordDialog() {
    final l10n = AppLocalizations.of(context);
    String root = 'C';
    ChordQuality quality = ChordQuality.major;
    int beats = 4;
    String? bass;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(l10n?.addChord ?? 'Add Chord'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: root,
                      decoration: InputDecoration(
                        labelText: l10n?.rootNote ?? 'Root Note',
                      ),
                      items:
                          const [
                                'C',
                                'C#',
                                'Db',
                                'D',
                                'D#',
                                'Eb',
                                'E',
                                'F',
                                'F#',
                                'Gb',
                                'G',
                                'G#',
                                'Ab',
                                'A',
                                'A#',
                                'Bb',
                                'B',
                              ]
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => root = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ChordQuality>(
                      isExpanded: true,
                      initialValue: quality,
                      decoration: InputDecoration(
                        labelText: l10n?.quality ?? 'Quality',
                      ),
                      items: ChordQuality.values
                          .map(
                            (q) => DropdownMenuItem(
                              value: q,
                              child: Text(
                                '${q.displayName} (${q.symbol})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => quality = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: bass,
                      decoration: InputDecoration(
                        labelText: l10n?.bassNote ?? 'Bass Note (Slash Chord)',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            l10n?.noneOption ?? 'None',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        ...[
                          'C',
                          'C#',
                          'D',
                          'Eb',
                          'E',
                          'F',
                          'F#',
                          'G',
                          'Ab',
                          'A',
                          'Bb',
                          'B',
                        ].map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setDialogState(() => bass = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(l10n?.beatsLabel ?? 'Beats: '),
                        for (final b in [1, 2, 3, 4, 6])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('$b'),
                              selected: beats == b,
                              onSelected: (_) =>
                                  setDialogState(() => beats = b),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final chord = ChordCell(
                      root: root,
                      quality: quality,
                      bass: bass,
                      beats: beats,
                    );
                    setState(() {
                      widget.section.chords.add(chord);
                      widget.section.quickChordsController.text = widget
                          .section
                          .chords
                          .map((c) => c.displayLabel)
                          .join(' ');
                    });
                    widget.onChordsUpdated();
                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text(l10n?.add ?? 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sec = widget.section;
    final previousMatch = widget.onFindPreviousMatch(sec.nameController.text);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title & Controls Bar
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: sec.nameController,
                    decoration: InputDecoration(
                      labelText: l10n?.sectionName ?? 'Section Name',
                      isDense: true,
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Repeat count badge/stepper
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      tooltip: l10n?.decreaseRepeats ?? 'Decrease repeats',
                      onPressed: sec.repeatCount > 1
                          ? () {
                              setState(() => sec.repeatCount--);
                              widget.onChordsUpdated();
                            }
                          : null,
                    ),
                    Text(
                      '${sec.repeatCount}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      tooltip: l10n?.increaseRepeats ?? 'Increase repeats',
                      onPressed: () {
                        setState(() => sec.repeatCount++);
                        widget.onChordsUpdated();
                      },
                    ),
                  ],
                ),

                // Move up / down
                if (widget.onMoveUp != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    tooltip: l10n?.moveUp ?? 'Move up',
                    onPressed: widget.onMoveUp,
                  ),
                if (widget.onMoveDown != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    tooltip: l10n?.moveDown ?? 'Move down',
                    onPressed: widget.onMoveDown,
                  ),

                // Duplicate Section
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: l10n?.duplicateSection ?? 'Duplicate section',
                  onPressed: widget.onDuplicate,
                ),

                // Copy from other section menu (if other sections exist with content)
                if (widget.otherSections.any(
                  (s) =>
                      s.chords.isNotEmpty || s.lyricsController.text.isNotEmpty,
                ))
                  PopupMenuButton<_EditableSection>(
                    icon: const Icon(Icons.content_copy, size: 20),
                    tooltip:
                        l10n?.copyFromExistingSection ??
                        'Copy from another section...',
                    onSelected: widget.onCopyFrom,
                    itemBuilder: (context) {
                      return widget.otherSections
                          .where(
                            (s) =>
                                s.chords.isNotEmpty ||
                                s.lyricsController.text.isNotEmpty,
                          )
                          .map((s) {
                            final chordPreview = s.chords.isEmpty
                                ? ''
                                : ' (${s.chords.take(4).map((c) => c.displayLabel).join(' ')})';
                            return PopupMenuItem<_EditableSection>(
                              value: s,
                              child: Text(
                                '${s.nameController.text.trim().isEmpty ? "Section" : s.nameController.text.trim()}$chordPreview',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList();
                    },
                  ),

                // Delete Section
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  tooltip: l10n?.deleteSection ?? 'Delete Section',
                  onPressed: widget.onDelete,
                ),
              ],
            ),

            // Pre-load helper chip when current section is empty and previous match exists
            if (previousMatch != null &&
                sec.chords.isEmpty &&
                sec.lyricsController.text.trim().isEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.amberAccent,
                  ),
                  label: Text(
                    l10n?.preloadFromPrevious(
                          previousMatch.nameController.text.trim(),
                        ) ??
                        'Pre-load from previous ${previousMatch.nameController.text.trim()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      sec.chords = previousMatch.chords
                          .map((c) => c.copyWith())
                          .toList();
                      sec.quickChordsController.text = sec.chords
                          .map((c) => c.displayLabel)
                          .join(' ');
                      sec.lyricsController.text =
                          previousMatch.lyricsController.text;
                      sec.notesController.text =
                          previousMatch.notesController.text;
                      sec.repeatCount = previousMatch.repeatCount;
                    });
                    widget.onChordsUpdated();
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Chord Progression Editor Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sec.quickChordsController,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.chordsFieldLabel ??
                          'Chords (e.g. C | G/B | Am | F)',
                      hintText:
                          l10n?.chordsFieldHint ??
                          'Type chord symbols separated by spaces or bars',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip:
                            l10n?.applyChordsTooltip ?? 'Apply chords text',
                        onPressed: _applyQuickChords,
                      ),
                    ),
                    onSubmitted: (_) => _applyQuickChords(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.music_note),
                  tooltip: l10n?.addChordBuilderTooltip ?? 'Add chord builder',
                  onPressed: _showAddChordDialog,
                ),
              ],
            ),

            // Display Chord Cells
            if (sec.chords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var cIdx = 0; cIdx < sec.chords.length; cIdx++)
                    Chip(
                      label: Text(
                        '${sec.chords[cIdx].displayLabel} (${sec.chords[cIdx].beats}b)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      onDeleted: () {
                        setState(() {
                          sec.chords.removeAt(cIdx);
                          sec.quickChordsController.text = sec.chords
                              .map((c) => c.displayLabel)
                              .join(' ');
                        });
                        widget.onChordsUpdated();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Lyrics
            TextFormField(
              controller: sec.lyricsController,
              decoration: InputDecoration(
                labelText: l10n?.sectionLyricsLabel ?? 'Section Lyrics',
                hintText:
                    l10n?.sectionLyricsHint ?? 'Enter lyrics line by line...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // Rehearsal Notes
            TextFormField(
              controller: sec.notesController,
              decoration: InputDecoration(
                labelText:
                    l10n?.rehearsalNotesLabel ?? 'Rehearsal Notes (optional)',
                hintText:
                    l10n?.rehearsalNotesHint ??
                    'e.g. Guitar solo starts here...',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
