import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/config/app_theme.dart';
import 'package:utd_app/shared/core/color_manager.dart';

/// Pure-Dart tests for [parseHexColor], [AppPalette.fromJson] field defaulting,
/// and the [AppThemeProvider] global.
void main() {
  group('parseHexColor', () {
    test('parses #RRGGBB by prepending opaque alpha', () {
      expect(parseHexColor('#2563EB'), const Color(0xFF2563EB));
    });

    test('parses RRGGBB without a leading hash', () {
      expect(parseHexColor('2563EB'), const Color(0xFF2563EB));
    });

    test('parses #AARRGGBB with explicit alpha', () {
      expect(parseHexColor('#802563EB'), const Color(0x802563EB));
    });

    test('trims surrounding whitespace', () {
      expect(parseHexColor('  #2563EB  '), const Color(0xFF2563EB));
    });

    test('is case-insensitive on the hex digits', () {
      expect(parseHexColor('#abcdef'), const Color(0xFFABCDEF));
    });

    test('returns null for null input', () {
      expect(parseHexColor(null), isNull);
    });

    test('returns null for a wrong-length string', () {
      expect(parseHexColor('#FFF'), isNull); // 3 digits
      expect(parseHexColor('#FFFFF'), isNull); // 5 digits
      expect(parseHexColor('#1234567'), isNull); // 7 digits
    });

    test('returns null for non-hex characters', () {
      expect(parseHexColor('#GGGGGG'), isNull);
    });

    test('returns null for an empty string', () {
      expect(parseHexColor(''), isNull);
    });
  });

  group('AppPalette.fromJson', () {
    test('parses every field from valid hex', () {
      final p = AppPalette.fromJson({
        'primary': '#111111',
        'accent': '#222222',
        'bg_dark': '#333333',
        'bg_gradient_1': '#444444',
        'bg_gradient_2': '#555555',
        'bg_gradient_3': '#666666',
        'card_bg': '#777777',
        'card_border': '#888888',
        'text_primary': '#999999',
        'text_secondary': '#AAAAAA',
      });
      expect(p.primary, const Color(0xFF111111));
      expect(p.accent, const Color(0xFF222222));
      expect(p.bgDark, const Color(0xFF333333));
      expect(p.bgGradient,
          [const Color(0xFF444444), const Color(0xFF555555), const Color(0xFF666666)]);
      expect(p.cardBg, const Color(0xFF777777));
      expect(p.cardBorder, const Color(0xFF888888));
      expect(p.textPrimary, const Color(0xFF999999));
      expect(p.textSecondary, const Color(0xFFAAAAAA));
    });

    test('falls back to the lumia tokens for an empty map', () {
      final p = AppPalette.fromJson(const {});
      expect(p.primary, ColorManager.lumiaAccent);
      expect(p.accent, ColorManager.lumiaAccentLight);
      expect(p.bgDark, ColorManager.lumiaBgDark);
      expect(p.bgGradient, ColorManager.lumiaBgGradient);
      expect(p.cardBg, ColorManager.lumiaCardBg);
      expect(p.cardBorder, ColorManager.lumiaCardBorder);
      expect(p.textPrimary, ColorManager.lumiaTextPrimary);
      expect(p.textSecondary, ColorManager.lumiaTextSecondary);
    });

    test('falls back per-field for invalid/blank values', () {
      final p = AppPalette.fromJson({
        'primary': '#00FF00',
        'accent': 'not-a-color',
        'bg_dark': '',
      });
      expect(p.primary, const Color(0xFF00FF00)); // valid → used
      expect(p.accent, AppPalette.fallback.accent); // invalid → fallback
      expect(p.bgDark, AppPalette.fallback.bgDark); // blank → fallback
    });

    test('a single missing gradient stop falls back only for that stop', () {
      final p = AppPalette.fromJson({
        'bg_gradient_1': '#010101',
        // _2 missing
        'bg_gradient_3': '#030303',
      });
      expect(p.bgGradient[0], const Color(0xFF010101));
      expect(p.bgGradient[1], AppPalette.fallback.bgGradient[1]);
      expect(p.bgGradient[2], const Color(0xFF030303));
    });
  });

  group('AppPalette defaults / fallback', () {
    test('default constructor equals the lumia tokens', () {
      const p = AppPalette();
      expect(p.primary, ColorManager.lumiaAccent);
      expect(p.bgGradient, ColorManager.lumiaBgGradient);
    });

    test('fallback is the default palette', () {
      expect(AppPalette.fallback.primary, const AppPalette().primary);
    });
  });

  group('AppThemeProvider', () {
    tearDown(() => AppThemeProvider.current = AppPalette.fallback);

    test('defaults to the fallback palette', () {
      AppThemeProvider.current = AppPalette.fallback;
      expect(AppThemeProvider.current.primary, AppPalette.fallback.primary);
    });

    test('can be replaced with a runtime palette', () {
      AppThemeProvider.current = AppPalette.fromJson({'primary': '#123456'});
      expect(AppThemeProvider.current.primary, const Color(0xFF123456));
    });
  });
}
