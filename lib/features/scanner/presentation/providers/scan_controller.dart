/// Battuta — ScanController & Notifier.
///
/// Orchestrates camera/gallery capture, cropper flow, and routes images
/// to Gemini OMR Schema A (full lead sheet) or Schema B (pitch-only snippet)
/// with offline resilience and comprehensive error reporting.
library;

import 'package:battuta/features/scanner/data/services/image_capture_service.dart';
import 'package:battuta/features/scanner/domain/entities/pitch_only_result.dart';
import 'package:battuta/features/scanner/domain/repositories/omr_repository.dart';
import 'package:battuta/features/scanner/presentation/providers/omr_provider.dart';
import 'package:battuta/features/score/domain/entities/score.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [ImageCaptureService].
final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) {
  return DefaultImageCaptureService();
});

/// Current lifecycle status of an OMR scanning session.
enum ScanStatus { idle, picking, cropping, analyzing, success, error }

/// State representation for an active OMR scanning workflow.
class ScanState {
  const ScanState({
    this.status = ScanStatus.idle,
    this.scanMode = ScanMode.fullLeadSheet,
    this.imageBytes,
    this.extractedScore,
    this.extractedPitchResult,
    this.errorMessage,
  });

  final ScanStatus status;
  final ScanMode scanMode;
  final Uint8List? imageBytes;
  final Score? extractedScore;
  final PitchOnlyResult? extractedPitchResult;
  final String? errorMessage;

  bool get isLoading =>
      status == ScanStatus.picking ||
      status == ScanStatus.cropping ||
      status == ScanStatus.analyzing;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  ScanState copyWith({
    ScanStatus? status,
    ScanMode? scanMode,
    Uint8List? imageBytes,
    bool clearImageBytes = false,
    Score? extractedScore,
    PitchOnlyResult? extractedPitchResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScanState(
      status: status ?? this.status,
      scanMode: scanMode ?? this.scanMode,
      imageBytes: clearImageBytes ? null : (imageBytes ?? this.imageBytes),
      extractedScore: extractedScore ?? this.extractedScore,
      extractedPitchResult: extractedPitchResult ?? this.extractedPitchResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// [Notifier] managing the OMR scan flow.
class ScanController extends Notifier<ScanState> {
  ScanController({
    ImageCaptureService? captureService,
    OmrRepository? omrRepository,
  }) : _injectedCaptureService = captureService,
       _injectedOmrRepository = omrRepository;

  final ImageCaptureService? _injectedCaptureService;
  final OmrRepository? _injectedOmrRepository;

  ImageCaptureService get captureService =>
      _injectedCaptureService ?? ref.watch(imageCaptureServiceProvider);

  OmrRepository get omrRepository =>
      _injectedOmrRepository ?? ref.watch(omrRepositoryProvider);

  @override
  ScanState build() => const ScanState();

  @visibleForTesting
  set testState(ScanState newState) => state = newState;

  /// Changes the scanning mode (Full Lead Sheet vs Staff Snippet).
  void setScanMode(ScanMode mode) {
    state = state.copyWith(scanMode: mode, clearError: true);
  }

  /// Sets image bytes directly (e.g. from tests or drag-and-drop).
  void setImageBytes(Uint8List bytes) {
    state = state.copyWith(
      imageBytes: bytes,
      status: ScanStatus.idle,
      clearError: true,
    );
  }

  /// Captures an image from the camera.
  Future<void> captureFromCamera() async {
    state = state.copyWith(status: ScanStatus.picking, clearError: true);
    try {
      final bytes = await captureService.captureFromCamera();
      if (bytes != null) {
        state = state.copyWith(imageBytes: bytes, status: ScanStatus.idle);
        if (state.scanMode == ScanMode.pitchOnlySnippet) {
          await cropStaffSnippet();
        }
      } else {
        state = state.copyWith(status: ScanStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Failed to access camera: $e',
      );
    }
  }

  /// Selects an image from the photo library / file picker.
  Future<void> pickFromGallery() async {
    state = state.copyWith(status: ScanStatus.picking, clearError: true);
    try {
      final bytes = await captureService.pickFromGallery();
      if (bytes != null) {
        state = state.copyWith(imageBytes: bytes, status: ScanStatus.idle);
        if (state.scanMode == ScanMode.pitchOnlySnippet) {
          await cropStaffSnippet();
        }
      } else {
        state = state.copyWith(status: ScanStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Failed to pick photo: $e',
      );
    }
  }

  /// Invokes system cropper to isolate a staff system.
  Future<void> cropStaffSnippet() async {
    if (state.imageBytes == null) return;
    state = state.copyWith(status: ScanStatus.cropping, clearError: true);
    try {
      final cropped = await captureService.cropStaffSnippet(state.imageBytes!);
      if (cropped != null) {
        state = state.copyWith(imageBytes: cropped, status: ScanStatus.idle);
      } else {
        state = state.copyWith(status: ScanStatus.idle);
      }
    } catch (_) {
      // Non-fatal error; keep existing image
      state = state.copyWith(status: ScanStatus.idle);
    }
  }

  /// Sends the selected image to Gemini OMR according to [ScanMode].
  Future<void> analyze() async {
    final bytes = state.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(
        status: ScanStatus.error,
        errorMessage: 'Please capture or select an image before analyzing.',
      );
      return;
    }

    state = state.copyWith(status: ScanStatus.analyzing, clearError: true);

    if (state.scanMode == ScanMode.fullLeadSheet) {
      final result = await omrRepository.extractFullLeadSheet(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            status: ScanStatus.error,
            errorMessage: failure.message,
          );
        },
        (score) {
          state = state.copyWith(
            status: ScanStatus.success,
            extractedScore: score,
          );
        },
      );
    } else {
      final result = await omrRepository.extractPitchOnlySection(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            status: ScanStatus.error,
            errorMessage: failure.message,
          );
        },
        (pitchResult) {
          state = state.copyWith(
            status: ScanStatus.success,
            extractedPitchResult: pitchResult,
          );
        },
      );
    }
  }

  /// Resets scan state back to initial.
  void reset() {
    state = const ScanState();
  }
}

/// Provider for [ScanController].
final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
