/// Battuta — ScanFlowModal.
///
/// Responsive modal dialog for iPadOS and macOS (and bottom sheet for mobile)
/// facilitating camera capture, photo selection, staff system cropping,
/// and Gemini OMR analysis with loading overlays and offline error handling.
library;

import 'package:battuta/features/scanner/data/services/image_capture_service.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/presentation/providers/scan_controller.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal dialog facilitating the complete OMR capture and recognition flow.
class ScanFlowModal extends ConsumerWidget {
  const ScanFlowModal({
    super.key,
    this.onScoreExtracted,
    this.onSectionExtracted,
  });

  /// Callback when a complete lead sheet is extracted via Schema A.
  final void Function(Score score)? onScoreExtracted;

  /// Callback when a pitch-only section is extracted via Schema B.
  final void Function(PitchOnlyResult result)? onSectionExtracted;

  /// Shows the scan flow modal appropriately for the current device form factor.
  static Future<void> show(
    BuildContext context, {
    void Function(Score score)? onScoreExtracted,
    void Function(PitchOnlyResult result)? onSectionExtracted,
  }) {
    final isTabletOrDesktop = MediaQuery.sizeOf(context).width >= 600;
    if (isTabletOrDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: ScanFlowModal(
              onScoreExtracted: onScoreExtracted,
              onSectionExtracted: onSectionExtracted,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.85,
          child: ScanFlowModal(
            onScoreExtracted: onScoreExtracted,
            onSectionExtracted: onSectionExtracted,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);
    final controller = ref.read(scanControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Scan Sheet Music'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (state.hasImage && !state.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: () => controller.reset(),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // Mode Selector: Full Lead Sheet vs Staff Snippet
                // -------------------------------------------------------------
                SegmentedButton<ScanMode>(
                  segments: const [
                    ButtonSegment(
                      value: ScanMode.fullLeadSheet,
                      icon: Icon(Icons.description_outlined),
                      label: Text('Full Sheet (Schema A)'),
                    ),
                    ButtonSegment(
                      value: ScanMode.pitchOnlySnippet,
                      icon: Icon(Icons.crop_outlined),
                      label: Text('Staff Snippet (Schema B)'),
                    ),
                  ],
                  selected: {state.scanMode},
                  onSelectionChanged: (modes) {
                    controller.setScanMode(modes.first);
                  },
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // Image Capture / Selection Cards
                // -------------------------------------------------------------
                if (!state.hasImage) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('scan_camera_btn'),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                          ),
                          onPressed: () => controller.captureFromCamera(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('scan_gallery_btn'),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Photos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                          ),
                          onPressed: () => controller.pickFromGallery(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            state.scanMode == ScanMode.fullLeadSheet
                                ? Icons.auto_stories_outlined
                                : Icons.music_note_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.scanMode == ScanMode.fullLeadSheet
                                  ? 'Captures complete arrangement with metadata, staves, chords, and lyrics.'
                                  : 'Crops a single system or melody line for rapid tap-first rhythm entry.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // -----------------------------------------------------------
                  // Image Preview & Actions
                  // -----------------------------------------------------------
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 240,
                      color: Colors.black12,
                      child: Image.memory(
                        state.imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (state.scanMode == ScanMode.pitchOnlySnippet)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.crop),
                            label: const Text('Crop System'),
                            onPressed: () => controller.cropStaffSnippet(),
                          ),
                        ),
                      if (state.scanMode == ScanMode.pitchOnlySnippet)
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Change Image'),
                          onPressed: () => controller.pickFromGallery(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // -----------------------------------------------------------
                  // Analyze Button
                  // -------------------------------------------------------------
                  FilledButton.icon(
                    key: const Key('scan_analyze_btn'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Analyze with Gemini AI'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () => controller.analyze(),
                  ),
                ],

                // -------------------------------------------------------------
                // Error Display / Offline Alert
                // -------------------------------------------------------------
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recognition Error',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // -------------------------------------------------------------
                // Success Presentation
                // -------------------------------------------------------------
                if (state.status == ScanStatus.success) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Recognition Complete!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.extractedScore != null) ...[
                          Text('Title: ${state.extractedScore!.title}'),
                          Text(
                            'Sections: ${state.extractedScore!.sections.length}',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () {
                              onScoreExtracted?.call(state.extractedScore!);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Open in Repertoire'),
                          ),
                        ] else if (state.extractedPitchResult != null) ...[
                          Text(
                            'Section: ${state.extractedPitchResult!.sectionName}',
                          ),
                          Text(
                            'Measures: ${state.extractedPitchResult!.totalMeasures}',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () {
                              onSectionExtracted?.call(
                                state.extractedPitchResult!,
                              );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Open in Rhythm Editor'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // Loading Overlay
          // -------------------------------------------------------------------
          if (state.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state.status == ScanStatus.analyzing
                              ? 'Analyzing sheet with Gemini AI...'
                              : 'Processing image...',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transcribing notes, chords & staves',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
