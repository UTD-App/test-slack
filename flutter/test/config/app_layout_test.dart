import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/config/app_flow.dart';
import 'package:utd_app/config/app_layout.dart';

/// Pure-Dart tests for the server-delivered `app_layout` parsing:
/// [AppLayout.fromJson], [BottomNavConfig.fromJson], [NavTab.fromJson], and
/// [NavStyle.fromJson] hex parsing + defaulting.
void main() {
  group('NavStyle.fromJson', () {
    test('parses #RRGGBB hex with opaque alpha', () {
      final s = NavStyle.fromJson({
        'bg': '#101010',
        'active': '#202020',
        'inactive': '#303030',
      });
      expect(s.bg, const Color(0xFF101010));
      expect(s.active, const Color(0xFF202020));
      expect(s.inactive, const Color(0xFF303030));
    });

    test('parses #AARRGGBB hex preserving alpha', () {
      final s = NavStyle.fromJson({'bg': '#80FF0000'});
      expect(s.bg, const Color(0x80FF0000));
    });

    test('uses the built-in defaults when not a map', () {
      final s = NavStyle.fromJson(null);
      expect(s.bg, const Color(0xFFFFFFFF));
      expect(s.active, const Color(0xFF2563EB));
      expect(s.inactive, const Color(0xFF94A3B8));
    });

    test('falls back per-field on bad/blank hex', () {
      final s = NavStyle.fromJson({
        'bg': 'nope',
        'active': '',
        // inactive missing
      });
      expect(s.bg, const Color(0xFFFFFFFF));
      expect(s.active, const Color(0xFF2563EB));
      expect(s.inactive, const Color(0xFF94A3B8));
    });

    test('falls back when value is not a string', () {
      final s = NavStyle.fromJson({'bg': 123});
      expect(s.bg, const Color(0xFFFFFFFF));
    });
  });

  group('NavTab.fromJson', () {
    test('parses all fields', () {
      final t = NavTab.fromJson({
        'screen': 'home_screen',
        'route': '/home',
        'label': 'Home',
        'icon': 'chat',
        'kind': 'native',
        'featureId': 'chat.feature',
      });
      expect(t.screen, 'home_screen');
      expect(t.route, '/home');
      expect(t.label, 'Home');
      expect(t.iconName, 'chat');
      expect(t.kind, 'native');
      expect(t.featureId, 'chat.feature');
      expect(t.isNative, isTrue);
    });

    test('applies defaults for missing fields', () {
      final t = NavTab.fromJson(const {});
      expect(t.screen, '');
      expect(t.route, '');
      expect(t.label, '');
      expect(t.iconName, 'home'); // default icon
      expect(t.kind, 'stac'); // default kind
      expect(t.featureId, isNull);
      expect(t.isNative, isFalse);
    });

    test('isNative is true only for kind == native', () {
      expect(NavTab.fromJson({'kind': 'stac'}).isNative, isFalse);
      expect(NavTab.fromJson({'kind': 'native'}).isNative, isTrue);
      expect(NavTab.fromJson({'kind': 'other'}).isNative, isFalse);
    });
  });

  group('BottomNavConfig.fromJson', () {
    test('enabled defaults to true (only false disables)', () {
      expect(BottomNavConfig.fromJson(const {}).enabled, isTrue);
      expect(BottomNavConfig.fromJson({'enabled': true}).enabled, isTrue);
      expect(BottomNavConfig.fromJson({'enabled': false}).enabled, isFalse);
      // a non-bool value is "not false" → enabled
      expect(BottomNavConfig.fromJson({'enabled': 'yes'}).enabled, isTrue);
    });

    test('parses an ordered list of tabs', () {
      final cfg = BottomNavConfig.fromJson({
        'tabs': [
          {'label': 'A', 'route': '/a'},
          {'label': 'B', 'route': '/b'},
        ],
      });
      expect(cfg.tabs.length, 2);
      expect(cfg.tabs[0].label, 'A');
      expect(cfg.tabs[1].label, 'B');
    });

    test('ignores non-map tab entries', () {
      final cfg = BottomNavConfig.fromJson({
        'tabs': [
          {'label': 'A'},
          'garbage',
          42,
          {'label': 'B'},
        ],
      });
      expect(cfg.tabs.length, 2);
      expect(cfg.tabs.map((t) => t.label), ['A', 'B']);
    });

    test('empty/absent/non-list tabs yields no tabs', () {
      expect(BottomNavConfig.fromJson(const {}).tabs, isEmpty);
      expect(BottomNavConfig.fromJson({'tabs': 'x'}).tabs, isEmpty);
    });
  });

  group('AppLayout.fromJson', () {
    test('returns null for null input', () {
      expect(AppLayout.fromJson(null), isNull);
    });

    test('returns null when neither flow nor bottomNav is present', () {
      expect(AppLayout.fromJson(const {'schema': 1}), isNull);
    });

    test('parses bottomNav only', () {
      final layout = AppLayout.fromJson({
        'bottomNav': {
          'enabled': true,
          'tabs': [
            {'label': 'Home', 'route': '/'},
          ],
        },
      });
      expect(layout, isNotNull);
      expect(layout!.flow, isNull);
      expect(layout.bottomNav, isNotNull);
      expect(layout.bottomNav!.tabs.length, 1);
    });

    test('parses flow with slot overrides and screen contracts', () {
      final layout = AppLayout.fromJson({
        'flow': {
          'unauthenticated': '/s/core_login',
          'home': '/s/core_home',
          'onAuthSuccess': '/welcome',
        },
        'screens': {
          '/s/core_login': {'role': 'auth.login'},
          '/s/core_home': {'role': 'app.home', 'requiresAuth': true},
          '/intro': {'role': 'onboarding.intro', 'showOnce': true},
        },
      });
      expect(layout, isNotNull);
      final flow = layout!.flow!;
      expect(flow.unauthenticated, '/s/core_login');
      expect(flow.home, '/s/core_home');
      expect(flow.onAuthSuccess, '/welcome');
      // unspecified slots fall back to AppFlow.fallback
      expect(flow.splash, AppFlow.fallback.splash);
      expect(flow.firstRun, AppFlow.fallback.firstRun);
      // contracts
      expect(flow.contractFor('/s/core_home').requiresAuth, isTrue);
      expect(flow.contractFor('/s/core_home').role, 'app.home');
      expect(flow.contractFor('/intro').showOnce, isTrue);
      expect(flow.contractFor('/s/core_login').requiresAuth, isFalse);
    });

    test('flow with no screens block yields empty contracts', () {
      final layout = AppLayout.fromJson({
        'flow': {'home': '/x'},
      });
      final flow = layout!.flow!;
      expect(flow.home, '/x');
      // unknown route → inert default contract
      expect(flow.contractFor('/x').role, isNull);
    });

    test('ignores non-map screen entries', () {
      final layout = AppLayout.fromJson({
        'flow': {'home': '/x'},
        'screens': {
          '/x': {'role': 'app.home'},
          '/junk': 'not-a-map',
        },
      });
      final flow = layout!.flow!;
      expect(flow.contractFor('/x').role, 'app.home');
      expect(flow.contractFor('/junk').role, isNull);
    });

    test('parses both flow and bottomNav together', () {
      final layout = AppLayout.fromJson({
        'flow': {'home': '/'},
        'bottomNav': {
          'tabs': [
            {'label': 'A'},
          ],
        },
      });
      expect(layout!.flow, isNotNull);
      expect(layout.bottomNav, isNotNull);
    });
  });
}
