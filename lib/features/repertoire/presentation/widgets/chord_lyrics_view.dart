/// Battuta — Chord-Over-Lyrics Stage View Widget.
///
/// Renders song lyrics with chords floating directly over their corresponding
/// words in a stage-ready, high-contrast, responsive layout.
/// Also supports dedicated Lyrics Only and Chords Only stage display modes.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/chord_lyric_line.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_section.dart';
import 'package:battuta/features/repertoire/domain/entities/song_view_mode.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/widgets/karaoke_chord_alignment_modal.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

export 'package:battuta/features/repertoire/domain/entities/song_view_mode.dart';

/// Full lead-sheet view presenting song sections with selectable display modes:
/// - Both (Lyrics & Chords floating above words)
/// - Lyrics Only (Clean, distraction-free stage text for vocalists)
/// - Chords Only (Pure chord charts & progression blocks for instrumentalists)
class ChordLyricsView extends StatelessWidget {
  const ChordLyricsView({
    required this.song,
    required this.transpositionSemitones,
    this.viewMode = SongViewMode.both,
    super.key,
    this.onSongUpdated,
  });

  /// The song being displayed.
  final Song song;

  /// Active transposition in semitones (-12 to +12).
  final int transpositionSemitones;

  /// Current display mode (both, lyricsOnly, or chordsOnly).
  final SongViewMode viewMode;

  /// Callback when a section's chord alignment is edited and saved.
  final ValueChanged<Song>? onSongUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (song.sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n?.noSectionsYet ?? 'This song has no sections yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in song.sections)
          _SectionChordLyricsCard(
            key: ValueKey(section.id),
            section: section,
            transpositionSemitones: transpositionSemitones,
            viewMode: viewMode,
            onEditAlignment: () => _openAlignmentModal(context, section),
          ),
      ],
    );
  }

  void _openAlignmentModal(BuildContext context, SongSection section) {
    showModalBottomSheet<SongSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => KaraokeChordAlignmentModal(
        song: song,
        section: section,
      ),
    ).then((updatedSection) {
      if (updatedSection != null && onSongUpdated != null) {
        final updatedSections = song.sections.map((s) {
          return s.id == updatedSection.id ? updatedSection : s;
        }).toList();

        final updatedSong = song.copyWith(
          sections: updatedSections,
          updatedAt: DateTime.now(),
        );

        onSongUpdated!(updatedSong);
      }
    });
  }
}

/// A flush, stage-ready card displaying a single song section.
class _SectionChordLyricsCard extends StatelessWidget {
  const _SectionChordLyricsCard({
    required this.section,
    required this.transpositionSemitones,
    required this.viewMode,
    required this.onEditAlignment,
    super.key,
  });

  final SongSection section;
  final int transpositionSemitones;
  final SongViewMode viewMode;
  final VoidCallback onEditAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Transpose lyrics if transposed
    final effectiveLyrics = transpositionSemitones != 0 && section.lyrics != null
        ? SongTransposer.transposeChordProText(
            section.lyrics!,
            transpositionSemitones,
          )
        : (section.lyrics ?? '');

    // Transpose section chord cells if transposed
    final effectiveChords = transpositionSemitones != 0
        ? section.chords
            .map(
              (c) => SongTransposer.transposeChord(
                c,
                transpositionSemitones,
                preferSharps: true,
              ),
            )
            .toList()
        : section.chords;

    final parsedLines = ChordLyricsParser.parse(effectiveLyrics);
    final hasLyricsContent =
        parsedLines.isNotEmpty && parsedLines.any((l) => l.rawLyrics.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppTheme.slateBorder : AppTheme.pearlBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        section.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (section.repeatCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.amberAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.amberAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            l10n?.repeatTimes(section.repeatCount) ??
                                'Repeat ${section.repeatCount}×',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.amberAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Karaoke / Align Chords Button (only in Both mode)
                if (viewMode == SongViewMode.both)
                  OutlinedButton.icon(
                    key: ValueKey('align_chords_btn_${section.id}'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: AppTheme.amberAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    icon: const Icon(
                      Icons.mic_external_on,
                      size: 15,
                      color: AppTheme.amberAccent,
                    ),
                    label: Text(
                      l10n?.alignChordsAction ?? 'Align Chords',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.amberAccent,
                      ),
                    ),
                    onPressed: onEditAlignment,
                  ),
              ],
            ),

