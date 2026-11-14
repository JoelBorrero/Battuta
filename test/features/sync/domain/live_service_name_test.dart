import 'dart:convert';

import 'package:battuta/features/sync/domain/services/live_session_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int bytes(String s) => utf8.encode(s).length;

  group('buildLiveServiceName', () {
    test('keeps short names whole', () {
      expect(
        buildLiveServiceName('Sunday service', "Joel's iPad"),
        "Sunday service · Joel's iPad",
      );
    });

    test('stays within 63 bytes and keeps the session readable', () {
      final name = buildLiveServiceName(
        'Sunday morning service main stage rehearsal',
        'Joel\'s iPad Pro 12.9-inch',
      );
      expect(bytes(name), lessThanOrEqualTo(63));
      expect(name, startsWith('Sunday morning'));
      expect(name, contains('…'));
      expect(name, contains('iPad'));
    });

    test('counts multibyte characters in bytes, not letters', () {
      final name = buildLiveServiceName(
        'Alabanza y adoración ' * 3,
        'Móvil de Ñandú',
      );
      expect(bytes(name), lessThanOrEqualTo(63));
      // Never cuts a character in half.
      expect(() => utf8.decode(utf8.encode(name)), returnsNormally);

      final emoji = buildLiveServiceName('🎸' * 40, 'Pixel');
      expect(bytes(emoji), lessThanOrEqualTo(63));
    });

    test('drops a huge device name rather than the session', () {
      final name = buildLiveServiceName('Band', 'X' * 200);
      expect(bytes(name), lessThanOrEqualTo(63));
      expect(name, startsWith('Band'));
    });
  });
}
