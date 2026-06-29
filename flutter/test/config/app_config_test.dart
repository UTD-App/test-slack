import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/config/app_config.dart';

/// Pure-Dart tests for [AppConfig], its factory presets, derived getters, URL
/// builders, copyWith, and the [AppConfigProvider] singleton lifecycle.
void main() {
  group('AppConfig.development', () {
    final cfg = AppConfig.development();

    test('is the development environment', () {
      expect(cfg.environment, Environment.development);
      expect(cfg.isDevelopment, isTrue);
      expect(cfg.isProduction, isFalse);
    });

    test('enables debug features', () {
      expect(cfg.enableDebugFeatures, isTrue);
    });

    test('uses the local backend base url', () {
      expect(cfg.baseUrl, 'http://192.168.1.5:8000/api');
      expect(cfg.appName, 'Tempo Dev');
    });
  });

  group('AppConfig.production', () {
    final cfg = AppConfig.production();

    test('is the production environment', () {
      expect(cfg.environment, Environment.production);
      expect(cfg.isProduction, isTrue);
      expect(cfg.isDevelopment, isFalse);
    });

    test('disables debug features', () {
      expect(cfg.enableDebugFeatures, isFalse);
    });

    test('points at the project-x backend', () {
      expect(cfg.baseUrl, 'https://project-x.utdsoftware.com/api');
      expect(cfg.domainUrl, 'https://project-x.utdsoftware.com');
      expect(cfg.appName, 'Tempo');
    });
  });

  group('defaults', () {
    const cfg = AppConfig(
      appName: 'x',
      baseUrl: 'https://api',
      storageBucketUrl: 'https://bucket',
      domainUrl: 'https://dom',
      privacyPolicyUrl: 'https://pp',
      environment: Environment.production,
    );

    test('optional fields default sanely', () {
      expect(cfg.utdStreamAppId, '');
      expect(cfg.utdStreamAppKey, '');
      expect(cfg.appBuildNumber, 1);
      expect(cfg.useDeviceLocale, isTrue);
      expect(cfg.enableDebugFeatures, isFalse);
      expect(cfg.apiTimeout, const Duration(seconds: 30));
      expect(cfg.maxRetryAttempts, 3);
    });
  });

  group('storageUrl', () {
    const cfg = AppConfig(
      appName: 'x',
      baseUrl: 'https://api',
      storageBucketUrl: 'https://bucket',
      domainUrl: 'https://dom',
      privacyPolicyUrl: 'https://pp',
      environment: Environment.production,
    );

    test('joins a relative path with a single slash', () {
      expect(cfg.storageUrl('avatars/1.png'), 'https://bucket/avatars/1.png');
    });

    test('strips exactly one leading slash from the path', () {
      expect(cfg.storageUrl('/avatars/1.png'), 'https://bucket/avatars/1.png');
    });

    test('handles an empty path', () {
      expect(cfg.storageUrl(''), 'https://bucket/');
    });
  });

  group('apiUrl', () {
    const cfg = AppConfig(
      appName: 'x',
      baseUrl: 'https://api',
      storageBucketUrl: 'https://bucket',
      domainUrl: 'https://dom',
      privacyPolicyUrl: 'https://pp',
      environment: Environment.production,
    );

    test('adds a leading slash when the endpoint lacks one', () {
      expect(cfg.apiUrl('login'), 'https://api/login');
    });

    test('keeps the endpoint when it already has a leading slash', () {
      expect(cfg.apiUrl('/login'), 'https://api/login');
    });
  });

  group('copyWith', () {
    const base = AppConfig(
      appName: 'orig',
      baseUrl: 'https://orig',
      storageBucketUrl: 'https://bucket',
      domainUrl: 'https://dom',
      privacyPolicyUrl: 'https://pp',
      environment: Environment.production,
      appBuildNumber: 5,
    );

    test('overrides only the supplied fields', () {
      final next = base.copyWith(appName: 'new', appBuildNumber: 9);
      expect(next.appName, 'new');
      expect(next.appBuildNumber, 9);
      // untouched
      expect(next.baseUrl, 'https://orig');
      expect(next.environment, Environment.production);
    });

    test('returns an equivalent config when nothing is passed', () {
      final next = base.copyWith();
      expect(next.appName, base.appName);
      expect(next.baseUrl, base.baseUrl);
      expect(next.appBuildNumber, base.appBuildNumber);
      expect(next.environment, base.environment);
    });
  });

  group('toString', () {
    test('contains the key identifying fields', () {
      const cfg = AppConfig(
        appName: 'Tempo',
        baseUrl: 'https://api',
        storageBucketUrl: 'https://bucket',
        domainUrl: 'https://dom',
        privacyPolicyUrl: 'https://pp',
        environment: Environment.development,
      );
      final s = cfg.toString();
      expect(s, contains('Tempo'));
      expect(s, contains('Environment.development'));
      expect(s, contains('https://api'));
    });
  });

  group('Environment enum', () {
    test('has exactly development and production in order', () {
      expect(Environment.values,
          <Environment>[Environment.development, Environment.production]);
    });
  });

  group('AppConfigProvider', () {
    // NOTE: the provider is a static singleton with no public reset, so we can't
    // assert the "uninitialized" branch in isolation without leaking order
    // dependence. These tests only cover the deterministic post-initialize
    // behavior, which is safe regardless of run order.

    test('initialize sets the instance and the appConfig shorthand', () {
      final cfg = AppConfig.production();
      AppConfigProvider.initialize(cfg);
      expect(AppConfigProvider.isInitialized, isTrue);
      expect(AppConfigProvider.instance, same(cfg));
      expect(AppConfigProvider.instanceOrNull, same(cfg));
      expect(appConfig, same(cfg));
    });

    test('initialize overwrites a previous instance', () {
      final a = AppConfig.development();
      final b = AppConfig.production();
      AppConfigProvider.initialize(a);
      AppConfigProvider.initialize(b);
      expect(AppConfigProvider.instance, same(b));
    });
  });
}
