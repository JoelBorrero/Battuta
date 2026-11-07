/// Battuta — Image capture and cropper service.
///
/// Wraps [ImagePicker] and [ImageCropper] to provide unified camera capture,
/// photo library selection, and staff snippet cropping across iPadOS, macOS,
/// and mobile platforms.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Supported scanning modes determining OMR schema routing.
enum ScanMode {
  /// Full page lead sheet extraction (Schema A: metadata, sections, staves, chords).
  fullLeadSheet,

  /// Cropped staff snippet or measure (Schema B: pitch-only noteheads & chords).
  pitchOnlySnippet,
}

/// Abstract contract for camera and photo selection to ensure testability.
abstract class ImageCaptureService {
  /// Captures an image using the device camera.
  Future<Uint8List?> captureFromCamera();

  /// Picks an image from the photo library / file picker.
  Future<Uint8List?> pickFromGallery();

  /// Opens the system cropper to isolate a specific staff system or measure snippet.
  Future<Uint8List?> cropStaffSnippet(
    Uint8List sourceBytes, {
    BuildContext? context,
  });
}

/// Concrete [ImageCaptureService] utilizing [ImagePicker] and [ImageCropper].
class DefaultImageCaptureService implements ImageCaptureService {
  DefaultImageCaptureService({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  @override
  Future<Uint8List?> captureFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 3200,
      imageQuality: 90,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 3200,
      imageQuality: 90,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> cropStaffSnippet(
    Uint8List sourceBytes, {
    BuildContext? context,
  }) async {
    // Write temporarily to memory/file for cropper
    // In platforms where ImageCropper operates on file paths:
    // We create a temporary XFile
    final tempXFile = XFile.fromData(
      sourceBytes,
      mimeType: 'image/jpeg',
      name: 'temp_staff_snippet.jpg',
    );

    try {
      final cropped = await _cropper.cropImage(
        sourcePath: tempXFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Staff System',
            toolbarColor: const Color(0xFF0F766E),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Staff System',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (cropped == null) return null;
      return await cropped.readAsBytes();
    } catch (_) {
      // Fallback on platforms where native cropper UI is not registered
      return sourceBytes;
    }
  }
}
