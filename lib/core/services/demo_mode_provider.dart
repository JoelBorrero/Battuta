/// Battuta — Demo Mode Provider.
///
/// Controls application-wide Demo / Showcase Mode:
/// - When TRUE: displays sample team members, calendar schedules, mock AI credits,
///   cloud storage quotas, and demo rehearsal audio tracks.
/// - When FALSE: displays only genuine data from the local database, real zero-based
///   usage metrics, and dedicated empty/attachment states.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class DemoModeStorageKeys {
  static const String demoModeEnabled = 'battuta_demo_mode_enabled';
}

final demoModeStorageProvider = Provider<ApiKeyStorage>((ref) {
  return SecureApiKeyStorage();
});

/// Manages application-level Demo Mode state with persistence.
class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(demoModeStorageProvider);
    _loadPersistedDemoMode(storage);
    // Defaults to false until loaded from secure storage
    return false;
  }

  Future<void> _loadPersistedDemoMode(ApiKeyStorage storage) async {
    try {
      final val = await storage.read(DemoModeStorageKeys.demoModeEnabled);
      if (val != null) {
        state = val == 'true';
      }
    } catch (_) {}
  }

  /// Updates Demo Mode enabled state and persists to storage.
  void setDemoMode(bool enabled) {
    state = enabled;
    ref.read(demoModeStorageProvider).write(
      DemoModeStorageKeys.demoModeEnabled,
      enabled ? 'true' : 'false',
    );
  }

  /// Toggles Demo Mode between enabled and disabled.
  void toggle() {
    setDemoMode(!state);
  }
}

/// Provides application-level Demo Mode state.
final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);
