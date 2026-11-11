/// How the user entered the app: first launch, "continue offline" (remembered)
/// or signed in. Drives the router redirect.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:battuta/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEntry { firstLaunch, offline, signedIn }

abstract final class AppEntryStorageKeys {
  static const String continueOffline = 'battuta_continue_offline';
}

final appEntryStorageProvider = Provider<ApiKeyStorage>(
  (ref) => SecureApiKeyStorage(),
);

/// Whether the user chose "Continue offline" on a previous run.
class OfflineChoice extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final stored = await ref
          .read(appEntryStorageProvider)
          .read(AppEntryStorageKeys.continueOffline);
      return stored == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Remembers the choice across restarts.
  Future<void> choose() async {
    state = const AsyncData(true);
    try {
      await ref
          .read(appEntryStorageProvider)
          .write(AppEntryStorageKeys.continueOffline, 'true');
    } catch (_) {
      // Remembered for this run only.
    }
  }
}

final offlineChoiceProvider = AsyncNotifierProvider<OfflineChoice, bool>(
  OfflineChoice.new,
);

/// The entry state; `null` while the stored choice is still loading.
final appEntryProvider = Provider<AppEntry?>((ref) {
  if (ref.watch(isAuthenticatedProvider)) return AppEntry.signedIn;
  final choice = ref.watch(offlineChoiceProvider);
  if (choice.isLoading) return null;
  return choice.value == true ? AppEntry.offline : AppEntry.firstLaunch;
});
