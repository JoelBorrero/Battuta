/// Picking and cropping a square profile photo or organization logo.
///
/// Wraps `image_picker` (camera or library) and `image_cropper` (square crop
/// with a circle or rounded-square guide, resized to 512x512 JPEG).
library;

import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Where the photo comes from.
enum PhotoSource { camera, gallery }

/// The shape of the crop guide: a circle for people, a rounded square for
/// logos (the cropper offers a circle or a rectangle).
enum PhotoShape { circle, square }

/// Contract of the picker so widgets can be tested without a camera.
abstract interface class ProfileImagePicker {
  /// Lets the user pick from [source] and crop. Returns the 512x512 JPEG
  /// bytes, or `null` when the user cancelled the pick or the crop.
  Future<Uint8List?> pick(
    PhotoSource source, {
    required PhotoShape shape,
    String? cropTitle,
  });
}

class DefaultProfileImagePicker implements ProfileImagePicker {
  DefaultProfileImagePicker({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  /// Side of the saved image in pixels.
  static const int outputSize = 512;

  /// JPEG quality of the saved image.
  static const int quality = 85;

  final ImagePicker _picker;
  final ImageCropper _cropper;

  @override
  Future<Uint8List?> pick(
    PhotoSource source, {
    required PhotoShape shape,
    String? cropTitle,
  }) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (file == null) return null;
    final CroppedFile? cropped;
    try {
      cropped = await _cropper.cropImage(
        sourcePath: file.path,
        maxWidth: outputSize,
        maxHeight: outputSize,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: quality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: cropTitle,
            lockAspectRatio: true,
            hideBottomControls: true,
            cropStyle: shape == PhotoShape.circle
                ? CropStyle.circle
                : CropStyle.rectangle,
            toolbarColor: const Color(0xFF121316),
            toolbarWidgetColor: const Color(0xFFF2F2F2),
            statusBarLight: false,
            backgroundColor: const Color(0xFF121316),
            activeControlsWidgetColor: const Color(0xFFE5A93C),
            cropFrameColor: const Color(0xFFE5A93C),
          ),
          IOSUiSettings(
            title: cropTitle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            cropStyle: shape == PhotoShape.circle
                ? CropStyle.circle
                : CropStyle.rectangle,
          ),
        ],
      );
    } on MissingPluginException {
      // Platforms without a native cropper (desktop): use the picked image.
      return file.readAsBytes();
    } on UnimplementedError {
      return file.readAsBytes();
    }
    // Any other cropper failure (e.g. a misconfigured Android activity) is
    // real: let it reach the sheet instead of silently uploading the
    // uncropped original.
    if (cropped == null) return null;
    return cropped.readAsBytes();
  }
}
