import 'dart:io';

import 'package:battuta/core/errors/backend_error_code.dart';
import 'package:battuta/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendErrorCode', () {
    test('every error code documented in supabase/README.md is mapped', () {
      final readme = File('supabase/README.md').readAsStringSync();
      final section = readme.substring(readme.indexOf('Error codes:'));
      final table = section.substring(0, section.indexOf('`join_with_invite_link` checks'));
      final documented = <String, String>{}; // message -> SQLSTATE
      for (final line in table.split('\n').where((l) => l.startsWith('| `'))) {
        final cells = line.split('|').map((c) => c.trim()).toList();
        final sqlState = RegExp('`(\\w+)`').firstMatch(cells[1])!.group(1)!;
        for (final m in RegExp('`([a-z_]+)`').allMatches(cells[2])) {
          documented[m.group(1)!] = sqlState;
        }
      }

      expect(documented.length, greaterThan(30));
      for (final entry in documented.entries) {
        final code = BackendErrorCode.fromMessage(entry.key, sqlState: entry.value);
        expect(code, isNot(BackendErrorCode.unknown), reason: entry.key);
        expect(code.code, entry.key);
        final failure = code.failure();
        expect(failure.errorCode, code);
        // permission -> PermissionFailure, input -> ValidationFailure, rest -> ServerFailure
        switch (entry.value) {
          case '42501' || '28000':
            expect(failure, isA<PermissionFailure>(), reason: entry.key);
          case '22023':
            expect(failure, isA<ValidationFailure>(), reason: entry.key);
          default:
            expect(failure, isA<ServerFailure>(), reason: entry.key);
        }
      }
    });

    test('every documented enum value maps back from its own message', () {
      for (final code in BackendErrorCode.documented) {
        expect(BackendErrorCode.fromMessage(code.code), code);
      }
    });

    test('unknown or null messages map to unknown and never throw', () {
      expect(BackendErrorCode.fromMessage('something odd'), BackendErrorCode.unknown);
      expect(BackendErrorCode.fromMessage(null), BackendErrorCode.unknown);
      expect(BackendErrorCode.fromMessage(''), BackendErrorCode.unknown);
    });

    test('RLS violations map to permissionDenied', () {
      expect(
        BackendErrorCode.fromMessage(
          'new row violates row-level security policy for table "bands"',
          sqlState: '42501',
        ),
        BackendErrorCode.permissionDenied,
      );
      expect(
        BackendErrorCode.fromMessage('permission denied for table x'),
        BackendErrorCode.permissionDenied,
      );
    });

    test('wrapped messages still resolve', () {
      expect(
        BackendErrorCode.fromMessage('ERROR: invite_expired (P0001)'),
        BackendErrorCode.inviteExpired,
      );
    });

    test('offline and notSignedIn are client side failures', () {
      expect(BackendErrorCode.offline.failure(), isA<ServerFailure>());
      expect(BackendErrorCode.notSignedIn.failure(), isA<PermissionFailure>());
    });

    test('failures with different codes are not equal', () {
      expect(
        BackendErrorCode.lastAdmin.failure(message: 'x'),
        isNot(equals(BackendErrorCode.offline.failure(message: 'x'))),
      );
    });
  });
}
