/// Section editor card used by the song editor page.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_quality.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Mutable editing state of one song section: its text controllers, chords
/// and repeat count. Owned and disposed by the song editor page.
class EditableSection {
  EditableSection({
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

  EditableSection clone({String? newId, String? newName}) {
    return EditableSection(
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

/// One section of the song being edited: name, repeat count, reorder and
/// copy tools, chord progression, lyrics and rehearsal notes.
class SongEditorSectionCard extends StatefulWidget {
  const SongEditorSectionCard({
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
  final EditableSection section;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<EditableSection> onCopyFrom;
  final List<EditableSection> otherSections;
  final EditableSection? Function(String name) onFindPreviousMatch;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onChordsUpdated;

  @override
  State<SongEditorSectionCard> createState() => _SongEditorSectionCardState();
}

class _SongEditorSectionCardState extends State<SongEditorSectionCard> {
  @override
  void initState() {
    super.initState();
    widget.section.nameController.addListener(_onNameChanged);
  }

  @override
  void didUpdateWidget(SongEditorSectionCard oldWidget) {
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
    final brand = BattutaBrand.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final sec = widget.section;
    final previousMatch = widget.onFindPreviousMatch(sec.nameController.text);
    final title = sec.nameController.text.trim().isEmpty
        ? (l10n?.sectionName ?? 'Section Name')
        : sec.nameController.text.trim();
    final hasCopySource = widget.otherSections.any(
      (s) => s.chords.isNotEmpty || s.lyricsController.text.isNotEmpty,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: BattutaSpace.md),
      child: StageCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: section label, repeat stepper and tools.
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 0,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: BattutaSpace.minTouchTarget,
                      maxWidth: 180,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: brand.accentInk,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToolButton(
                        icon: Icons.remove_circle_outline,
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
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _ToolButton(
                        icon: Icons.add_circle_outline,
                        tooltip: l10n?.increaseRepeats ?? 'Increase repeats',
                        onPressed: () {
                          setState(() => sec.repeatCount++);
                          widget.onChordsUpdated();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onMoveUp != null)
                        _ToolButton(
                          icon: Icons.arrow_upward,
                          tooltip: l10n?.moveUp ?? 'Move up',
                          onPressed: widget.onMoveUp,
                        ),
                      if (widget.onMoveDown != null)
                        _ToolButton(
                          icon: Icons.arrow_downward,
                          tooltip: l10n?.moveDown ?? 'Move down',
                          onPressed: widget.onMoveDown,
                        ),
                      _ToolButton(
                        icon: Icons.copy_rounded,
                        tooltip: l10n?.duplicateSection ?? 'Duplicate section',
                        onPressed: widget.onDuplicate,
                      ),
                      if (hasCopySource)
                        PopupMenuButton<EditableSection>(
                          icon: const Icon(Icons.content_copy, size: 20),
                          iconColor: brand.inkMuted,
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
                                  return PopupMenuItem<EditableSection>(
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
                      _ToolButton(
                        icon: Icons.delete_outline,
                        color: brand.danger,
                        tooltip: l10n?.deleteSection ?? 'Delete Section',
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: brand.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: sec.nameController,
                    decoration: InputDecoration(
                      labelText: l10n?.sectionName ?? 'Section Name',
                    ),
                  ),

                  // Pre-load helper chip when the section is empty and a
                  // previous section has the same name.
                  if (previousMatch != null &&
                      sec.chords.isEmpty &&
                      sec.lyricsController.text.trim().isEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: brand.accentInk,
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

                  // Chord progression editor.
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sec.quickChordsController,
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFontFamily,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                l10n?.chordsFieldLabel ??
                                'Chords (e.g. C | G/B | Am | F)',
                            hintText: l10n?.chordsFieldHint ?? 'Type chord symbols separated by spaces or bars',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip:
                                  l10n?.applyChordsTooltip ??
                                  'Apply chords text',
                              onPressed: _applyQuickChords,
                            ),
                          ),
                          onSubmitted: (_) => _applyQuickChords(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.music_note),
                        tooltip:
                            l10n?.addChordBuilderTooltip ?? 'Add chord builder',
                        onPressed: _showAddChordDialog,
                      ),
                    ],
                  ),

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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: brand.accentWash,
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

                  TextFormField(
                    controller: sec.lyricsController,
                    decoration: InputDecoration(
                      labelText: l10n?.sectionLyricsLabel ?? 'Section Lyrics',
                      hintText:
                          l10n?.sectionLyricsHint ??
                          'Enter lyrics line by line...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: sec.notesController,
                    decoration: InputDecoration(
                      labelText:
                          l10n?.rehearsalNotesLabel ??
                          'Rehearsal Notes (optional)',
                      hintText:
                          l10n?.rehearsalNotesHint ??
                          'e.g. Guitar solo starts here...',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 44 pt icon tool in the section header.
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color ?? brand.inkMuted,
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: BattutaSpace.minTouchTarget,
        minHeight: BattutaSpace.minTouchTarget,
      ),
      onPressed: onPressed,
    );
  }
}
