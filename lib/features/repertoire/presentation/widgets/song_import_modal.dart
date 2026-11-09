/// Battuta — Song Import Modal.
///
/// Enables musicians to import songs and full repertoire backups:
/// - From plain text / clipboard lead sheets (using `//` comments for section demarcation).
/// - From JSON format (single song or multiple songs array).
/// - Offers live preview of parsed sections, chords, and metadata.
/// - Allows immediate saving to local database or opening in the Song Editor.
library;

import 'package:battuta/app/theme/app_theme.dart';
import 'package:battuta/features/repertoire/domain/entities/song.dart';
import 'package:battuta/features/repertoire/domain/services/song_import_export_service.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SongImportModal extends ConsumerStatefulWidget {
  const SongImportModal({super.key});

  /// Opens the [SongImportModal] in a bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const SongImportModal(),
    );
  }

  @override
  ConsumerState<SongImportModal> createState() => _SongImportModalState();
}

class _SongImportModalState extends ConsumerState<SongImportModal> {
  final TextEditingController _textController = TextEditingController();
  List<Song> _parsedSongs = [];
  bool _isJsonMode = false;
  bool _isImporting = false;
  String? _errorMessage;

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
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _parsedSongs = [];
        _errorMessage = null;
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
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _parsedSongs = [];
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard is empty'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      _textController.text = text;
      _onTextChanged(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read clipboard: $e'),
            backgroundColor: AppTheme.stageRed,
          ),
        );
      }
    }
  }

  void _loadSampleTemplate() {
    _textController.text = _sampleLeadSheet.trim();
    _onTextChanged(_textController.text);
  }

  void _clearText() {
    _textController.clear();
    _onTextChanged('');
  }

  Future<void> _saveToRepertoire() async {
    if (_parsedSongs.isEmpty || _isImporting) return;

    setState(() => _isImporting = true);
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
        setState(() => _isImporting = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.stageRed,
            content: Text('Failed to import: $e'),
          ),
        );
      }
    }
  }

  void _openInEditor() {
    if (_parsedSongs.isEmpty) return;
    final firstSong = _parsedSongs.first;
    Navigator.of(context).pop();
    context.push('/repertoire/new', extra: firstSong);
  }

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
                        'Import Song / Repertoire',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Supports JSON and plain text with // comments for sections',
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

          const Divider(height: 1),

          // ── Quick Action Toolbar ──
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
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.stageRed,
                      ),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                      onPressed: _clearText,
                    ),
                ],
              ),
            ),
          ),

          // ── Main Content: Editor & Live Preview ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                // ── Text Input Area ──
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
                      hintText: 'Paste lead sheet or JSON here...\n\nExample:\n// Title: Amazing Grace\n// Verse 1\n[G]Amazing grace how [C]sweet...',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        color: isDark ? AppTheme.textDim : AppTheme.charcoalDim,
                      ),
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Parsing Status / Mode Badge ──
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

                // ── Error Message ──
                if (_errorMessage != null)
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
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: AppTheme.stageRed),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Empty State / Instructions ──
                if (_parsedSongs.isEmpty && _errorMessage == null)
                  _buildInstructionsCard(surfaceColor, borderColor, primaryTextColor, mutedTextColor),

                // ── Parsed Songs Preview ──
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

          // ── Bottom Action Buttons ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: bgColor,
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
                      onPressed: _openInEditor,
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
                    onPressed: _parsedSongs.isEmpty || _isImporting ? null : _saveToRepertoire,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.stageAmber,
                      foregroundColor: AppTheme.obsidianText,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: _isImporting
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
                'How to Format Your Song',
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
            'Double-slash (//) section dividers:',
            'Use // Verse 1, // Chorus, // Bridge, // Coro, // Puente to automatically split your song into sections with their respective type.',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'Section repeats:',
            'Add repeat count like // Chorus (2x) or // Coro x2.',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'Metadata lines:',
            '// Title: Song Name, // Key: G, // Tempo: 120, // Time: 4/4',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'Chords & lyrics:',
            'Standard ChordPro bracket notation ([G]Amazing [C]grace) or two-line chords over lyrics are both recognized automatically.',
            primaryTextColor,
            mutedTextColor,
          ),
          const SizedBox(height: 8),
          _buildBulletItem(
            'JSON backups:',
            'Exported JSON backups (single song or entire repertoire) can be pasted here for one-click restore.',
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
    final firstLyricSection = song.sections.where((s) => s.lyrics != null && s.lyrics!.isNotEmpty).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Artist
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Musical Key badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.stageAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.stageAmber),
                ),
                child: Text(
                  'Key ${song.key}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.stageAmber,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Metadata Badges (Tempo, Time Sig, Section count)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaPill('${song.tempo} BPM', Icons.speed, borderColor, primaryTextColor),
              _buildMetaPill(song.timeSignatureLabel, Icons.timer_outlined, borderColor, primaryTextColor),
              _buildMetaPill('${song.sections.length} sections', Icons.view_headline, borderColor, primaryTextColor),
              if (song.tags.isNotEmpty)
                _buildMetaPill(song.tags.join(', '), Icons.label_outline, borderColor, primaryTextColor),
            ],
          ),

          const SizedBox(height: 12),

          // Sections breakdown
          Text(
            'SECTIONS DETECTED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: mutedTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: song.sections.map((sec) {
              final repeatSuffix = sec.repeatCount > 1 ? ' (${sec.repeatCount}x)' : '';
              final chordSuffix = sec.chords.isNotEmpty ? ' · ${sec.chords.length} chords' : '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slateSurfaceLight : AppTheme.pearlBorderSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '${sec.name}$repeatSuffix$chordSuffix',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              );
            }).toList(),
          ),

          // Sample lyrics preview
          if (firstLyricSection != null && firstLyricSection.lyrics != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.obsidian : AppTheme.pureWhiteSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                firstLyricSection.lyrics!.split('\n').take(4).join('\n'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.4,
                  color: primaryTextColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaPill(String label, IconData icon, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: textColor),
          ),
        ],
      ),
    );
  }
}
