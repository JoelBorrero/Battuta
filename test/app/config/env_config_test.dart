import 'package:battuta/app/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig', () {
    test('initializes with DevConfig correctly', () {
      EnvConfig.init(Environment.dev);

      final config = EnvConfig.instance;
      expect(config, isA<DevConfig>());
      expect(config.environment, equals(Environment.dev));
      expect(config.environmentName, equals('Development'));
      expect(config.isDebug, isTrue);
      expect(config.enableVerboseLogging, isTrue);
      expect(config.apiBaseUrl, contains('localhost'));
    });

    test('initializes with StagingConfig correctly', () {
      EnvConfig.init(Environment.staging);

      final config = EnvConfig.instance;
      expect(config, isA<StagingConfig>());
      expect(config.environment, equals(Environment.staging));
      expect(config.environmentName, equals('Staging'));
      expect(config.isDebug, isTrue);
      expect(config.enableVerboseLogging, isFalse);
      expect(config.apiBaseUrl, contains('staging'));
    });

    test('initializes with ProdConfig correctly', () {
      EnvConfig.init(Environment.prod);

      final config = EnvConfig.instance;
      expect(config, isA<ProdConfig>());
      expect(config.environment, equals(Environment.prod));
      expect(config.environmentName, equals('Production'));
      expect(config.isDebug, isFalse);
      expect(config.enableVerboseLogging, isFalse);
      expect(config.apiBaseUrl, contains('api.battuta.app'));
    });

    test('top-level envConfig getter returns same instance', () {
      EnvConfig.init(Environment.dev);
      expect(envConfig, equals(EnvConfig.instance));
    });
  });
}
