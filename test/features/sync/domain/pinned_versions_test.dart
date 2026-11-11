import 'package:battuta/features/sync/domain/services/pinned_versions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a pinned version stays pinned until every pin is released', () {
    final pins = PinnedVersions()
      ..pin('v1')
      ..pin('v1')
      ..pin('v2');
    expect(pins.ids, {'v1', 'v2'});
    pins.release('v1');
    expect(pins.isPinned('v1'), isTrue);
    pins.release('v1');
    expect(pins.isPinned('v1'), isFalse);
    expect(pins.ids, {'v2'});
  });

  test('releasing something never pinned is harmless', () {
    final pins = PinnedVersions()..release('nope');
    expect(pins.ids, isEmpty);
  });
}
