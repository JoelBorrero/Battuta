import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/services/photo_storage.dart';
import 'package:battuta/features/organizations/data/backend_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

void main() {
  group('photoPublicUrl', () {
    final client = supa.SupabaseClient('http://127.0.0.1:54321', 'anon-key');

    test('builds the public object URL from the active project', () {
      expect(
        photoPublicUrl(client, PhotoBucket.avatars, 'u1/a.jpg'),
        'http://127.0.0.1:54321/storage/v1/object/public/avatars/u1/a.jpg',
      );
      expect(
        photoPublicUrl(client, PhotoBucket.organizationLogos, 'o1/l.jpg'),
        'http://127.0.0.1:54321/storage/v1/object/public/'
        'organization-logos/o1/l.jpg',
      );
    });

    test('is null without a client, a path or with an empty one', () {
      expect(photoPublicUrl(null, PhotoBucket.avatars, 'u1/a.jpg'), isNull);
      expect(photoPublicUrl(client, PhotoBucket.avatars, null), isNull);
      expect(photoPublicUrl(client, PhotoBucket.avatars, ''), isNull);
    });
  });

  group('storage errors', () {
    test('a 413 becomes image_too_large', () {
      final failure = mapBackendError(
        const supa.StorageException(
          'The object exceeded the maximum allowed size',
          statusCode: '413',
        ),
      );
      expect(failure.errorCode, BackendErrorCode.imageTooLarge);
    });

    test('row-level security and 403 become permission_denied', () {
      expect(
        mapBackendError(
          const supa.StorageException(
            'new row violates row-level security policy',
            statusCode: '403',
          ),
        ).errorCode,
        BackendErrorCode.permissionDenied,
      );
      expect(
        mapBackendError(
          const supa.StorageException('Unauthorized', statusCode: '401'),
        ).errorCode,
        BackendErrorCode.permissionDenied,
      );
    });

    test('any other storage error is a server failure', () {
      final failure = mapBackendError(
        const supa.StorageException('boom', statusCode: '500'),
      );
      expect(failure.errorCode, isNull);
      expect(failure.message, 'boom');
    });
  });
}
