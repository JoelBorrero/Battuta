/// Scanner feature — OMR camera capture and photo recognition page.
///
/// Hosts the Gemini-powered Optical Music Recognition (OMR) flow
/// (tickets #86e3yy41t, #86e3yy421, and #86e3yy428).
library;

import 'package:battuta/app/design_system/design_system.dart';
import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:battuta/features/sharing/presentation/widgets/song_link_sheet.dart';
import 'package:battuta/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full screen landing page for the OMR scanner feature.
class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  void _openScanModal(
    BuildContext context,
    WidgetRef ref, {
    required bool fromCamera,
  }) {
    final l10n = AppLocalizations.of(context);
    ScanFlowModal.show(
      context,
      onScoreExtracted: (Score score) async {
        final linked = await linkSongBeforeSave(context, ref, score.toSong());
        if (linked == null) return;
        final song = linked;
        await ref.read(repertoireProvider.notifier).addSong(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.addedToRepertoireSuccess(song.title) ??
                    'Added "${song.title}" to Repertoire!',
              ),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: l10n?.openInRepertoire ?? 'Open in Repertoire',
                onPressed: () {
                  if (context.mounted) {
                    while (context.canPop()) {
                      context.pop();
                    }
                    context.go('/repertoire/${song.id}');
                  }
                },
              ),
            ),
          );
          while (context.canPop()) {
            context.pop();
          }
          context.go('/repertoire/${song.id}');
        }
      },
      onSectionExtracted: (PitchOnlyResult result) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.extractedMeasuresSuccess(
                      result.totalMeasures,
                      result.sectionName,
                    ) ??
                    'Extracted ${result.totalMeasures} measures for "${result.sectionName}".',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );

    final controller = ref.read(scanControllerProvider.notifier);
    if (fromCamera) {
      controller.captureFromCamera();
    } else {
      controller.pickFromGallery();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = BattutaBrand.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.scanLeadSheet ?? 'Scan sheet music')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                BattutaSpace.lg,
                BattutaSpace.xs,
                BattutaSpace.lg,
                BattutaSpace.xl,
              ),
              children: [
                const _CaptureViewfinder(),
                const SizedBox(height: 18),
                Text(
                  l10n?.omrScannerTitle ?? 'Turn paper into charts',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: brand.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.omrScannerSubtitle ??
                      'Scan printed sheet music or a chord chart. Chords, '
                          'melody and structure are extracted with Gemini AI.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: brand.inkMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: BattutaSpace.lg),
                _ScanActionTile(
                  key: const Key('open_camera_button'),
                  icon: Icons.photo_camera_outlined,
                  title: l10n?.openCamera ?? 'Capture from camera',
                  caption:
                      l10n?.openCameraCaption ??
                      'Photograph a page on the music stand',
                  primary: true,
                  onTap: () => _openScanModal(context, ref, fromCamera: true),
                ),
                const SizedBox(height: BattutaSpace.sm),
                _ScanActionTile(
                  key: const Key('choose_gallery_button'),
                  icon: Icons.image_outlined,
                  title: l10n?.chooseFromLibrary ?? 'Choose from photos',
                  caption:
                      l10n?.chooseFromLibraryCaption ??
                      'An image from this device',
                  onTap: () => _openScanModal(context, ref, fromCamera: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One capture source: an icon tile, a title and a caption in a pressable card.
class _ScanActionTile extends StatelessWidget {
  const _ScanActionTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
    super.key,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    final textTheme = Theme.of(context).textTheme;
    return StageCard(
      onTap: onTap,
      selected: primary,
      semanticLabel: title,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: BattutaSpace.minTouchTarget,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary ? brand.accent : brand.cardRaised,
                borderRadius: BorderRadius.circular(BattutaRadius.sm + 2),
              ),
              child: Icon(
                icon,
                size: 22,
                color: primary ? brand.onAccent : brand.ink,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: brand.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: textTheme.bodySmall?.copyWith(color: brand.inkMuted),
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

/// Static viewfinder illustration: staff lines, amber corner brackets and a
/// scan line. Decorative only, so it is excluded from semantics.
class _CaptureViewfinder extends StatelessWidget {
  const _CaptureViewfinder();

  @override
  Widget build(BuildContext context) {
    final brand = BattutaBrand.of(context);
    return ExcludeSemantics(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: brand.card,
          border: Border.all(color: brand.border),
          borderRadius: BorderRadius.circular(BattutaRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _ViewfinderPainter(
            accent: brand.accent,
            line: brand.inkDim,
            lineDim: brand.border,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter({
    required this.accent,
    required this.line,
    required this.lineDim,
  });

  final Color accent;
  final Color line;
  final Color lineDim;

  @override
  void paint(Canvas canvas, Size size) {
    // Three staves of five lines, centred.
    const staffWidth = 220.0;
    const lineGap = 6.0;
    const staffGap = 14.0;
    const staffHeight = lineGap * 4 + 1;
    const total = staffHeight * 3 + staffGap * 2;
    final left = (size.width - staffWidth) / 2;
    final top = (size.height - total) / 2;
    for (var s = 0; s < 3; s++) {
      final paint = Paint()
        ..color = s == 2 ? lineDim : line
        ..strokeWidth = 1;
      final y0 = top + s * (staffHeight + staffGap);
      for (var l = 0; l < 5; l++) {
        final y = y0 + l * lineGap;
        canvas.drawLine(Offset(left, y), Offset(left + staffWidth, y), paint);
      }
    }

    // Scan line.
    final scanX = size.width / 2 + 30;
    canvas.drawLine(
      Offset(scanX, 0),
      Offset(scanX, size.height),
      Paint()
        ..color = accent
        ..strokeWidth = 2,
    );

    // Corner brackets.
    final bracket = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const inset = 16.0;
    const arm = 26.0;
    const r = 8.0;
    for (final (sx, sy) in const [
      (1.0, 1.0),
      (-1.0, 1.0),
      (1.0, -1.0),
      (-1.0, -1.0),
    ]) {
      final cx = sx > 0 ? inset : size.width - inset;
      final cy = sy > 0 ? inset : size.height - inset;
      final path = Path()
        ..moveTo(cx + sx * arm, cy)
        ..lineTo(cx + sx * r, cy)
        ..quadraticBezierTo(cx, cy, cx, cy + sy * r)
        ..lineTo(cx, cy + sy * arm);
      canvas.drawPath(path, bracket);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) =>
      old.accent != accent || old.line != line || old.lineDim != lineDim;
}
