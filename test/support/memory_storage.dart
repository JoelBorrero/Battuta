import 'package:battuta/core/services/api_key_storage.dart';

/// In-memory [ApiKeyStorage] (the secure storage plugin is not available in
/// tests).
class MemoryStorage extends ApiKeyStorage {
  MemoryStorage([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
}
