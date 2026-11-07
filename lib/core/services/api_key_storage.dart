/// Low-level secure key-value storage wrapper.
///
/// Uses [FlutterSecureStorage] with hardware-backed encryption
/// (iOS Keychain and Android KeyStore / AES-GCM).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for secure key-value persistence.
abstract class ApiKeyStorage {
  const ApiKeyStorage();

  /// Reads a secure value for the given [key].
  Future<String?> read(String key);

  /// Writes a secure [value] for [key].
  Future<void> write(String key, String value);

  /// Deletes the entry for [key].
  Future<void> delete(String key);

  /// Checks if [key] exists and is non-empty.
  Future<bool> containsKey(String key);
}

/// Production implementation of [ApiKeyStorage] backed by [FlutterSecureStorage].
class SecureApiKeyStorage extends ApiKeyStorage {
  SecureApiKeyStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions.defaultOptions,
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value.trim());

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
