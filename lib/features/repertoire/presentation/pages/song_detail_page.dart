/// Song detail page — displays a full song with sections, chords, and metadata.
///
/// This page provides the complete interactive lead sheet view for a song,
/// supporting real-time key transposition, PDF lead sheet printing/exporting,
/// MIDI generation, and direct navigation to edit or delete.
library;

import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/score/data/services/midi_file_exporter.dart';
import 'package:battuta/features/score/data/services/pdf_lead_sheet_generator.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
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
  final _toneSynthesizer = ToneSynthesizer();
  int _transpositionSemitones = 0;
  bool _isExporting = false;
  SongViewMode _selectedViewMode = SongViewMode.both;

  @override
  void dispose() {
    _toneSynthesizer.dispose();
    super.dispose();
  }

  void _showTransposeDialog(Song originalSong) {
    final l10n = AppLocalizations.of(context);
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
                        l10n?.transposeSong ?? 'Transpose Song',
                        style: Theme.of(modalCtx).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _transpositionSemitones == 0
                            ? null
                            : () {
                                setModalState(
                                  () => _transpositionSemitones = 0,
                                );
                                setState(() {});
                              },
                        child: Text(l10n?.reset ?? 'Reset'),
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
                        color: Theme.of(modalCtx).colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            transposedSong.key,
                            style: Theme.of(modalCtx).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(modalCtx)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          Text(
                            _transpositionSemitones == 0
                                ? (l10n?.originalKey ?? 'Original Key')
                                : (l10n?.semitonesCount(
                                      _transpositionSemitones > 0 ? '+' : '',
                                      _transpositionSemitones,
                                    ) ??
                                    '${_transpositionSemitones > 0 ? '+' : ''}$_transpositionSemitones semitones'),
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
                        tooltip: l10n?.downOneSemitone ?? 'Down 1 semitone',
                        onPressed: () {
                          setModalState(() => _transpositionSemitones--);
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: l10n?.upOneSemitone ?? 'Up 1 semitone',
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
                          ? (l10n?.done ?? 'Done')
                          : (l10n?.saveTransposedKey(transposedSong.key) ??
                              'Save Transposed Key (${transposedSong.key}) to Song'),
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
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);
    try {
      final score = song.toScore();
      const generator = PdfLeadSheetGenerator();
      await generator.shareLeadSheet(score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.failedToExportPdf(e.toString()) ?? 'Failed to export PDF: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportMidi(Song song) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);
    try {
      final score = song.toScore();
      const exporter = MidiFileExporter();
      await exporter.shareMidiFile(score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.failedToExportMidi(e.toString()) ??
                  'Failed to export MIDI: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteSong(Song song) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteSongTitle ?? 'Delete Song'),
        content: Text(
          l10n?.deleteSongConfirm(song.title) ??
              'Are you sure you want to delete "${song.title}"? This action cannot be undone.',
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
      await ref.read(repertoireProvider.notifier).deleteSong(song.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.deletedSongSuccess(song.title) ?? 'Deleted "${song.title}"',
            ),
          ),
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
    final l10n = AppLocalizations.of(context);

    return songAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n?.songDetail ?? 'Song Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text('${l10n?.failedToLoadRepertoire ?? "Error loading song"}: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(songByIdProvider(widget.songId)),
                  child: Text(l10n?.retry ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n?.songDetail ?? 'Song Detail')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n?.songNotFound ?? 'Song not found in repertoire'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/repertoire'),
                    child: Text(l10n?.backToRepertoire ?? 'Back to Repertoire'),
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
                tooltip: l10n?.transposeKeyTooltip ?? 'Transpose Key',
                onPressed: () => _showTransposeDialog(song),
              ),
              IconButton(
                icon: const Icon(Icons.queue_music),
                tooltip: l10n?.notationEditorTooltip ?? 'Notation Editor',
                onPressed: () =>
                    context.push('/repertoire/${song.id}/notation'),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: l10n?.exportPdfTooltip ?? 'Export PDF Lead Sheet',
                onPressed: _isExporting ? null : () => _exportPdf(activeSong),
              ),
              IconButton(
                icon: const Icon(Icons.audiotrack_outlined),
                tooltip: l10n?.exportMidiTooltip ?? 'Export MIDI File',
                onPressed: _isExporting ? null : () => _exportMidi(activeSong),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n?.editSong ?? 'Edit Song',
                onPressed: () => context.push('/repertoire/${song.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n?.deleteSong ?? 'Delete Song',
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
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
                            label: l10n?.songKeyBadge(activeSong.key) ?? 'Key: ${activeSong.key}',
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
              const SizedBox(height: 12),

              // ── Practice Audio Player Bar ──
              PracticePlayerBar(song: activeSong),
              const SizedBox(height: 12),

              // ── View Mode Selector (Both vs Lyrics Only vs Chords Only vs Staff Notation) ──
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<SongViewMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: SongViewMode.both,
                        icon: const Icon(Icons.library_music),
                        label: Text(l10n?.viewModeBoth ?? 'Both'),
                      ),
                      ButtonSegment(
                        value: SongViewMode.lyricsOnly,
                        icon: const Icon(Icons.article_outlined),
                        label: Text(l10n?.viewModeLyricsOnly ?? 'Lyrics Only'),
                      ),
                      ButtonSegment(
                        value: SongViewMode.chordsOnly,
                        icon: const Icon(Icons.grid_view),
                        label: Text(l10n?.viewModeChordsOnly ?? 'Chords Only'),
                      ),
                      ButtonSegment(
                        value: SongViewMode.staff,
                        icon: const Icon(Icons.queue_music),
                        label: Text(l10n?.musicalStaff ?? 'Musical Staff'),
                      ),
                    ],
                    selected: {_selectedViewMode},
                    onSelectionChanged: (modes) {
                      setState(() => _selectedViewMode = modes.first);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Main Content: Both / Lyrics Only / Chords Only / Staff Notation ──
              if (_selectedViewMode == SongViewMode.staff)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              l10n?.interactiveNotationView ??
                                  'Interactive Notation View',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                l10n?.editInNotationEditor ??
                                    'Edit in Notation Editor',
                              ),
                              onPressed: () => context.push(
                                '/repertoire/${song.id}/notation',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 380,
                          child: StaffCanvas(
                            score: activeSong.toScore(),
                            onNoteTapped: (note) =>
                                _toneSynthesizer.playPitch(note.pitch),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ChordLyricsView(
                  song: activeSong,
                  transpositionSemitones: _transpositionSemitones,
                  viewMode: _selectedViewMode,
                  onSongUpdated: (updatedSong) {
                    ref.read(repertoireProvider.notifier).updateSong(updatedSong);
                  },
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

