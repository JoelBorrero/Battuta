import 'package:battuta/features/sync/data/versions_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('isRefusedShare', () {
    test('row-level security and constraint errors are final refusals', () {
      for (final code in ['42501', '23503', '23505', '23514']) {
        expect(
          isRefusedShare(PostgrestException(message: 'no', code: code)),
          isTrue,
          reason: code,
        );
      }
    });

    test('other errors are transient and must be retried', () {
      for (final code in [null, '', 'PGRST301', '57014', '08006', '500']) {
        expect(
          isRefusedShare(PostgrestException(message: 'later', code: code)),
          isFalse,
          reason: '$code',
        );
      }
    });
  });
}
