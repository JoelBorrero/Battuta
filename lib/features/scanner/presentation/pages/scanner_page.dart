/// Scanner feature — OMR camera capture placeholder.
///
/// This page will eventually host the Gemini-powered Optical Music
/// Recognition (OMR) camera capture flow (tickets #86e3yy41t and
/// #86e3yy421).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder page for the OMR scanner feature.
///
/// Will be expanded to include:
/// - Camera viewfinder for capturing lead sheet photos
/// - Photo library import option
/// - Crop & enhance pre-processing
/// - Gemini API integration for music recognition
class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Lead Sheet'),
      ),
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
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Point your camera at a lead sheet to extract\n'
                'chords, melody, and structure using Gemini AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: null, // TODO: implement camera capture
                icon: const Icon(Icons.camera_alt),
                label: const Text('Open Camera'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null, // TODO: implement photo library import
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

