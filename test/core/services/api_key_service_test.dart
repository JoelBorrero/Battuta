import 'package:battuta/core/services/api_key_service.dart';
import 'package:battuta/core/services/api_key_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiKeyStorage extends Mock implements ApiKeyStorage {}

void main() {
  late MockApiKeyStorage mockStorage;

  setUp(() {
    mockStorage = MockApiKeyStorage();
  });

  const validKey = 'AIzaSyA1234567890abcdefghijklmnopqrstuv';

  group('ApiKeyService', () {
    group('getActiveGeminiKey & getGeminiKeySource', () {
      test('returns custom key from secure storage when present', () async {
        when(() => mockStorage.read(geminiStorageKey))
            .thenAnswer((_) async => validKey);

        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {geminiEnvKey: 'env-fallback-key-12345678'},
        );

        final key = await service.getActiveGeminiKey();
        final source = await service.getGeminiKeySource();

        expect(key, equals(validKey));
        expect(source, equals(ApiKeySource.userSecureStorage));
        verify(() => mockStorage.read(geminiStorageKey)).called(2);
      });

      test('falls back to env when storage key is absent or empty', () async {
        when(() => mockStorage.read(geminiStorageKey))
            .thenAnswer((_) async => null);

        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {geminiEnvKey: 'env-key-abcdefghijklmnopqrst'},
        );

        final key = await service.getActiveGeminiKey();
        final source = await service.getGeminiKeySource();

        expect(key, equals('env-key-abcdefghijklmnopqrst'));
        expect(source, equals(ApiKeySource.envFile));
      });

      test('returns null and ApiKeySource.none when neither storage nor env has a key', () async {
        when(() => mockStorage.read(geminiStorageKey))
            .thenAnswer((_) async => null);

        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {},
        );

        final key = await service.getActiveGeminiKey();
        final source = await service.getGeminiKeySource();

        expect(key, isNull);
        expect(source, equals(ApiKeySource.none));
        expect(await service.hasGeminiKey(), isFalse);
      });
    });

    group('setCustomGeminiKey & clearCustomGeminiKey', () {
      test('saves valid key to secure storage', () async {
        when(() => mockStorage.write(geminiStorageKey, any()))
            .thenAnswer((_) async {});

        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {},
        );

        await service.setCustomGeminiKey(validKey);

        verify(() => mockStorage.write(geminiStorageKey, validKey)).called(1);
      });

      test('throws ArgumentError on invalid key formats', () async {
        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {},
        );

        // Too short (< 20 chars)
        expect(
          () => service.setCustomGeminiKey('too-short'),
          throwsArgumentError,
        );

        // Contains whitespace
        expect(
          () => service.setCustomGeminiKey('AIzaSy 1234567890abcdefgh'),
          throwsArgumentError,
        );

        // Empty
        expect(
          () => service.setCustomGeminiKey(''),
          throwsArgumentError,
        );

        verifyNever(() => mockStorage.write(any(), any()));
      });

      test('clears custom key from secure storage', () async {
        when(() => mockStorage.delete(geminiStorageKey))
            .thenAnswer((_) async {});

        final service = ApiKeyService(
          storage: mockStorage,
          envOverrides: {},
        );

        await service.clearCustomGeminiKey();

        verify(() => mockStorage.delete(geminiStorageKey)).called(1);
      });
    });

    group('isValidKey helper', () {
      test('validates correct formats', () {
        expect(ApiKeyService.isValidKey(validKey), isTrue);
        expect(ApiKeyService.isValidKey('12345678901234567890'), isTrue);
      });

      test('rejects null, short, and whitespace keys', () {
        expect(ApiKeyService.isValidKey(null), isFalse);
        expect(ApiKeyService.isValidKey(''), isFalse);
        expect(ApiKeyService.isValidKey('abc'), isFalse);
        expect(ApiKeyService.isValidKey('123456789 12345678901'), isFalse);
      });
    });

    group('maskKey helper', () {
      test('returns Not configured for null or empty keys', () {
        expect(ApiKeyService.maskKey(null), equals('Not configured'));
        expect(ApiKeyService.maskKey(''), equals('Not configured'));
        expect(ApiKeyService.maskKey('   '), equals('Not configured'));
      });

      test('masks middle characters for long keys', () {
        expect(
          ApiKeyService.maskKey('AIzaSy1234567890xyzW'),
          equals('AIza••••••••xyzW'),
        );
      });

      test('returns bullets for short keys', () {
        expect(ApiKeyService.maskKey('short'), equals('••••••••'));
      });
    });
  });
}
