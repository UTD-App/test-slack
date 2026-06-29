import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/color_manager.dart';

/// Pure-Dart tests for ColorManager.
///
/// NOTE: ColorManager exposes NO hex-parsing helpers — it is a bag of
/// `static const Color` design tokens. So instead of testing parsing, we pin a
/// representative set of token ARGB values (regression guard against accidental
/// edits), and assert the structural invariants of the gradient lists (length,
/// non-empty, opaque/translucent alpha where it matters).
void main() {
  group('ColorManager — core token values', () {
    test('brand primary palette', () {
      expect(ColorManager.primary, const Color(0xFF2563EB));
      expect(ColorManager.primaryDark, const Color(0xFF1D4ED8));
      expect(ColorManager.primaryLight, const Color(0xFF60A5FA));
    });

    test('neutrals', () {
      expect(ColorManager.white, const Color(0xFFFFFFFF));
      expect(ColorManager.black, const Color(0xFF000000));
      expect(ColorManager.blackColor, const Color(0xFF0F172A));
    });

    test('semantic colors', () {
      expect(ColorManager.error, const Color(0xFFDC2626));
      expect(ColorManager.success, const Color(0xFF16A34A));
      expect(ColorManager.warning, const Color(0xFFF59E0B));
      expect(ColorManager.info, const Color(0xFF0EA5E9));
    });

    test('transparent is fully transparent', () {
      expect(ColorManager.transparent, Colors.transparent);
      expect(ColorManager.transparent.a, 0.0);
    });
  });

  group('ColorManager — alpha semantics', () {
    test('opaque tokens are fully opaque (alpha 0xFF)', () {
      expect(ColorManager.primary.a, 1.0);
      expect(ColorManager.white.a, 1.0);
      expect(ColorManager.lumiaAccent.a, 1.0);
    });

    test('frosted tints are translucent (alpha < 0xFF, > 0)', () {
      // frostedFill = 0x1AFFFFFF (~10% white), frostedBorder = 0x33FFFFFF (~20%)
      expect(ColorManager.frostedFill.a, greaterThan(0.0));
      expect(ColorManager.frostedFill.a, lessThan(1.0));
      expect(ColorManager.frostedBorder.a, greaterThan(ColorManager.frostedFill.a));
    });

    test('buleShadw shadow token is translucent', () {
      // 0x332563EB — same RGB as primary but ~20% alpha.
      expect(ColorManager.buleShadw.a, lessThan(1.0));
      expect(ColorManager.buleShadw.a, greaterThan(0.0));
    });

    test('muted pink CTA gradient is translucent vs solid pink CTA', () {
      for (final c in ColorManager.pinkCtaGradient) {
        expect(c.a, 1.0, reason: 'solid CTA must be opaque');
      }
      for (final c in ColorManager.pinkCtaGradientMuted) {
        expect(c.a, lessThan(1.0), reason: 'muted CTA must be translucent');
      }
    });
  });

  group('ColorManager — gradient list invariants', () {
    test('gender gradients have exactly 2 stops', () {
      expect(ColorManager.maleContainer.length, 2);
      expect(ColorManager.femaleContainer.length, 2);
    });

    test('lumia background gradient has 3 stops, accent/card have 2', () {
      expect(ColorManager.lumiaBgGradient.length, 3);
      expect(ColorManager.lumiaCardGradient.length, 2);
      expect(ColorManager.lumiaAccentGradient.length, 2);
    });

    test('auth background gradient has 3 stops', () {
      expect(ColorManager.authBgGradient.length, 3);
    });

    test('nav selected + pink CTA gradients have 2 stops', () {
      expect(ColorManager.navSelectedGradient.length, 2);
      expect(ColorManager.pinkCtaGradient.length, 2);
      expect(ColorManager.pinkCtaGradientMuted.length, 2);
    });

    test('all gradient lists are non-empty', () {
      final gradients = <List<Color>>[
        ColorManager.maleContainer,
        ColorManager.femaleContainer,
        ColorManager.lumiaBgGradient,
        ColorManager.lumiaCardGradient,
        ColorManager.lumiaAccentGradient,
        ColorManager.navSelectedGradient,
        ColorManager.authBgGradient,
        ColorManager.pinkCtaGradient,
        ColorManager.pinkCtaGradientMuted,
      ];
      for (final g in gradients) {
        expect(g, isNotEmpty);
      }
    });
  });

  group('ColorManager — lumia theme tokens', () {
    test('pinned values', () {
      expect(ColorManager.lumiaBgDark, const Color(0xFF463394));
      expect(ColorManager.lumiaAccent, const Color(0xFFBE4AFF));
      expect(ColorManager.lumiaGold, const Color(0xFFFFD700));
      expect(ColorManager.walletGreen, const Color(0xFF2ED9B0));
      expect(ColorManager.walletRed, const Color(0xFFFF5A6E));
    });
  });
}
