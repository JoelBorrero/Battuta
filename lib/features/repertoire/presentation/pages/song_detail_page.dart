/// Song detail page — displays a full song with sections, chords, and metadata.
///
/// This page provides the complete interactive lead sheet view for a song,
/// supporting real-time key transposition, PDF lead sheet printing/exporting,
/// MIDI generation, and direct navigation to edit or delete.
library;

import 'package:battuta/features/repertoire/domain/entities/chord_cell.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/score/data/services/midi_file_exporter.dart';
import 'package:battuta/features/score/data/services/pdf_lead_sheet_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Displays the full detail view of a song.
class SongDetailPage extends ConsumerStatefulWidget {
  /// Creates a [SongDetailPage] for the given [songId].
  const SongDetailPage({required this.songId, super.key});

  /// The unique identifier of the song to display.
  final String songId;

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  int _transpositionSemitones = 0;
  bool _isExporting = false;

  void _showTransposeDialog(Song originalSong) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final transposedSong = SongTransposer.transposeSong(
              originalSong,
              _transpositionSemitones,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transpose Song',
                        style: Theme.of(modalCtx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: _transpositionSemitones == 0
                            ? null
                            : () {
                                setModalState(() => _transpositionSemitones = 0);
                                setState(() {});
                              },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(modalCtx)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            transposedSong.key,
                            style: Theme.of(modalCtx)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(modalCtx)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          Text(
                            _transpositionSemitones == 0
                                ? 'Original Key'
                                : '${_transpositionSemitones > 0 ? "+" : ""}$_transpositionSemitones semitones',
                            style: Theme.of(modalCtx).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        tooltip: 'Down 1 semitone',
                        onPressed: () {
                          setModalState(() => _transpositionSemitones--);
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Up 1 semitone',
                        onPressed: () {
                          setModalState(() => _transpositionSemitones++);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      if (_transpositionSemitones != 0) {
                        await ref
                            .read(repertoireProvider.notifier)
                            .updateSong(transposedSong);
                        setModalState(() => _transpositionSemitones = 0);
                        setState(() {});
                      }
                      if (modalCtx.mounted) {
                        Navigator.of(modalCtx).pop();
                      }
                    },
                    child: Text(
                      _transpositionSemitones == 0
                          ? 'Done'
                          : 'Save Transposed Key (${transposedSong.key}) to Song',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportPdf(Song song) async {
    setState(() => _isExporting = true);
    try {
      final score = song.toScore();
      const generator = PdfLeadSheetGenerator();
      await generator.shareLeadSheet(score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportMidi(Song song) async {
    setState(() => _isExporting = true);
    try {
      final score = song.toScore();
      const exporter = MidiFileExporter();
      await exporter.shareMidiFile(score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export MIDI: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text(
          'Are you sure you want to delete "${song.title}"? '
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
      await ref.read(repertoireProvider.notifier).deleteSong(song.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${song.title}"')),
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
    final songAsync = ref.watch(songByIdProvider(widget.songId));

    return songAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Song Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('Error loading song: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(songByIdProvider(widget.songId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Song Detail')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Song not found in repertoire'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/repertoire'),
                    child: const Text('Back to Repertoire'),
                  ),
                ],
              ),
            ),
          );
        }

        final activeSong = _transpositionSemitones == 0
            ? song
            : SongTransposer.transposeSong(song, _transpositionSemitones);

        return Scaffold(
          appBar: AppBar(
            title: Text(activeSong.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Transpose Key',
                onPressed: () => _showTransposeDialog(song),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF Lead Sheet',
                onPressed: _isExporting ? null : () => _exportPdf(activeSong),
              ),
              IconButton(
                icon: const Icon(Icons.audiotrack_outlined),
                tooltip: 'Export MIDI File',
                onPressed: _isExporting ? null : () => _exportMidi(activeSong),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Song',
                onPressed: () => context.push('/repertoire/${song.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Song',
                onPressed: () => _deleteSong(song),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // ── Header Metadata Card ──
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeSong.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeSong.artist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaBadge(
                            icon: Icons.music_note,
                            label: 'Key: ${activeSong.key}',
                            highlight: _transpositionSemitones != 0,
                          ),
                          _MetaBadge(
                            icon: Icons.speed,
                            label: activeSong.tempoLabel,
                          ),
                          _MetaBadge(
                            icon: Icons.timer_outlined,
                            label: activeSong.timeSignatureLabel,
                          ),
                          for (final tag in activeSong.tags)
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      if (activeSong.notes != null &&
                          activeSong.notes!.isNotEmpty) ...[
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeSong.notes!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sections Lead Sheet Display ──
              if (activeSong.sections.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('This song has no sections yet.'),
                  ),
                )
              else
                for (final section in activeSong.sections)
                  _SectionDisplayCard(
                    section: section,
                    key: ValueKey(section.id),
                  ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primary
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlight ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDisplayCard extends StatelessWidget {
  const _SectionDisplayCard({required this.section, super.key});

  final dynamic section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chords = section.chords as List<ChordCell>;
    final lyrics = section.lyrics as String?;
    final notes = section.rehearsalNotes as String?;
    final repeatCount = section.repeatCount as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title and Repeat Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.name as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (repeatCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Repeat $repeatCount×',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),

            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Chords Row / Wrap
            if (chords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chord in chords)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chord.displayLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${chord.beats} beats',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // Lyrics
            if (lyrics != null && lyrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lyrics,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
