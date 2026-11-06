/// Song editor page — create or edit a song's metadata and sections.
///
/// Provides a comprehensive form for managing song properties, time signature,
/// tempo with tap-tempo capability, tags, notes, and a dynamic section builder
/// with chord chart parsing, reordering, and lyrics.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/entities/musical_key.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A full-featured form page for creating or editing a song.
///
/// When [songId] is null, operates in creation mode.
/// When [songId] is provided, loads existing data from the database.
class SongEditorPage extends ConsumerStatefulWidget {
  /// Creates a [SongEditorPage].
  const SongEditorPage({this.songId, super.key});

  /// The ID of the song to edit, or null for creating a new song.
  final String? songId;

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

    if (widget.songId == null) {
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
    _tapTimestamps.removeWhere(
      (t) => now.difference(t).inMilliseconds > 3000,
    );

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

  void _addSection([String defaultName = 'New Section']) {
    setState(() {
      _sections.add(
        _EditableSection(
          id: 'sec_${DateTime.now().millisecondsSinceEpoch}_${_sections.length}',
          name: defaultName,
          chords: [],
          lyrics: '',
          repeatCount: 1,
        ),
      );
    });
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

  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final songId = widget.songId ??
          'song_${DateTime.now().millisecondsSinceEpoch}';

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
      );

      final notifier = ref.read(repertoireProvider.notifier);
      if (widget.songId != null) {
        await notifier.updateSong(song);
      } else {
        await notifier.addSong(song);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.songId != null
                  ? 'Song "${song.title}" updated successfully'
                  : 'Song "${song.title}" created successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save song: $e'),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text(
          'Are you sure you want to delete "${_titleController.text}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(repertoireProvider.notifier).deleteSong(widget.songId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted')),
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
    final theme = Theme.of(context);
    final isEditing = widget.songId != null;

    if (isEditing && !_initialized) {
      final songAsync = ref.watch(songByIdProvider(widget.songId!));
      return songAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Song')),
          body: Center(child: Text('Error loading song: $err')),
        ),
        data: (song) {
          if (song == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Song')),
              body: const Center(child: Text('Song not found')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Song' : 'New Song'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Song',
              onPressed: _isSaving ? null : _confirmDelete,
            ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveSong,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Primary Metadata ──
            TextFormField(
              key: const Key('song_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title *',
                hintText: 'e.g. Amazing Grace',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a song title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('song_artist_field'),
              controller: _artistController,
              decoration: const InputDecoration(
                labelText: 'Artist / Composer *',
                hintText: 'e.g. John Newton',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an artist or composer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Musical Attributes (Key, Tempo, Meter) ──
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Musical Setup',
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
                            initialValue: MusicalKey.allKeys
                                    .any((k) => k.name == _selectedKey)
                                ? _selectedKey
                                : MusicalKey.cMajor.name,
                            decoration: const InputDecoration(
                              labelText: 'Key',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: MusicalKey.allKeys.map((k) {
                              return DropdownMenuItem(
                                value: k.name,
                                child: Text(
                                  k.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                            initialValue: _timeSignature,
                            decoration: const InputDecoration(
                              labelText: 'Meter',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _supportedTimeSignatures.map((sig) {
                              final (num, den) = sig;
                              return DropdownMenuItem(
                                value: sig,
                                child: Text('$num/$den'),
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
                                tooltip: 'Decrease BPM',
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
                                tooltip: 'Increase BPM',
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
                          label: const Text('Tap Tempo'),
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
                    decoration: const InputDecoration(
                      labelText: 'Add Tag',
                      hintText: 'e.g. worship, rock, ballad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                  tooltip: 'Add Tag',
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
              decoration: const InputDecoration(
                labelText: 'Notes / Performance Instructions',
                hintText: 'e.g. Capo 3rd fret, slow acoustic intro...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Sections Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Song Sections (${_sections.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Section'),
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
                  const Text('Quick add: ', style: TextStyle(fontSize: 12)),
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
                    'No sections added. Tap "+ Add Section" to build your song.',
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
                    onMoveUp: index > 0 ? () => _moveSection(index, index - 1) : null,
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
  })  : nameController = TextEditingController(text: name),
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
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChordsUpdated,
  });

  final int index;
  final int totalSections;
  final _EditableSection section;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onChordsUpdated;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  void _applyQuickChords() {
    final text = widget.section.quickChordsController.text;
    final parsed = ChordParser.parseProgression(text);
    setState(() {
      widget.section.chords = parsed;
    });
    widget.onChordsUpdated();
  }

  void _showAddChordDialog() {
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
              title: const Text('Add Chord'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: root,
                      decoration: const InputDecoration(labelText: 'Root Note'),
                      items: const [
                        'C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'F',
                        'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B',
                      ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => root = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ChordQuality>(
                      initialValue: quality,
                      decoration: const InputDecoration(labelText: 'Quality'),
                      items: ChordQuality.values
                          .map((q) => DropdownMenuItem(
                                value: q,
                                child: Text('${q.displayName} (${q.symbol})'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => quality = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: bass,
                      decoration: const InputDecoration(
                        labelText: 'Bass Note (Slash Chord)',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B']
                            .map((b) => DropdownMenuItem(value: b, child: Text(b))),
                      ],
                      onChanged: (val) => setDialogState(() => bass = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Beats: '),
                        for (final b in [1, 2, 3, 4, 6])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('$b'),
                              selected: beats == b,
                              onSelected: (_) => setDialogState(() => beats = b),
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
                  child: const Text('Cancel'),
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
                      widget.section.quickChordsController.text =
                          widget.section.chords.map((c) => c.displayLabel).join(' ');
                    });
                    widget.onChordsUpdated();
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Add'),
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
    final sec = widget.section;

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
                    decoration: const InputDecoration(
                      labelText: 'Section Name',
                      isDense: true,
                      border: UnderlineInputBorder(),
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
                      tooltip: 'Decrease repeats',
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
                      tooltip: 'Increase repeats',
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
                    tooltip: 'Move up',
                    onPressed: widget.onMoveUp,
                  ),
                if (widget.onMoveDown != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    tooltip: 'Move down',
                    onPressed: widget.onMoveDown,
                  ),

                // Delete Section
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                  tooltip: 'Delete Section',
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chord Progression Editor Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sec.quickChordsController,
                    decoration: InputDecoration(
                      labelText: 'Chords (e.g. C | G/B | Am | F)',
                      hintText: 'Type chord symbols separated by spaces or bars',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Apply chords text',
                        onPressed: _applyQuickChords,
                      ),
                    ),
                    onSubmitted: (_) => _applyQuickChords(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.music_note),
                  tooltip: 'Add chord builder',
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
                          sec.quickChordsController.text =
                              sec.chords.map((c) => c.displayLabel).join(' ');
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
              decoration: const InputDecoration(
                labelText: 'Section Lyrics',
                hintText: 'Enter lyrics line by line...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // Rehearsal Notes
            TextFormField(
              controller: sec.notesController,
              decoration: const InputDecoration(
                labelText: 'Rehearsal Notes (optional)',
                hintText: 'e.g. Guitar solo starts here...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