            if (section.rehearsalNotes != null &&
                section.rehearsalNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                section.rehearsalNotes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Mode-Specific Body ──
            if (viewMode == SongViewMode.lyricsOnly)
              _buildLyricsOnlyBody(
                context,
                parsedLines,
                hasLyricsContent,
                isDark,
              )
            else if (viewMode == SongViewMode.chordsOnly)
              _buildChordsOnlyBody(
                context,
                effectiveChords,
                effectiveLyrics,
                isDark,
              )
            else
              _buildBothBody(
                context,
                parsedLines,
                effectiveChords,
                isDark,
              ),
          ],
        ),
      ),
    );
  }

  // ── Lyrics Only: Clean, legible stage text without chords ──
  Widget _buildLyricsOnlyBody(
    BuildContext context,
    List<ChordLyricLine> parsedLines,
    bool hasLyricsContent,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (!hasLyricsContent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.slateSurfaceLight
              : AppTheme.pearlSurfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.music_note,
              size: 18,
              color: AppTheme.amberAccent,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.instrumentalSection ?? 'Instrumental (No lyrics)',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in parsedLines)
          if (line.rawLyrics.isEmpty)
            const SizedBox(height: 12)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Text(
                line.rawLyrics,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textOffWhite : AppTheme.charcoalText,
                ),
              ),
            ),
      ],
    );
  }

  // ── Chords Only: Pure chord progression blocks without lyrics ──
  Widget _buildChordsOnlyBody(
    BuildContext context,
    List<ChordCell> effectiveChords,
    String effectiveLyrics,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Prefer structured chord progression cells
    if (effectiveChords.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final chord in effectiveChords)
            _ChordBlockCard(
              chordLabel: chord.displayLabel,
              beats: chord.beats,
              isDark: isDark,
            ),
        ],
      );
    }

    // Fallback: extracted bracket chords from lyrics
    final extractedChords = ChordLyricsParser.extractChords(effectiveLyrics);
    if (extractedChords.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final chord in extractedChords)
            _ChordBlockCard(
              chordLabel: chord,
              beats: null,
              isDark: isDark,
            ),
        ],
      );
    }

    // No chords found
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.slateSurfaceLight
            : AppTheme.pearlSurfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_off,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            l10n?.noChordsForSection ?? 'No chords entered for this section.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Both: Interactive Chords floating over words ──
  Widget _buildBothBody(
    BuildContext context,
    List<ChordLyricLine> parsedLines,
    List<ChordCell> effectiveChords,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasContent = parsedLines.isNotEmpty;

    if (!hasContent) {
      // If lyrics are absent but section has chords, display chord progression
      if (effectiveChords.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chord in effectiveChords)
                  _ChordBlockCard(
                    chordLabel: chord.displayLabel,
                    beats: chord.beats,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.slateSurfaceLight
              : AppTheme.pearlSurfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.queue_music,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.noLyricsForSection ??
                    'No lyrics or chord alignment for this section yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  l10n?.alignChordsAction ?? 'Align Chords',
                ),
                onPressed: onEditAlignment,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < parsedLines.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ChordLyricLineRow(line: parsedLines[i]),
        ],
      ],
    );
  }
}

/// Displays a high-contrast chord badge for chords-only view.
class _ChordBlockCard extends StatelessWidget {
  const _ChordBlockCard({
    required this.chordLabel,
    this.beats,
    required this.isDark,
  });

  final String chordLabel;
  final int? beats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.slateSurfaceLight
            : AppTheme.pearlSurfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.amberAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chordLabel,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.amberAccent,
            ),
          ),
          if (beats != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n?.beatsCount(beats!) ?? '$beats beats',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders a single lyric line with responsive word-wrapped chords.
class _ChordLyricLineRow extends StatelessWidget {
  const _ChordLyricLineRow({required this.line});

  final ChordLyricLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (line.tokens.isEmpty) {
      return const SizedBox(height: 10);
    }

    final hasAnyChordInLine = line.hasChords;

    return Wrap(
      spacing: 0,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in line.tokens)
          _ChordWordPair(
            token: token,
            reserveChordSpace: hasAnyChordInLine,
            isDark: isDark,
          ),
      ],
    );
  }
}

/// Displays an individual word/syllable and its attached chord floating above.
class _ChordWordPair extends StatelessWidget {
  const _ChordWordPair({
    required this.token,
    required this.reserveChordSpace,
    required this.isDark,
  });

  final ChordLyricToken token;
  final bool reserveChordSpace;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chord = token.chord?.trim();
    final hasChord = chord != null && chord.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(right: token.trailingSpace ? 6.0 : 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chord floating above
          if (reserveChordSpace)
            SizedBox(
              height: 20,
              child: hasChord
                  ? Text(
                      chord,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.amberAccent,
                        letterSpacing: 0.5,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

          // Lyric word below
          Text(
            token.word,
            style: TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textOffWhite : AppTheme.charcoalText,
            ),
          ),
        ],
      ),
    );
  }
}
