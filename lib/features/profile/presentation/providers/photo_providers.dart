/// Providers behind profile photos and organization logos: where an image
/// path becomes a URL, and the picker that produces a new image.
library;

import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/core/services/profile_image_picker.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the public URL of a stored photo. Returns `null` when there is no
/// path or no backend (the avatar then shows initials). Tests override it.
typedef PhotoUrlBuilder = String? Function(PhotoBucket bucket, String? path);

final photoUrlBuilderProvider = Provider<PhotoUrlBuilder>((ref) {
  final manager = ref.watch(supabaseClientManagerProvider);
  return (bucket, path) {
    try {
      return photoPublicUrl(manager.client, bucket, path);
    } catch (_) {
      return null;
    }
  };
});

/// The camera / library picker and cropper. Tests override it.
final profileImagePickerProvider = Provider<ProfileImagePicker>(
  (ref) => DefaultProfileImagePicker(),
);
