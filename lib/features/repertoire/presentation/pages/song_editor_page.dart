/// Song editor page — create or edit a song's metadata and sections.
///
/// Provides a comprehensive form for managing song properties, time signature,
/// tempo with tap-tempo capability, tags, notes, and a dynamic section builder
/// with chord chart parsing, reordering, and lyrics.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/song_editor_section_card.dart';
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
  final List<EditableSection> _sections = [];

  bool _initialized = false;
  bool _isSaving = false;
  Song? _originalSong;

  /// The existing song a new version is attached to (picked from the
  /// suggestions); null keeps what was typed as a new song.
  SongSuggestion? _linked;

  // Tap-tempo timestamp tracker
  final List<DateTime> _tapTimestamps = [];

  /// Beat dots shown under the tap-tempo button.
  static const int _tapDotCount = 8;

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
        EditableSection(
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
        EditableSection(
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
        EditableSection(
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
    setState(() {});

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

  EditableSection? _findPreviousSection(String name, [int? beforeIndex]) {
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

    final newSection = EditableSection(
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

  void _copySectionContent(int targetIndex, EditableSection source) {
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
    final brand = BattutaBrand.of(context);
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
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BattutaRadius.sm + 2),
              ),
            ),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BattutaSpace.lg,
                BattutaSpace.sm,
                BattutaSpace.lg,
                BattutaSpace.xxl,
              ),
              children: [
                if (!canEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BattutaSpace.md),
                    child: StageCard(
                      padding: const EdgeInsets.all(BattutaSpace.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: brand.accentInk,
                          ),
                          const SizedBox(width: BattutaSpace.sm),
                          Expanded(
                            child: Text(
                              l10n?.readOnlyVersionEditorNotice ??
                                  'Only the owner can edit this version.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: brand.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                const SizedBox(height: BattutaSpace.md),
                TextFormField(
                  key: const Key('song_artist_field'),
                  controller: _artistController,
                  readOnly: fieldsLocked,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.artistComposerLabel ?? 'Artist / Composer *',
                    hintText: l10n?.artistComposerHint ?? 'e.g. John Newton',
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
                    padding: const EdgeInsets.only(top: BattutaSpace.md),
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
                    padding: const EdgeInsets.only(top: BattutaSpace.md),
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
                const SizedBox(height: BattutaSpace.lg),

                // ── Musical Attributes (Key, Meter, Tempo) ──
                StageSectionHeader(
                  title: l10n?.musicalSetup ?? 'Musical Setup',
                  padding: const EdgeInsets.only(bottom: BattutaSpace.sm),
                ),
                _buildKeyMeterRow(l10n),
                const SizedBox(height: BattutaSpace.md),
                _buildTempoCard(theme, brand, l10n),
                const SizedBox(height: BattutaSpace.lg),

                // ── Tags ──
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('song_tag_input'),
                        controller: _tagInputController,
                        decoration: InputDecoration(
                          labelText: l10n?.addTag ?? 'Add Tag',
                          hintText:
                              l10n?.tagHint ?? 'e.g. worship, rock, ballad',
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: BattutaSpace.sm),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      tooltip: l10n?.addTag ?? 'Add Tag',
                      constraints: const BoxConstraints(
                        minWidth: BattutaSpace.minTouchTarget,
                        minHeight: BattutaSpace.minTouchTarget,
                      ),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: BattutaSpace.sm),
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
                const SizedBox(height: BattutaSpace.lg),

                // ── Notes ──
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.notesInstructionsLabel ??
                        'Notes / Performance Instructions',
                    hintText:
                        l10n?.notesInstructionsHint ??
                        'e.g. Capo 3rd fret, slow acoustic intro...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: BattutaSpace.xl),

                // ── Sections header ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n?.songSectionsCount(_sections.length) ??
                            'Song Sections (${_sections.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          BattutaSpace.minTouchTarget,
                          BattutaSpace.minTouchTarget,
                        ),
                        foregroundColor: brand.accentInk,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n?.addSection ?? 'Add Section'),
                      onPressed: () => _addSection(),
                    ),
                  ],
                ),
                const SizedBox(height: BattutaSpace.sm),

                // Quick Section Templates
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        l10n?.quickAdd ?? 'Quick add: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: brand.inkMuted,
                        ),
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
                                ? Icon(
                                    Icons.replay,
                                    size: 14,
                                    color: brand.accentInk,
                                  )
                                : null,
                            label: Text(name),
                            onPressed: () => _addSection(name),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: BattutaSpace.md),

                // Section Cards
                if (_sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(BattutaSpace.xl),
                    child: Center(
                      child: Text(
                        l10n?.noSectionsAddedHint ?? 'No sections added. Tap "+ Add Section" to build your song.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: brand.inkMuted,
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
                      return SongEditorSectionCard(
                        key: ValueKey(section.id),
                        index: index,
                        totalSections: _sections.length,
                        section: section,
                        onDelete: () => _removeSection(index),
                        onDuplicate: () => _duplicateSection(index),
                        onCopyFrom: (source) =>
                            _copySectionContent(index, source),
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

                Text(
                  l10n?.chordEntryHint ??
                      'Type chords as symbols separated by spaces or bars, '
                          'like C G/B Am F.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Key (mono, amber) and meter selectors side by side.
  Widget _buildKeyMeterRow(AppLocalizations? l10n) {
    final brand = BattutaBrand.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const Key('song_key_dropdown'),
            isExpanded: true,
            initialValue: MusicalKey.allKeys.any((k) => k.name == _selectedKey)
                ? _selectedKey
                : MusicalKey.cMajor.name,
            decoration: InputDecoration(labelText: l10n?.keyLabel ?? 'Key'),
            items: MusicalKey.allKeys.map((k) {
              return DropdownMenuItem(
                value: k.name,
                child: Text(
                  k.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFontFamily,
                    fontWeight: FontWeight.w700,
                    color: brand.accentInk,
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
        const SizedBox(width: BattutaSpace.sm),
        Expanded(
          child: DropdownButtonFormField<(int, int)>(
            key: const Key('song_meter_dropdown'),
            isExpanded: true,
            initialValue: _timeSignature,
            decoration: InputDecoration(labelText: l10n?.meterLabel ?? 'Meter'),
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
    );
  }

  /// Tempo stepper plus the round tap-tempo button and its beat dots.
  Widget _buildTempoCard(
    ThemeData theme,
    BattutaBrand brand,
    AppLocalizations? l10n,
  ) {
    final taps = _tapTimestamps.length.clamp(0, _tapDotCount);
    return StageCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.tapTempo ?? 'Tap Tempo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.tapTempoHint ??
                      'Tap along with the beat. Wait 3 seconds to start over.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
                const SizedBox(height: BattutaSpace.sm),
                Row(
                  children: [
                    _TempoStepButton(
                      icon: Icons.remove,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _TempoStepButton(
                      icon: Icons.add,
                      tooltip: l10n?.increaseBpm ?? 'Increase BPM',
                      onPressed: () {
                        if (_tempo < 300) {
                          setState(() => _tempo++);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: BattutaSpace.sm),
                ExcludeSemantics(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < _tapDotCount; i++)
                        Container(
                          width: 18,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < taps ? brand.accent : brand.cardRaised,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: BattutaSpace.md),
          Tooltip(
            message: l10n?.tapTempo ?? 'Tap Tempo',
            child: BattutaPressable(
              key: const Key('song_tap_tempo_button'),
              onTap: _recordTapTempo,
              semanticLabel: l10n?.tapTempo ?? 'Tap Tempo',
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brand.accentWash,
                  border: Border.all(color: brand.accent, width: 2),
                ),
                child: Text(
                  l10n?.tapButtonLabel ?? 'TAP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: brand.accentInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 44 pt tonal stepper button for the tempo control.
class _TempoStepButton extends StatelessWidget {
  const _TempoStepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(icon),
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: BattutaSpace.minTouchTarget,
        minHeight: BattutaSpace.minTouchTarget,
      ),
      onPressed: onPressed,
    );
  }
}
