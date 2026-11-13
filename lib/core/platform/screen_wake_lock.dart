/// Battuta — keeps the screen on while the stage view is open.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the device screen from sleeping. Implementations never throw.
abstract interface class ScreenWakeLock {
  /// Prevents the screen from turning off.
  Future<void> enable();

  /// Lets the screen turn off again.
  Future<void> disable();
}

/// [ScreenWakeLock] backed by the `wakelock_plus` plugin. Platforms where the
/// plugin is missing or fails are ignored (logged in debug builds).
class PluginScreenWakeLock implements ScreenWakeLock {
  const PluginScreenWakeLock();

  @override
  Future<void> enable() => _run(() => WakelockPlus.enable());

  @override
  Future<void> disable() => _run(() => WakelockPlus.disable());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Screen wake lock unavailable: $error');
    }
  }
}

/// The wake lock used by the Live session page.
final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => const PluginScreenWakeLock(),
);
