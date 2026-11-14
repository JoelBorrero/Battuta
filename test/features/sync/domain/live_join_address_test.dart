import 'package:battuta/features/sync/domain/models/live_join_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveJoinAddress.parse', () {
    test('host and port', () {
      final a = LiveJoinAddress.parse('192.168.1.20:47321');
      expect(a.host, '192.168.1.20');
      expect(a.port, 47321);
    });

    test('host only uses the default port', () {
      final a = LiveJoinAddress.parse('  192.168.1.20 ');
      expect(a.host, '192.168.1.20');
      expect(a.port, liveDefaultPort);
    });

    test('battuta-live link, with and without port', () {
      expect(
        LiveJoinAddress.parse('battuta-live://10.0.0.5:5000'),
        const LiveJoinAddress(host: '10.0.0.5', port: 5000),
      );
      expect(
        LiveJoinAddress.parse('battuta-live://10.0.0.5'),
        const LiveJoinAddress(host: '10.0.0.5'),
      );
    });

    test('mDNS style host names are accepted', () {
      expect(
        LiveJoinAddress.parse('joels-ipad.local:47320').host,
        'joels-ipad.local',
      );
    });

    test('link and display round trip', () {
      const a = LiveJoinAddress(host: '192.168.1.20');
      expect(a.display, '192.168.1.20:47320');
      expect(a.link, 'battuta-live://192.168.1.20:47320');
      expect(LiveJoinAddress.parse(a.link), a);
    });

    void rejects(String? input, LiveJoinAddressError reason) {
      expect(
        () => LiveJoinAddress.parse(input),
        throwsA(
          isA<LiveJoinAddressException>()
              .having((e) => e.reason, 'reason', reason)
              .having((e) => e.message, 'message', isNotEmpty),
        ),
        reason: 'input: $input',
      );
      expect(LiveJoinAddress.tryParse(input), isNull);
    }

    test('rejects garbage with a reason and a message', () {
      rejects(null, LiveJoinAddressError.empty);
      rejects('   ', LiveJoinAddressError.empty);
      rejects('hello world', LiveJoinAddressError.invalidHost);
      rejects('999.1.1.1', LiveJoinAddressError.invalidHost);
      rejects('1.2.3', LiveJoinAddressError.invalidHost);
      rejects(':47320', LiveJoinAddressError.invalidHost);
      rejects('192.168.1.20:abc', LiveJoinAddressError.invalidPort);
      rejects('192.168.1.20:0', LiveJoinAddressError.invalidPort);
      rejects('192.168.1.20:70000', LiveJoinAddressError.invalidPort);
      rejects('https://192.168.1.20', LiveJoinAddressError.invalidLink);
      rejects('battuta://join/abc', LiveJoinAddressError.invalidLink);
    });
  });

  group('LiveJoinAddress.fromUri', () {
    test('reads a battuta-live link', () {
      expect(
        LiveJoinAddress.fromUri(Uri.parse('battuta-live://192.168.1.20:47320')),
        const LiveJoinAddress(host: '192.168.1.20'),
      );
    });

    test('ignores other schemes', () {
      expect(LiveJoinAddress.fromUri(Uri.parse('battuta://join/abc')), isNull);
    });
  });
}
