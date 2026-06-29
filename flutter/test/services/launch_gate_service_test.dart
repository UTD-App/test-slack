import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/services/launch_gate_service.dart';

/// Pure-Dart tests for the launch-gate value objects:
/// [SocialLink.fromJson], [AppInfo.fromJson], the [AppInfoProvider] global, and
/// the [LaunchGateResult] decision getters (`blocks`).
///
/// NOTE: [LaunchGateService.check] / .sync perform a network call and inline
/// their decision (force_update / maintenance / update_available) directly from
/// the parsed response map, so there is no pure decision function to call in
/// isolation. We therefore exercise the pure parsing + the `blocks` decision
/// getter, and skip the network fetch (documented in the report).
void main() {
  group('SocialLink.fromJson', () {
    test('parses a custom link with all fields', () {
      final l = SocialLink.fromJson({
        'platform': 'custom',
        'label': 'My Site',
        'value': 'https://example.com',
        'icon': 'uploads/icon.png',
        'color': '#1877F2',
      });
      expect(l.platform, 'custom');
      expect(l.label, 'My Site');
      expect(l.value, 'https://example.com');
      expect(l.icon, 'uploads/icon.png');
      expect(l.color, '#1877F2');
    });

    test('defaults platform to custom and trims fields', () {
      final l = SocialLink.fromJson({
        'label': '  Trim Me  ',
        'value': '  https://x  ',
      });
      expect(l.platform, 'custom');
      expect(l.label, 'Trim Me');
      expect(l.value, 'https://x');
    });

    test('blank/missing icon and color become null', () {
      final l = SocialLink.fromJson({
        'platform': 'whatsapp',
        'value': '123',
        'icon': '   ',
        'color': '',
      });
      expect(l.icon, isNull);
      expect(l.color, isNull);
    });

    test('missing label/value default to empty string', () {
      final l = SocialLink.fromJson(const {});
      expect(l.label, '');
      expect(l.value, '');
      expect(l.platform, 'custom');
    });
  });

  group('AppInfo.fromJson', () {
    test('parses full branding', () {
      final a = AppInfo.fromJson({
        'name': 'Acme',
        'description': 'Best app',
        'logo': 'logos/a.png',
        'support_email': 'help@acme.io',
        'support_phone': '+100',
        'privacy_url': 'https://acme.io/privacy',
        'terms_url': 'https://acme.io/terms',
      });
      expect(a.name, 'Acme');
      expect(a.description, 'Best app');
      expect(a.logo, 'logos/a.png');
      expect(a.supportEmail, 'help@acme.io');
      expect(a.supportPhone, '+100');
      expect(a.privacyUrl, 'https://acme.io/privacy');
      expect(a.termsUrl, 'https://acme.io/terms');
    });

    test('name defaults to Tempo when missing or blank', () {
      expect(AppInfo.fromJson(const {}).name, 'Tempo');
      expect(AppInfo.fromJson({'name': ''}).name, 'Tempo');
      expect(AppInfo.fromJson({'name': '   '}).name, 'Tempo');
    });

    test('description defaults to empty', () {
      expect(AppInfo.fromJson(const {}).description, '');
    });

    test('parses social_links list and drops empty-value entries', () {
      final a = AppInfo.fromJson({
        'social_links': [
          {'platform': 'whatsapp', 'value': '123'},
          {'platform': 'facebook', 'value': ''}, // dropped (empty value)
          {'platform': 'custom', 'value': 'https://x', 'label': 'X'},
        ],
      });
      expect(a.socialLinks.length, 2);
      expect(a.socialLinks[0].platform, 'whatsapp');
      expect(a.socialLinks[1].label, 'X');
    });

    test('ignores non-map entries inside social_links', () {
      final a = AppInfo.fromJson({
        'social_links': [
          'garbage',
          {'platform': 'whatsapp', 'value': '1'},
          null,
        ],
      });
      expect(a.socialLinks.length, 1);
    });

    test('non-list social_links yields empty list', () {
      expect(AppInfo.fromJson({'social_links': 'x'}).socialLinks, isEmpty);
      expect(AppInfo.fromJson(const {}).socialLinks, isEmpty);
    });

    test('parses the legacy flat social map and stringifies values', () {
      final a = AppInfo.fromJson({
        'social': {'whatsapp': '123', 'website': 456},
      });
      expect(a.social['whatsapp'], '123');
      expect(a.social['website'], '456'); // int → String
    });

    test('non-map social yields empty map', () {
      expect(AppInfo.fromJson({'social': 'x'}).social, isEmpty);
      expect(AppInfo.fromJson(const {}).social, isEmpty);
    });
  });

  group('AppInfo defaults / fallback', () {
    test('default constructor has safe defaults', () {
      const a = AppInfo();
      expect(a.name, 'Tempo');
      expect(a.description, '');
      expect(a.logo, isNull);
      expect(a.socialLinks, isEmpty);
      expect(a.social, isEmpty);
    });

    test('fallback equals the default', () {
      expect(AppInfo.fallback.name, const AppInfo().name);
    });
  });

  group('AppInfoProvider', () {
    tearDown(() => AppInfoProvider.current = AppInfo.fallback);

    test('defaults to the fallback', () {
      AppInfoProvider.current = AppInfo.fallback;
      expect(AppInfoProvider.current.name, 'Tempo');
    });

    test('can be replaced at runtime', () {
      AppInfoProvider.current = AppInfo.fromJson({'name': 'Acme'});
      expect(AppInfoProvider.current.name, 'Acme');
    });
  });

  group('LaunchGateResult.blocks (the gate decision)', () {
    test('neutral none result blocks nothing', () {
      expect(LaunchGateResult.none.blocks, isFalse);
      expect(LaunchGateResult.none.maintenance, isFalse);
      expect(LaunchGateResult.none.forceUpdate, isFalse);
      expect(LaunchGateResult.none.updateAvailable, isFalse);
    });

    test('force update blocks', () {
      const r = LaunchGateResult(forceUpdate: true);
      expect(r.blocks, isTrue);
    });

    test('maintenance blocks', () {
      const r = LaunchGateResult(maintenance: true);
      expect(r.blocks, isTrue);
    });

    test('an optional update available does NOT block', () {
      const r = LaunchGateResult(updateAvailable: true);
      expect(r.blocks, isFalse);
    });

    test('both maintenance and force update still blocks', () {
      const r = LaunchGateResult(maintenance: true, forceUpdate: true);
      expect(r.blocks, isTrue);
    });

    test('carries through message / store url / app branding', () {
      const r = LaunchGateResult(
        maintenance: true,
        maintenanceMessage: 'back soon',
        storeUrl: 'https://store',
        app: AppInfo(name: 'Acme'),
      );
      expect(r.maintenanceMessage, 'back soon');
      expect(r.storeUrl, 'https://store');
      expect(r.app.name, 'Acme');
    });
  });
}
