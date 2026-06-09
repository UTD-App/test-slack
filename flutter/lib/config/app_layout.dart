import 'package:flutter/material.dart';

import 'app_flow.dart';

/// Parsed form of the server-delivered `app_layout` document — the single
/// source of truth that lets UTD Studio drive the app's navigation (flow +
/// bottom nav) without any base-side code.
///
/// Delivered as a normal Stac document named `app_layout` (package `__app__`)
/// through the existing push/fetch pipeline, so it inherits versioning and
/// Hive caching for free (see [AppLayoutService]). Shape:
/// ```json
/// { "schema": 1,
///   "flow": { "unauthenticated": "/s/core_login", "home": "/", ... },
///   "bottomNav": { "enabled": true, "style": {...}, "tabs": [ {...} ] },
///   "screens": { "/s/core_login": { "role": "auth.login", ... } } }
/// ```
/// Parsing is tolerant: missing slots fall back to [AppFlow.fallback]; a
/// malformed document yields null so the caller keeps its defaults.
class AppLayout {
  final AppFlow? flow;
  final BottomNavConfig? bottomNav;

  const AppLayout({this.flow, this.bottomNav});

  static AppLayout? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      AppFlow? flow;
      final flowJson = json['flow'];
      if (flowJson is Map) {
        final screensJson = json['screens'] is Map
            ? (json['screens'] as Map)
            : const {};
        flow = _flowFromJson(flowJson, screensJson);
      }

      BottomNavConfig? nav;
      final navJson = json['bottomNav'];
      if (navJson is Map) nav = BottomNavConfig.fromJson(navJson);

      if (flow == null && nav == null) return null;
      return AppLayout(flow: flow, bottomNav: nav);
    } catch (_) {
      return null;
    }
  }

  static AppFlow _flowFromJson(Map flow, Map screens) {
    final fb = AppFlow.fallback;
    final contracts = <String, ScreenContract>{};
    screens.forEach((route, value) {
      if (value is Map) {
        contracts[route.toString()] = ScreenContract(
          role: value['role'] as String?,
          requiresAuth: value['requiresAuth'] == true,
          showOnce: value['showOnce'] == true,
        );
      }
    });
    return AppFlow(
      splash: flow['splash'] as String? ?? fb.splash,
      firstRun: flow['firstRun'] as String? ?? fb.firstRun,
      unauthenticated: flow['unauthenticated'] as String? ?? fb.unauthenticated,
      home: flow['home'] as String? ?? fb.home,
      onAuthSuccess: flow['onAuthSuccess'] as String?,
      onLogout: flow['onLogout'] as String?,
      contracts: contracts,
    );
  }
}

/// Server-driven bottom navigation: ordered tabs + colors.
class BottomNavConfig {
  final bool enabled;
  final NavStyle style;
  final List<NavTab> tabs;

  const BottomNavConfig({
    required this.enabled,
    required this.style,
    required this.tabs,
  });

  factory BottomNavConfig.fromJson(Map json) {
    final rawTabs = json['tabs'];
    final tabs = <NavTab>[];
    if (rawTabs is List) {
      for (final t in rawTabs) {
        if (t is Map) tabs.add(NavTab.fromJson(t));
      }
    }
    return BottomNavConfig(
      enabled: json['enabled'] != false,
      style: NavStyle.fromJson(json['style']),
      tabs: tabs,
    );
  }
}

/// A single bottom-nav tab. [kind] `stac` renders [screen] via
/// `StacDynamicScreen`; `native` resolves a feature-contributed screen (e.g.
/// a full-functionality chat/go-live) by [featureId].
class NavTab {
  final String screen;
  final String route;
  final String label;
  final String iconName;
  final String kind;
  final String? featureId;

  const NavTab({
    required this.screen,
    required this.route,
    required this.label,
    required this.iconName,
    required this.kind,
    this.featureId,
  });

  bool get isNative => kind == 'native';

  factory NavTab.fromJson(Map json) => NavTab(
        screen: json['screen'] as String? ?? '',
        route: json['route'] as String? ?? '',
        label: json['label'] as String? ?? '',
        iconName: json['icon'] as String? ?? 'home',
        kind: json['kind'] as String? ?? 'stac',
        featureId: json['featureId'] as String?,
      );
}

/// Bottom-nav colors, parsed from `#RRGGBB`/`#AARRGGBB` hex strings.
class NavStyle {
  final Color bg;
  final Color active;
  final Color inactive;

  const NavStyle({
    required this.bg,
    required this.active,
    required this.inactive,
  });

  factory NavStyle.fromJson(dynamic json) {
    final m = json is Map ? json : const {};
    return NavStyle(
      bg: _color(m['bg'], const Color(0xFFFFFFFF)),
      active: _color(m['active'], const Color(0xFF2563EB)),
      inactive: _color(m['inactive'], const Color(0xFF94A3B8)),
    );
  }

  static Color _color(dynamic hex, Color fallback) {
    if (hex is! String) return fallback;
    var s = hex.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return fallback;
    final value = int.tryParse(s, radix: 16);
    return value == null ? fallback : Color(value);
  }
}
