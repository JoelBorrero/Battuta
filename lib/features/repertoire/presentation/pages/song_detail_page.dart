/// Song detail page — displays a full song with sections, chords, and metadata.
///
/// This page provides the complete interactive lead sheet view for a song,
/// supporting real-time key transposition, PDF lead sheet printing/exporting,
/// MIDI generation, and direct navigation to edit or delete.
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/app/localization/backend_error_messages.dart';
import 'package:battuta/app/routes/app_routes.dart';
import 'package:battuta/features/audio/presentation/widgets/practice_player_bar.dart';
import 'package:battuta/features/organizations/presentation/providers/active_organization_providers.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/services/song_import_export_service.dart';
import 'package:battuta/features/repertoire/domain/services/song_transposer.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_scope_providers.dart';
import 'package:battuta/features/repertoire/presentation/widgets/add_to_setlist_sheet.dart';
import 'package:battuta/features/repertoire/presentation/widgets/chord_lyrics_view.dart';
import 'package:battuta/features/repertoire/presentation/widgets/transpose_stepper_card.dart';
import 'package:battuta/features/repertoire/presentation/widgets/version_owner_text.dart';
import 'package:battuta/features/score/data/services/midi_file_exporter.dart';
import 'package:battuta/features/score/data/services/pdf_lead_sheet_generator.dart';
import 'package:battuta/features/score/presentation/services/tone_synthesizer.dart';
import 'package:battuta/features/score/presentation/widgets/staff_canvas.dart';
import 'package:battuta/features/settings/domain/stage_preferences.dart';
import 'package:battuta/features/settings/presentation/providers/stage_preferences_provider.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_sharing_actions.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_versions_section.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showFailure(Object failure) {
    final l10n = AppLocalizations.of(context);
    if (!mounted || l10n == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(backendErrorMessage(l10n, failure))));
  }

  /// Flats are an explicit choice; otherwise the spelling follows the target
  /// key (`null`).
  bool? _preferSharps(StagePreferences prefs) =>
      prefs.preferFlats ? false : null;

  /// Writes the previewed transposition back to the song (owner only).
  Future<void> _saveTransposition(Song song) async {
    if (_transpositionSemitones == 0 ||
        !song.isEditableBy(ref.read(currentAccountIdProvider))) {
      return;
    }
    final transposed = SongTransposer.transposeSong(
      song,
      _transpositionSemitones,
      preferSharps: _preferSharps(ref.read(stagePreferencesProvider)),
    );
    final failure = await ref
        .read(repertoireProvider.notifier)
        .updateSong(transposed);
    if (failure != null) {
      _showFailure(failure);
    } else if (mounted) {
      setState(() => _transpositionSemitones = 0);
    }
  }

  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: BattutaBrand.of(context).success,
          content: Text(message),
        ),
      );
    }
  }

  Future<void> _onMenuSelected(String value, Song song, Song activeSong) async {
    switch (value) {
      case 'transpose':
        await _saveTransposition(song);
      case 'notation':
        context.push('/repertoire/${song.id}/notation');
      case 'text':
        await _copyToClipboard(
          SongImportExportService.exportSongToPlainText(activeSong),
          'Song lead sheet copied to clipboard (ChordPro)',
        );
      case 'json':
        await _copyToClipboard(
          SongImportExportService.exportSongToJson(activeSong),
          'Song JSON copied to clipboard',
        );
      case 'pdf':
        await _exportPdf(activeSong);
      case 'midi':
        await _exportMidi(activeSong);
      case 'delete':
        await _deleteSong(song);
    }
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
              l10n?.failedToExportPdf(e.toString()) ??
                  'Failed to export PDF: $e',
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
      final failure = await ref
          .read(repertoireProvider.notifier)
          .deleteSong(song.id);
      if (failure != null) {
        _showFailure(failure);
        return;
      }
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
    final brand = BattutaBrand.of(context);
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
                Text(
                  '${l10n?.failedToLoadRepertoire ?? "Error loading song"}: $err',
                  textAlign: TextAlign.center,
                ),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.versionUnavailableTitle ??
                          'This version is no longer available',
                      key: const ValueKey('version_unavailable'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.versionUnavailableBody ?? 'It was deleted, made private or is no longer shared with you.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/repertoire'),
                      child: Text(
                        l10n?.backToRepertoire ?? 'Back to Repertoire',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Only the owner edits a version; for anybody else this is a viewer.
        final canEdit = song.isEditableBy(ref.watch(currentAccountIdProvider));

        final prefs = ref.watch(stagePreferencesProvider);
        final activeSong = _transpositionSemitones == 0
            ? song
            : SongTransposer.transposeSong(
                song,
                _transpositionSemitones,
                preferSharps: _preferSharps(prefs),
              );

        final subtitle = [
          if (song.artist.trim().isNotEmpty) song.artist.trim(),
          '${l10n?.songOriginalKey(song.key) ?? 'Original: ${song.key}'}'
              '${song.tempo > 0 ? ' (${song.tempoLabel})' : ''}',
        ].join(' · ');
        final canTransposeAndSave = canEdit && _transpositionSemitones != 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.songScreenTitle ?? 'Song'),
            actions: [
              if (canEdit)
                IconButton(
                  key: const ValueKey('song_edit'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n?.editSong ?? 'Edit Song',
                  onPressed: () => context.push('/repertoire/${song.id}/edit'),
                ),
              PopupMenuButton<String>(
                key: const ValueKey('song_menu'),
                enabled: !_isExporting,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert),
                tooltip: l10n?.moreOptions ?? 'More options',
                onSelected: (value) => _onMenuSelected(value, song, activeSong),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'transpose',
                    enabled: canTransposeAndSave,
                    child: _MenuRow(
                      icon: Icons.tune,
                      label: l10n?.transposeAndSave ?? 'Transpose & save',
                    ),
                  ),
                  if (canEdit)
                    PopupMenuItem(
                      value: 'notation',
                      child: _MenuRow(
                        icon: Icons.queue_music,
                        label: l10n?.notationEditorTooltip ?? 'Notation Editor',
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'text',
                    child: _MenuRow(
                      icon: Icons.notes,
                      label: 'Copy Plain Text / ChordPro',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'json',
                    child: _MenuRow(
                      icon: Icons.data_object,
                      label: 'Copy JSON',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: _MenuRow(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Export PDF Lead Sheet',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'midi',
                    child: _MenuRow(
                      icon: Icons.audiotrack_outlined,
                      label: 'Export MIDI File',
                    ),
                  ),
                  if (canEdit) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: _MenuRow(
                        icon: Icons.delete_outline,
                        label: l10n?.deleteSong ?? 'Delete Song',
                        color: brand.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          bottomNavigationBar: StageActionBar(
            children: [
              OutlinedButton(
                key: const ValueKey('song_go_live'),
                style: StageActionBar.secondary(context),
                onPressed: () => context.push(AppRoutes.performSong(song.id)),
                child: Text(
                  l10n?.livePerfGoLive ?? 'Go live',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton(
                key: const ValueKey('add_to_setlist'),
                style: StageActionBar.primary(),
                onPressed: () => showAddToSetlistSheet(context, song),
                child: Text(
                  l10n?.addToSetlist ?? 'Add to setlist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              BattutaSpace.lg,
              BattutaSpace.xs,
              BattutaSpace.lg,
              BattutaSpace.xl,
            ),
            children: [
              if (!canEdit) _ReadOnlyVersionBanner(songId: song.id),

              // ── Title and subtitle ──
              Text(
                activeSong.title,
                style: TextStyle(
                  fontFamily: AppTheme.primaryFontFamily,
                  fontFamilyFallback: AppTheme.fontFamilyFallbacks,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: brand.ink,
                ),
              ),
              const SizedBox(height: BattutaSpace.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: brand.inkMuted,
                ),
              ),
              const SizedBox(height: BattutaSpace.lg),

              // ── Key / BPM / Time ──
              StageStatRow(
                children: [
                  StageStatTile(
                    key: const ValueKey('stat_key'),
                    value: activeSong.key,
                    label: l10n?.keyLabel ?? 'Key',
                    mono: true,
                    accent: true,
                  ),
                  StageStatTile(
                    key: const ValueKey('stat_bpm'),
                    value: activeSong.tempo > 0 ? '${activeSong.tempo}' : '–',
                    label: l10n?.songStatBpm ?? 'BPM',
                  ),
                  StageStatTile(
                    key: const ValueKey('stat_time'),
                    value: activeSong.timeSignatureLabel,
                    label: l10n?.songStatTime ?? 'Time',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Transpose preview ──
              TransposeStepperCard(
                semitones: _transpositionSemitones,
                onChanged: (value) =>
                    setState(() => _transpositionSemitones = value),
              ),
              const SizedBox(height: BattutaSpace.md),

              // ── Sharing, fork and move ──
              SongSharingActions(song: song),

              // ── Other versions of this song ──
              if (song.songWorkId != null) ...[
                SongVersionsSection(
                  songWorkId: song.songWorkId!,
                  currentVersionId: song.id,
                  title: l10n?.versionsOtherTitle ?? 'Other versions',
                ),
                const SizedBox(height: BattutaSpace.md),
              ],

              // ── Practice audio ──
              PracticePlayerBar(song: activeSong),
              const SizedBox(height: BattutaSpace.md),

              // ── Tags and notes ──
              if (activeSong.tags.isNotEmpty) ...[
                Wrap(
                  spacing: BattutaSpace.sm,
                  runSpacing: BattutaSpace.sm,
                  children: [
                    for (final tag in activeSong.tags) _TagPill(label: tag),
                  ],
                ),
                const SizedBox(height: BattutaSpace.md),
              ],
              if (activeSong.notes != null && activeSong.notes!.isNotEmpty) ...[
                StageCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: brand.accentInk,
                      ),
                      const SizedBox(width: BattutaSpace.sm),
                      Expanded(
                        child: Text(
                          activeSong.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: brand.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BattutaSpace.md),
              ],

              // ── View modes ──
              Wrap(
                spacing: BattutaSpace.sm,
                runSpacing: BattutaSpace.sm,
                children: [
                  for (final (mode, label) in [
                    (SongViewMode.both, l10n?.viewModeBoth ?? 'Both'),
                    (
                      SongViewMode.lyricsOnly,
                      l10n?.viewModeLyricsOnly ?? 'Lyrics Only',
                    ),
                    (
                      SongViewMode.chordsOnly,
                      l10n?.viewModeChordsOnly ?? 'Chords Only',
                    ),
                    (SongViewMode.staff, l10n?.musicalStaff ?? 'Musical Staff'),
                  ])
                    StageFilterPill(
                      label: label,
                      selected: _selectedViewMode == mode,
                      onTap: () => setState(() => _selectedViewMode = mode),
                    ),
                ],
              ),
              const SizedBox(height: BattutaSpace.lg),

              // ── Main Content: Both / Lyrics Only / Chords Only / Staff Notation ──
              if (_selectedViewMode == SongViewMode.staff)
                StageCard(
                  padding: const EdgeInsets.all(BattutaSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: BattutaSpace.sm,
                        runSpacing: BattutaSpace.sm,
                        children: [
                          Text(
                            l10n?.interactiveNotationView ??
                                'Interactive Notation View',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (canEdit)
                            FilledButton.tonalIcon(
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
                      const SizedBox(height: BattutaSpace.md),
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
                )
              else
                ChordLyricsView(
                  song: activeSong,
                  // activeSong is already transposed; the view must not shift it again.
                  transpositionSemitones: 0,
                  viewMode: _selectedViewMode,
                  chartTextScale: prefs.chartTextScale,
                  preferSharps: !prefs.preferFlats,
                  // A transposed preview is not stored: editing the alignment
                  // of it would persist the shifted chords on top of the preview.
                  onSongUpdated: canEdit && _transpositionSemitones == 0
                      ? (updatedSong) {
                          ref
                              .read(repertoireProvider.notifier)
                              .updateSong(updatedSong)
                              .then((failure) {
                                if (failure != null) _showFailure(failure);
                              });
                        }
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One row of the overflow menu: icon and label.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

/// Small outlined tag pill.
class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BattutaSpace.sm,
        vertical: BattutaSpace.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BattutaRadius.pill),
        border: Border.all(color: brand.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: brand.inkMuted),
      ),
    );
  }
}

/// Tells a viewer that the version belongs to somebody else.
class _ReadOnlyVersionBanner extends ConsumerWidget {
  const _ReadOnlyVersionBanner({required this.songId});

  final String songId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = BattutaBrand.of(context);
    final entry = ref.watch(repertoireEntryOfVersionProvider(songId));
    final owner = entry == null
        ? l10n.ownedByName(l10n.ownerUnknown)
        : ownedByText(l10n, entry);
    return Container(
      key: const ValueKey('read_only_version_banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BattutaRadius.smAll,
        border: Border.all(color: brand.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: brand.accentInk),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owner,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: brand.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.readOnlyVersionHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brand.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
