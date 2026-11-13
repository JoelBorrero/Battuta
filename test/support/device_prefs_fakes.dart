import 'package:battuta/core/platform/screen_wake_lock.dart';

import 'memory_storage.dart';

/// [MemoryStorage] whose reads wait [readDelay] (a slow keychain) or throw
/// when [failReads] is set.
class SlowMemoryStorage extends MemoryStorage {
  SlowMemoryStorage({
    Map<String, String>? initial,
    this.readDelay = Duration.zero,
    this.failReads = false,
  }) : super(initial);

  final Duration readDelay;
  final bool failReads;

  @override
  Future<String?> read(String key) async {
    if (readDelay > Duration.zero) await Future<void>.delayed(readDelay);
    if (failReads) throw StateError('storage unavailable');
    return super.read(key);
  }
}

/// Records wake lock calls; [held] is the current state.
class FakeScreenWakeLock implements ScreenWakeLock {
  final List<String> calls = [];
  bool held = false;

  @override
  Future<void> enable() async {
    calls.add('enable');
    held = true;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    held = false;
  }
}
