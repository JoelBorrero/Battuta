/// Profile photos and organization logos in Supabase Storage.
///
/// Objects live in two public-read buckets under an unguessable name:
/// `avatars/<user id>/<uuid>.jpg` and `organization-logos/<org id>/<uuid>.jpg`.
/// The database keeps only the bucket-relative path, so the URL is built here
/// from whichever project the app talks to.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:uuid/uuid.dart';

/// The Storage bucket of a kind of photo.
enum PhotoBucket {
  avatars('avatars'),
  organizationLogos('organization-logos');

  const PhotoBucket(this.id);

  final String id;
}

/// Public URL of the object at [path] (bucket-relative) in [bucket], or `null`
/// when there is no path or no backend client. Builds a string only; never
/// touches the network.
String? photoPublicUrl(
  supa.SupabaseClient? client,
  PhotoBucket bucket,
  String? path,
) {
  if (client == null || path == null || path.isEmpty) return null;
  return client.storage.from(bucket.id).getPublicUrl(path);
}

/// Uploads the JPEG [bytes] to a new object under [folder] and returns its
/// bucket-relative path. A fresh name per upload means a replaced photo is
/// never served stale from a cache.
Future<String> uploadPhoto(
  supa.SupabaseClient client,
  PhotoBucket bucket,
  String folder,
  Uint8List bytes,
) async {
  final path = '$folder/${const Uuid().v4()}.jpg';
  await client.storage
      .from(bucket.id)
      .uploadBinary(
        path,
        bytes,
        fileOptions: const supa.FileOptions(contentType: 'image/jpeg'),
      );
  return path;
}

/// Best-effort delete of the object at [path]; a failure is ignored (the row
/// no longer references it, so the worst case is an orphaned file).
Future<void> removePhotoQuietly(
  supa.SupabaseClient client,
  PhotoBucket bucket,
  String? path,
) async {
  if (path == null || path.isEmpty) return;
  try {
    await client.storage.from(bucket.id).remove([path]);
  } catch (_) {
    // Orphaned object: harmless.
  }
}
