/// Battuta — device-level key/value storage shared by the settings that live
/// on this device only: theme, language and stage preferences.
library;

import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local key/value storage backing the device preferences.
final devicePreferencesStorageProvider = Provider<ApiKeyStorage>((ref) {
  return SecureApiKeyStorage();
});
