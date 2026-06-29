import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/system_ui_style.dart';

/// Pure-const tests for kTransparentLightSystemUi.
///
/// This is the single source of truth for the edge-to-edge, dark-purple app's
/// system-bar appearance: both bars transparent with LIGHT (white) icons. The
/// invariants below guard against accidental regressions to opaque/dark bars.
void main() {
  group('kTransparentLightSystemUi', () {
    test('status bar is transparent', () {
      expect(kTransparentLightSystemUi.statusBarColor, Colors.transparent);
    });

    test('status bar icons are light (white) on Android and iOS', () {
      // Android uses statusBarIconBrightness; iOS uses statusBarBrightness.
      expect(kTransparentLightSystemUi.statusBarIconBrightness, Brightness.light);
      // iOS: a dark status-bar *background* brightness yields white icons.
      expect(kTransparentLightSystemUi.statusBarBrightness, Brightness.dark);
    });

    test('system navigation bar is transparent with no divider', () {
      expect(kTransparentLightSystemUi.systemNavigationBarColor, Colors.transparent);
      expect(kTransparentLightSystemUi.systemNavigationBarDividerColor,
          Colors.transparent);
    });

    test('system navigation bar icons are light (white)', () {
      expect(kTransparentLightSystemUi.systemNavigationBarIconBrightness,
          Brightness.light);
    });

    test('contrast enforcement is disabled (keeps the bar truly transparent)', () {
      expect(kTransparentLightSystemUi.systemNavigationBarContrastEnforced, isFalse);
    });

    test('is a const SystemUiOverlayStyle (identical to an inline equivalent)', () {
      const equivalent = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      );
      // const canonicalisation -> identical instance.
      expect(identical(kTransparentLightSystemUi, equivalent), isTrue);
    });
  });
}
