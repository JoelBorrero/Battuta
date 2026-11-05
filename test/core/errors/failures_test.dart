import 'package:battuta/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure hierarchy', () {
    test('ServerFailure holds message and optional status code', () {
      const failure = ServerFailure(message: 'Internal error', statusCode: 500);
      expect(failure.message, equals('Internal error'));
      expect(failure.statusCode, equals(500));
      expect(failure.toString(), contains('ServerFailure: Internal error'));
    });

    test('CacheFailure holds message and stackTrace', () {
      final st = StackTrace.current;
      final failure = CacheFailure(message: 'Not found', stackTrace: st);
      expect(failure.message, equals('Not found'));
      expect(failure.stackTrace, equals(st));
    });

    test('failures with same type and message are equal', () {
      const f1 = ValidationFailure(message: 'Invalid key');
      const f2 = ValidationFailure(message: 'Invalid key');
      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
    });

    test('failures with different types or messages are not equal', () {
      const f1 = ValidationFailure(message: 'Invalid key');
      const f2 = PermissionFailure(message: 'Invalid key');
      const f3 = ValidationFailure(message: 'Different error');

      expect(f1, isNot(equals(f2)));
      expect(f1, isNot(equals(f3)));
    });
  });
}
