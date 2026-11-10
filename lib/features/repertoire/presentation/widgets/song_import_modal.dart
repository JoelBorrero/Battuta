/// Battuta — Song Import & Creation Modal.
///
/// Enables musicians to import songs into their repertoire:
/// 1. Import by URL (Cifra Club active, LaCuerda soon).
/// 2. Scan sheet music with Gemini AI (Camera & Gallery OMR).
/// 3. Paste plain text / ChordPro / JSON backup.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/repertoire/data/datasources/song_url_import_service.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/domain/services/song_import_export_service.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Available import modes in the unified import hub.
enum SongImportTab {
  url('Import by URL', Icons.link),
  geminiScan('Scan with Gemini', Icons.document_scanner_outlined),
  text('Paste Text / JSON', Icons.content_paste_outlined);

  const SongImportTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SongImportModal extends ConsumerStatefulWidget {
  const SongImportModal({
    this.initialTab = SongImportTab.url,
    super.key,
  });

  final SongImportTab initialTab;

  /// Opens the [SongImportModal] in a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    SongImportTab initialTab = SongImportTab.url,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SongImportModal(initialTab: initialTab),
    );
  }

  @override
  ConsumerState<SongImportModal> createState() => _SongImportModalState();
}

class _SongImportModalState extends ConsumerState<SongImportModal> {
  late SongImportTab _currentTab;

  // ── URL Import State ──
  final TextEditingController _urlController = TextEditingController();
  final SongUrlImportService _urlService = SongUrlImportService();
  bool _isFetchingUrl = false;
  String? _urlError;
  ScrapedSongResult? _urlParsedSong;
  Song? _urlConvertedSong;

  // ── Text / Backup Import State ──
  final TextEditingController _textController = TextEditingController();
  List<Song> _parsedSongs = [];
  bool _isJsonMode = false;
  bool _isImportingText = false;
  String? _textErrorMessage;

