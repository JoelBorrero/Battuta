/// Scanner feature — OMR camera capture and photo recognition page.
///
/// Hosts the Gemini-powered Optical Music Recognition (OMR) flow
/// (tickets #86e3yy41t, #86e3yy421, and #86e3yy428).
library;

import 'package:battuta/features/repertoire/domain/entities/song_score_mapper.dart';
import 'package:battuta/features/repertoire/presentation/providers/repertoire_provider.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/scanner/presentation/widgets/scan_flow_modal.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
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
    ScanFlowModal.show(
      context,
      onScoreExtracted: (Score score) async {
        final song = score.toSong();
        await ref.read(repertoireProvider.notifier).addSong(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${song.title}" to Repertoire!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/repertoire/${song.id}');
        }
      },
      onSectionExtracted: (PitchOnlyResult result) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Lead Sheet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'OMR Scanner',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Point your camera at a lead sheet or pick an image to extract\n'
                'chords, melody, and structure using Gemini AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                key: const Key('open_camera_button'),
                onPressed: () => _openScanModal(context, ref, fromCamera: true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Open Camera'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('choose_gallery_button'),
                onPressed: () =>
                    _openScanModal(context, ref, fromCamera: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
