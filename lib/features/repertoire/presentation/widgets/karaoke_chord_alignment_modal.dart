/// Battuta — Karaoke Chord-to-Word Alignment Modal & Editor.
///
/// An interactive music chart editor enabling musicians and worship leaders
/// to dock chords directly onto lyric words with a single tap, distribute chords
/// evenly, or stamp chords in real time like karaoke as the song progresses.
library;

import 'dart:async';

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_lyric_line.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet for interactive chord-to-word karaoke alignment.
class KaraokeChordAlignmentModal extends StatefulWidget {
  const KaraokeChordAlignmentModal({
    required this.song,
    required this.section,
    super.key,
  });

  final Song song;
  final SongSection section;

  @override
  State<KaraokeChordAlignmentModal> createState() =>
      _KaraokeChordAlignmentModalState();
}

class _KaraokeChordAlignmentModalState
    extends State<KaraokeChordAlignmentModal> {
  late List<ChordLyricLine> _lines;
  late TextEditingController _textController;
  late List<String> _availableChords;

  int _selectedTab = 0; // 0: Visual Tap / Karaoke, 1: ChordPro Text
  String? _selectedChord;
  bool _isEraserActive = false;

  // Live Karaoke Cue Mode state
  bool _isCueActive = false;
  Timer? _cueTimer;
  int _cueLineIndex = 0;
  int _cueTokenIndex = 0;
  ToneSynthesizer? _tickSynth;

  @override
  void initState() {
    super.initState();
    final initialLyrics = widget.section.lyrics ?? '';
    _lines = ChordLyricsParser.parse(initialLyrics);
    _textController = TextEditingController(text: initialLyrics);

    // Collect initial chords from section.chords and any existing in lyrics
    final chordSet = <String>{};
    for (final c in widget.section.chords) {
      if (c.displayLabel.isNotEmpty) {
        chordSet.add(c.displayLabel);
      }
    }
    for (final line in _lines) {
      for (final t in line.tokens) {
        if (t.hasChord) {
          chordSet.add(t.chord!.trim());
        }
      }
    }
    if (chordSet.isEmpty) {
      chordSet.addAll(['G', 'C', 'Em', 'D']);
    }
    _availableChords = chordSet.toList();
    _selectedChord = _availableChords.firstOrNull;
  }

  @override
  void dispose() {
    _cueTimer?.cancel();
    _tickSynth?.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _syncFromText() {
    final parsed = ChordLyricsParser.parse(_textController.text);
    setState(() {
      _lines = parsed;
    });
  }

  void _syncToText() {
    final text = ChordLyricsParser.toChordPro(_lines);
    _textController.text = text;
  }

  void _onWordTapped(int lineIdx, int tokenIdx) {
    if (lineIdx >= _lines.length) return;
    final line = _lines[lineIdx];
    if (tokenIdx >= line.tokens.length) return;

    final token = line.tokens[tokenIdx];
    final updatedTokens = List<ChordLyricToken>.from(line.tokens);

    if (_isEraserActive) {
      // Remove chord
      updatedTokens[tokenIdx] = token.copyWith(clearChord: true);
    } else if (_selectedChord != null) {
      // Place selected chord
      updatedTokens[tokenIdx] = token.copyWith(chord: _selectedChord);
    }

    setState(() {
      _lines[lineIdx] = ChordLyricLine(tokens: updatedTokens);
      _syncToText();
    });
  }

  void _autoDistributeChords() {
    final currentText = ChordLyricsParser.stripChords(_textController.text);
    if (currentText.trim().isEmpty) return;

    final distributed = ChordLyricsParser.autoDistribute(
      plainLyrics: currentText,
      chords: _availableChords,
    );

    setState(() {
      _textController.text = distributed;
      _lines = ChordLyricsParser.parse(distributed);
    });
  }

  void _clearAllChords() {
    final stripped = ChordLyricsParser.stripChords(_textController.text);
    setState(() {
      _textController.text = stripped;
      _lines = ChordLyricsParser.parse(stripped);
    });
  }

  void _showAddCustomChordDialog() {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.addChordLabel ?? 'Add Chord to Palette'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Chord (e.g. G/B, Dsus4, C#m7)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty && !_availableChords.contains(val)) {
                setState(() {
                  _availableChords.add(val);
                  _selectedChord = val;
                  _isEraserActive = false;
                });
              }
              Navigator.of(ctx).pop();
            },
            child: Text(l10n?.save ?? 'Add'),
          ),
        ],
      ),
    );
  }

  void _toggleLiveCueMode() {
    if (_isCueActive) {
      _stopLiveCueMode();
    } else {
      _startLiveCueMode();
    }
  }

  void _startLiveCueMode() {
    if (_lines.isEmpty) return;
    _tickSynth ??= ToneSynthesizer();
    final bpm = widget.song.tempo > 0 ? widget.song.tempo : 90;
    final intervalMs = (60000 / bpm).round();

    setState(() {
      _isCueActive = true;
      _cueLineIndex = 0;
      _cueTokenIndex = 0;
    });

    _cueTimer?.cancel();
    _cueTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_isCueActive || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final currentLine = _lines[_cueLineIndex];
        if (_cueTokenIndex + 1 < currentLine.tokens.length) {
          _cueTokenIndex++;
        } else {
          // Advance to next line
          if (_cueLineIndex + 1 < _lines.length) {
            _cueLineIndex++;
            _cueTokenIndex = 0;
          } else {
            // Loop back to start
            _cueLineIndex = 0;
            _cueTokenIndex = 0;
          }
        }
      });
    });
  }

  void _stopLiveCueMode() {
    _cueTimer?.cancel();
    setState(() {
      _isCueActive = false;
    });
  }

  void _stampChordOnActiveCue(String chord) {
    if (!_isCueActive) return;
    _onWordTapped(_cueLineIndex, _cueTokenIndex);
  }

  void _saveAndClose() {
    final chordProResult = ChordLyricsParser.toChordPro(_lines);
    final updatedSection = widget.section.copyWith(lyrics: chordProResult);
    Navigator.of(context).pop(updatedSection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slateSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.karaokeAlignTitle ?? 'Karaoke Chord Alignment',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.section.name} • ${l10n?.karaokeAlignSubtitle ?? "Tap a chord, then tap the target word."}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Segment Switcher (Visual Tap vs ChordPro Text) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.touch_app, size: 16),
                  label: Text(l10n?.visualTapMode ?? 'Visual Tap / Karaoke'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.code, size: 16),
                  label: Text(l10n?.chordProTextMode ?? 'ChordPro Text'),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (val) {
                final newTab = val.first;
                if (newTab == 0 && _selectedTab == 1) {
                  _syncFromText();
                } else if (newTab == 1 && _selectedTab == 0) {
                  _syncToText();
                }
                setState(() => _selectedTab = newTab);
              },
            ),
          ),

          const Divider(height: 1),

          // ── Editor Body ──
          Expanded(
            child: _selectedTab == 0
                ? _buildVisualKaraokeTab(theme, isDark, l10n)
                : _buildTextEditorTab(theme, isDark, l10n),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              mediaQuery.padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.obsidian : AppTheme.pearlBackground,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                FilledButton.icon(
                  key: const ValueKey('save_alignment_btn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.amberAccent,
                    foregroundColor: AppTheme.obsidianText,
                    minimumSize: const Size(120, 44),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n?.save ?? 'Save Alignment'),
                  onPressed: _saveAndClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualKaraokeTab(
    ThemeData theme,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        // ── Chord Palette & Cue Controls ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.chordPalette ?? 'Chord Palette',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppTheme.textMuted : AppTheme.charcoalMuted,
                    ),
                  ),
                  // Live Cue Button
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _isCueActive
                          ? AppTheme.stageRed.withValues(alpha: 0.2)
                          : AppTheme.amberAccent.withValues(alpha: 0.15),
                      foregroundColor: _isCueActive
                          ? AppTheme.stageRed
                          : AppTheme.amberAccent,
                    ),
                    icon: Icon(
                      _isCueActive ? Icons.stop : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      _isCueActive
                          ? (l10n?.stopCueMode ?? 'Stop Cue')
                          : (l10n?.liveCueMode ?? 'Live Cue (${widget.song.tempo > 0 ? widget.song.tempo : 90} BPM)'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _toggleLiveCueMode,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Chord Chips
                    for (final chord in _availableChords) ...[
                      ChoiceChip(
                        key: ValueKey('palette_chord_$chord'),
                        label: Text(
                          chord,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: _selectedChord == chord && !_isEraserActive
                                ? AppTheme.obsidianText
                                : AppTheme.amberAccent,
                          ),
                        ),
                        selected: _selectedChord == chord && !_isEraserActive,
                        selectedColor: AppTheme.amberAccent,
                        backgroundColor:
                            AppTheme.amberAccent.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: _selectedChord == chord && !_isEraserActive
                              ? AppTheme.amberAccent
                              : AppTheme.amberAccent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedChord = chord;
                              _isEraserActive = false;
                            });
                            _stampChordOnActiveCue(chord);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Add Custom Chord Button
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      tooltip: l10n?.addChordLabel ?? 'Add Chord',
                      color: AppTheme.amberAccent,
                      onPressed: _showAddCustomChordDialog,
                    ),

                    const SizedBox(width: 6),

                    // Eraser Tool
                    ChoiceChip(
                      key: const ValueKey('palette_eraser'),
                      avatar: const Icon(Icons.backspace_outlined, size: 14),
                      label: Text(l10n?.eraserMode ?? 'Eraser'),
                      selected: _isEraserActive,
                      selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setState(() {
                          _isEraserActive = selected;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Assistant Helpers Row (Auto-distribute / Clear)
              const SizedBox(height: 6),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 13),
                    label: Text(
                      l10n?.autoAlignAction ?? 'Auto Distribute',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: _autoDistributeChords,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.clear_all, size: 14),
                    label: Text(
                      l10n?.clearChordsAction ?? 'Clear Chords',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: _clearAllChords,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Interactive Lyric Lines (Tap to place) ──
        Expanded(
          child: _lines.isEmpty
              ? Center(
                  child: Text(
                    l10n?.noLyricsForSection ?? 'No lyrics for this section.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lines.length,
                  itemBuilder: (context, lineIdx) {
                    final line = _lines[lineIdx];
                    if (line.tokens.isEmpty) {
                      return const SizedBox(height: 14);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        children: [
                          for (var tIdx = 0;
                              tIdx < line.tokens.length;
                              tIdx++)
                            _buildInteractiveWordChip(
                              lineIdx: lineIdx,
                              tokenIdx: tIdx,
                              token: line.tokens[tIdx],
                              theme: theme,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInteractiveWordChip({
    required int lineIdx,
    required int tokenIdx,
    required ChordLyricToken token,
    required ThemeData theme,
    required bool isDark,
  }) {
    final hasChord = token.hasChord;
    final isCueActiveForWord =
        _isCueActive && lineIdx == _cueLineIndex && tokenIdx == _cueTokenIndex;

    return InkWell(
      key: ValueKey('word_chip_${lineIdx}_$tokenIdx'),
      onTap: () => _onWordTapped(lineIdx, tokenIdx),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCueActiveForWord
              ? AppTheme.amberAccent.withValues(alpha: 0.3)
              : hasChord
                  ? AppTheme.amberAccent.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCueActiveForWord
                ? AppTheme.amberAccent
                : hasChord
                    ? AppTheme.amberAccent.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isCueActiveForWord ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chord Tag (Top)
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: hasChord
                  ? BoxDecoration(
                      color: AppTheme.amberAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                hasChord ? token.chord! : '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.amberAccent,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Lyric Word (Bottom)
            Text(
              token.word.isEmpty ? '—' : token.word,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCueActiveForWord ? FontWeight.bold : FontWeight.w500,
                color: isDark ? AppTheme.obsidianText : AppTheme.charcoalText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditorTab(
    ThemeData theme,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.chordProEditorInstructions ??
                'Edit ChordPro notation directly. Enclose chords in brackets before words: [G]Amazing [C]grace',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              key: const ValueKey('chordpro_raw_text_field'),
              controller: _textController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '[G]Amazing [C]grace how [G]sweet the sound...',
              ),
              onChanged: (_) => _syncFromText(),
            ),
          ),
        ],
      ),
    );
  }
}