  static const String _sampleLeadSheet = '''
// Title: Amazing Grace
// Artist: John Newton
// Key: G
// Tempo: 72
// Time: 3/4
// Tags: hymn, worship

// Verse 1
[G]Amazing grace how [C]sweet the [G]sound
That saved a wretch like [D]me
[G]I once was lost but [C]now am [G]found
Was blind but [D]now I [G]see

// Chorus (2x)
[G]My chains are gone I've [C]been set [G]free
My God my Savior has [D]ransomed me
And [G/B]like a flood His [C]mercy [G]reigns
Unending [D]love amazing [G]grace
''';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // URL IMPORT HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchFromUrl() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _urlError = 'Please enter or paste a valid song URL');
      return;
    }

    setState(() {
      _isFetchingUrl = true;
      _urlError = null;
    });

    try {
      final parsed = await _urlService.fetchPreview(rawUrl);
      final song = parsed.toSong();

      if (mounted) {
        setState(() {
          _urlParsedSong = parsed;
          _urlConvertedSong = song;
          _isFetchingUrl = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingUrl = false;
          _urlError = 'Failed to fetch song from URL: $e';
        });
      }
    }
  }

  Future<void> _pasteUrlFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        _urlController.text = text;
        setState(() => _urlError = null);
        await _fetchFromUrl();
      }
    } catch (_) {}
  }

  Future<void> _saveUrlSongToRepertoire() async {
    if (_urlConvertedSong == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final song = _urlConvertedSong!;

    try {
      await ref.read(repertoireProvider.notifier).addSong(song);
      if (mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.stageGreen,
            content: Text('Successfully imported "${song.title}" to Repertoire!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.stageRed,
            content: Text('Failed to save song: $e'),
          ),
        );
      }
    }
  }

  void _openUrlSongInEditor() {
    if (_urlConvertedSong == null) return;
    final song = _urlConvertedSong!;
    Navigator.of(context).pop();
    context.push('/repertoire/new', extra: song);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GEMINI SCAN HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _launchGeminiScanner(BuildContext context, {required bool isCamera}) {
    Navigator.of(context).pop();

    ScanFlowModal.show(
      context,
      onScoreExtracted: (Score score) async {
        final song = score.toSong();
        await ref.read(repertoireProvider.notifier).addSong(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.stageGreen,
              content: Text('Scanned & added "${song.title}" to Repertoire!'),
            ),
          );
          context.push('/repertoire/${song.id}');
        }
      },
    );

    final controller = ref.read(scanControllerProvider.notifier);
    if (isCamera) {
      controller.captureFromCamera();
    } else {
      controller.pickFromGallery();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT & BACKUP IMPORT HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onTextChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _parsedSongs = [];
        _textErrorMessage = null;
        _isJsonMode = false;
      });
      return;
    }

    try {
      final isJson = SongImportExportService.isJson(trimmed);
      final songs = SongImportExportService.parseMultipleSongs(trimmed);
      setState(() {
        _parsedSongs = songs;
        _isJsonMode = isJson;
        _textErrorMessage = null;
      });
    } catch (e) {
      setState(() {
        _parsedSongs = [];
        _textErrorMessage = e.toString();
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text.trim().isNotEmpty) {
        _textController.text = text;
        _onTextChanged(text);
      }
    } catch (_) {}
  }

  void _loadSampleTemplate() {
    _textController.text = _sampleLeadSheet.trim();
    _onTextChanged(_textController.text);
  }

  void _clearText() {
    _textController.clear();
    _onTextChanged('');
  }

  Future<void> _saveTextSongsToRepertoire() async {
    if (_parsedSongs.isEmpty || _isImportingText) return;

    setState(() => _isImportingText = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final count = _parsedSongs.length;

    try {
      await ref.read(repertoireProvider.notifier).importSongs(_parsedSongs);
      if (mounted) {
        Navigator.of(context).pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.stageGreen,
            content: Text(
              count == 1
                  ? 'Successfully imported "${_parsedSongs.first.title}" to repertoire'
                  : 'Successfully imported $count songs to repertoire',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImportingText = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.stageRed,
            content: Text('Failed to import: $e'),
          ),
        );
      }
    }
  }

  void _openTextInEditor() {
    if (_parsedSongs.isEmpty) return;
    final firstSong = _parsedSongs.first;
    Navigator.of(context).pop();
    context.push('/repertoire/new', extra: firstSong);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD METHOD & VIEWS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final bgColor = isDark ? AppTheme.slateBackground : AppTheme.pureWhiteSurface;
    final surfaceColor = isDark ? AppTheme.slateSurface : AppTheme.pearlSurfaceLight;
    final borderColor = isDark ? AppTheme.slateBorder : AppTheme.pearlBorder;
    final primaryTextColor = isDark ? AppTheme.textOffWhite : AppTheme.charcoalText;
    final mutedTextColor = isDark ? AppTheme.textMuted : AppTheme.charcoalMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1.5),
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Grab Handle ──
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Song / Lead Sheet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Import from web URL, Gemini sheet music scan, or paste',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n?.cancel ?? 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Mode Switcher (URL vs Gemini Scan vs Text) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<SongImportTab>(
              segments: const [
                ButtonSegment(
                  value: SongImportTab.url,
                  icon: Icon(Icons.link, size: 18),
                  label: Text('By URL'),
                ),
                ButtonSegment(
                  value: SongImportTab.geminiScan,
                  icon: Icon(Icons.document_scanner_outlined, size: 18),
                  label: Text('Gemini Scan'),
                ),
                ButtonSegment(
                  value: SongImportTab.text,
                  icon: Icon(Icons.content_paste_outlined, size: 18),
                  label: Text('Text / JSON'),
                ),
              ],
              selected: {_currentTab},
              onSelectionChanged: (vals) {
                setState(() => _currentTab = vals.first);
              },
            ),
          ),

          const Divider(height: 1),

          // ── Tab Body Content ──
          Expanded(
            child: switch (_currentTab) {
              SongImportTab.url => _buildUrlImportView(
                  surfaceColor,
                  borderColor,
                  primaryTextColor,
                  mutedTextColor,
                  isDark,
                ),
              SongImportTab.geminiScan => _buildGeminiScanView(
                  surfaceColor,
                  borderColor,
                  primaryTextColor,
                  mutedTextColor,
                ),
              SongImportTab.text => _buildTextImportView(
                  surfaceColor,
                  borderColor,
                  primaryTextColor,
                  mutedTextColor,
                  isDark,
                  l10n,
                ),
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: URL IMPORT VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildUrlImportView(
    Color surfaceColor,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Provider tags
        Row(
          children: [
            _buildProviderChip('Cifra Club', isActive: true),
            const SizedBox(width: 8),
            _buildProviderChip('LaCuerda', isActive: true),
          ],
        ),
        const SizedBox(height: 12),

        // URL Input
        TextField(
          key: const ValueKey('song_import_url_field'),
          controller: _urlController,
          style: TextStyle(fontSize: 14, color: primaryTextColor),
          decoration: InputDecoration(
            labelText: 'Full Song URL or Slug',
            hintText: 'e.g. cifraclub.com/... or lacuerda.net/...',
            prefixIcon: const Icon(Icons.link, color: AppTheme.stageAmber),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_paste, size: 20),
                  tooltip: 'Paste from clipboard',
                  onPressed: _pasteUrlFromClipboard,
                ),
                if (_urlController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: 'Clear',
                    onPressed: () {
                      _urlController.clear();
                      setState(() {
                        _urlParsedSong = null;
                        _urlConvertedSong = null;
                        _urlError = null;
                      });
                    },
                  ),
              ],
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _fetchFromUrl(),
        ),

        const SizedBox(height: 12),

        // Fetch Button
        FilledButton.icon(
          key: const ValueKey('fetch_url_btn'),
          onPressed: _isFetchingUrl ? null : _fetchFromUrl,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.stageAmber,
            foregroundColor: AppTheme.obsidianText,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: _isFetchingUrl
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.obsidianText,
                  ),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: Text(
            _isFetchingUrl ? 'Fetching Song & Chords...' : 'Fetch & Preview Song',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),

        const SizedBox(height: 16),

        // Error message if any
        if (_urlError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.stageRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.stageRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.stageRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _urlError!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.stageRed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Fetched Preview Card
        if (_urlConvertedSong != null && _urlParsedSong != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.stageAmber.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _urlParsedSong!.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _urlParsedSong!.artist,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.stageAmber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.stageGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.stageGreen),
                      ),
                      child: const Text(
                        'Ready to Import',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.stageGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Badges: Provider, Key, Tempo, Tuning, Capo
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildMetaChip(_urlParsedSong!.provider.displayName),
                    _buildMetaChip('Key: ${_urlParsedSong!.key}'),
                    if (_urlParsedSong!.bpm != null)
                      _buildMetaChip('${_urlParsedSong!.bpm} BPM'),
                    _buildMetaChip('Tuning: ${_urlParsedSong!.tuning}'),
                    if (_urlParsedSong!.capo > 0)
                      _buildMetaChip('Capo: Fret ${_urlParsedSong!.capo}'),
                    _buildMetaChip('${_urlParsedSong!.sections.length} Sections'),
                  ],
                ),
                const SizedBox(height: 12),

                // Chords used list
                Text(
                  'Chords used: ${_urlParsedSong!.chordsUsed.join(" • ")}',
                  style: TextStyle(fontSize: 12, color: mutedTextColor),
                ),
                const SizedBox(height: 16),

                // Actions: Save vs Open in Editor
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTextColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Edit First'),
                        onPressed: _openUrlSongInEditor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('save_url_song_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.stageGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Save to Repertoire',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _saveUrlSongToRepertoire,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: GEMINI SCAN VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGeminiScanView(
    Color surfaceColor,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x222E86DE),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.stageBlue.withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(
                Icons.document_scanner,
                size: 52,
                color: AppTheme.stageBlue,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Read Sheet Music with Gemini AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photograph a physical sheet music page or chord chart. Gemini Optical Music Recognition (OMR) transcribes the staves, chords, and lyrics directly into your library.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: mutedTextColor),
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            key: const ValueKey('gemini_scan_camera_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.stageAmber,
              foregroundColor: AppTheme.obsidianText,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text(
              'Capture with Camera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: () => _launchGeminiScanner(context, isCamera: true),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            key: const ValueKey('gemini_scan_gallery_btn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryTextColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text(
              'Select from Photo Library',
              style: TextStyle(fontSize: 14),
            ),
            onPressed: () => _launchGeminiScanner(context, isCamera: false),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: TEXT / JSON IMPORT VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTextImportView(
    Color surfaceColor,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        // Action toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.stageAmber,
                    side: const BorderSide(color: AppTheme.stageAmber),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste Clipboard'),
                  onPressed: _pasteFromClipboard,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Load Sample'),
                  onPressed: _loadSampleTemplate,
                ),
                const SizedBox(width: 8),
                if (_textController.text.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.stageRed),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    onPressed: _clearText,
                  ),
              ],
            ),
          ),
        ),

        // Text area
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  key: const ValueKey('song_import_text_field'),
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.45,
                    color: primaryTextColor,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText:
                        'Paste lead sheet or JSON here...\n\nExample:\n// Title: Amazing Grace\n// Verse 1\n[G]Amazing grace how [C]sweet...',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: isDark ? AppTheme.textDim : AppTheme.charcoalDim,
                    ),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),

              const SizedBox(height: 12),

              if (_parsedSongs.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isJsonMode
                            ? AppTheme.stageBlue.withValues(alpha: 0.2)
                            : AppTheme.stageAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isJsonMode ? AppTheme.stageBlue : AppTheme.stageAmber,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isJsonMode ? Icons.data_object : Icons.music_note,
                            size: 15,
                            color: _isJsonMode ? AppTheme.stageBlue : AppTheme.stageAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isJsonMode
                                ? 'JSON Backup (${_parsedSongs.length} ${_parsedSongs.length == 1 ? "song" : "songs"})'
                                : 'Plain Text Lead Sheet (with // comments)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isJsonMode ? AppTheme.stageBlue : AppTheme.stageAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (_textErrorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.stageRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.stageRed.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.stageRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _textErrorMessage!,
                          style: const TextStyle(fontSize: 13, color: AppTheme.stageRed),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_parsedSongs.isEmpty && _textErrorMessage == null)
                _buildInstructionsCard(surfaceColor, borderColor, primaryTextColor, mutedTextColor),

              if (_parsedSongs.isNotEmpty)
                ..._parsedSongs.map((song) => _buildSongPreviewCard(
                      song,
                      surfaceColor,
                      borderColor,
                      primaryTextColor,
                      mutedTextColor,
                      isDark,
                    )),
            ],
          ),
        ),

        // Text Action Buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                const SizedBox(width: 8),
                if (_parsedSongs.length == 1)
                  OutlinedButton.icon(
                    onPressed: _openTextInEditor,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.stageAmber,
                      side: const BorderSide(color: AppTheme.stageAmber),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Open in Editor'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _parsedSongs.isEmpty || _isImportingText ? null : _saveTextSongsToRepertoire,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.stageAmber,
                    foregroundColor: AppTheme.obsidianText,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: _isImportingText
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.obsidianText),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    _parsedSongs.length > 1
                        ? 'Import All (${_parsedSongs.length})'
                        : 'Import Song',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProviderChip(String name, {required bool isActive, String? label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.stageGreen.withValues(alpha: 0.15)
            : AppTheme.slateBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppTheme.stageGreen : AppTheme.textMuted.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: isActive ? AppTheme.stageGreen : AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label != null ? '$name ($label)' : name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.stageGreen : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.stageAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.stageAmber.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.stageAmber,
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(
    Color surfaceColor,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.stageAmber),
              const SizedBox(width: 8),
              Text(
                'How to Format Your Lead Sheet',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBulletItem(
            'Section dividers:',
            'Use // Verse 1, // Chorus, // Bridge to split sections.',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'Chords & lyrics:',
            'ChordPro [G]Amazing [C]grace or standard chord lines.',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'JSON backups:',
            'Paste complete exported JSON repertoire files for instant restore.',
            primaryTextColor,
            mutedTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    String boldPrefix,
    String text,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppTheme.stageAmber, fontWeight: FontWeight.bold)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12.5, height: 1.4, color: mutedTextColor),
              children: [
                TextSpan(
                  text: '$boldPrefix ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongPreviewCard(
    Song song,
    Color surfaceColor,
    Color borderColor,
    Color primaryTextColor,
    Color mutedTextColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.stageAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Key: ${song.key}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.stageAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(fontSize: 13, color: mutedTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            '${song.sections.length} ${song.sections.length == 1 ? "section" : "sections"} • ${song.tempo} BPM',
            style: TextStyle(fontSize: 12, color: mutedTextColor),
          ),
        ],
      ),
    );
  }
}
