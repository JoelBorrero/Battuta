import 'package:battuta/features/sync/data/lan_address_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LanInterfaceInfo i(String name, [String? ip]) =>
      LanInterfaceInfo(name, [?ip]);

  group('isPrivateLanIPv4', () {
    test('accepts the private ranges', () {
      for (final a in [
        '10.0.0.4',
        '172.16.0.1',
        '172.31.255.1',
        '192.168.43.1',
      ]) {
        expect(isPrivateLanIPv4(a), isTrue, reason: a);
      }
    });

    test('rejects everything else', () {
      for (final a in [
        '127.0.0.1',
        '169.254.10.2',
        '172.32.0.1',
        '172.15.0.1',
        '8.8.8.8',
        '100.64.1.1',
        '192.169.1.1',
        'not-an-ip',
        '1.2.3',
      ]) {
        expect(isPrivateLanIPv4(a), isFalse, reason: a);
      }
    });
  });

  group('pickLanAddress', () {
    test('picks the Wi-Fi address', () {
      expect(
        pickLanAddress([i('lo0', '127.0.0.1'), i('en0', '192.168.1.20')]),
        '192.168.1.20',
      );
    });

    test('skips loopback, link-local and cellular interfaces', () {
      expect(
        pickLanAddress([
          i('lo', '127.0.0.1'),
          i('en1', '169.254.3.3'),
          i('pdp_ip0', '10.20.30.40'),
          i('rmnet_data0', '10.1.1.1'),
        ]),
        isNull,
      );
    });

    test('skips VPN tunnels even when private', () {
      expect(
        pickLanAddress([i('utun3', '10.8.0.2'), i('wlan0', '192.168.0.9')]),
        '192.168.0.9',
      );
    });

    test('prefers Wi-Fi over hotspot and other interfaces', () {
      expect(
        pickLanAddress([
          i('eth0', '10.0.0.7'),
          i('ap0', '192.168.43.1'),
          i('wlan0', '192.168.1.5'),
        ]),
        '192.168.1.5',
      );
    });

    test('keeps hotspot ranges when there is no Wi-Fi', () {
      expect(
        pickLanAddress([i('rmnet0', '10.5.5.5'), i('swlan0', '192.168.43.1')]),
        '192.168.43.1',
      );
      expect(pickLanAddress([i('bridge100', '172.20.10.1')]), '172.20.10.1');
    });

    test('returns null with nothing usable', () {
      expect(pickLanAddress(const []), isNull);
      expect(pickLanAddress([i('en0')]), isNull);
    });
  });
}
