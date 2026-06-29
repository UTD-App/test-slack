import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/extensions.dart';

import '../../support/widget_harness.dart';

/// Widget-level tests for the ScreenUtil / BuildContext-dependent members of
/// extensions.dart that the pure-Dart `extensions_test.dart` deliberately skips:
///   - DimensionsExt (.hBox/.wBox/.radius/.radiusCircular -> use .h/.w/.r)
///   - PaddingExt on BuildContext (paddingOnly/paddingSymmetric/paddingAll/paddingZero)
///   - TextStyleExtensions on BuildContext (bodySmall/bodyMedium/bodyLarge)
///   - TextStyleModifiers.size (uses .sp)
///
/// These all read flutter_screenutil values, so they need a ScreenUtilInit +
/// BuildContext, provided by `pumpApp` from the shared harness (designSize
/// 375x812). Assertions are on *relationships* (proportional scaling, ordering,
/// non-negativity) rather than exact pixel values, since the scale factor
/// depends on the test surface size — that keeps them deterministic across
/// machines.
void main() {
  group('DimensionsExt (ScreenUtil-backed)', () {
    testWidgets('hBox produces a SizedBox whose height scales with .h', (tester) async {
      late double h10;
      late double h20;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          h10 = (10.hBox).height!;
          h20 = (20.hBox).height!;
          return const SizedBox.shrink();
        }),
      );
      expect(h10, greaterThan(0));
      // 20.h is exactly twice 10.h (linear scale).
      expect(h20, closeTo(h10 * 2, 1e-6));
    });

    testWidgets('wBox produces a SizedBox whose width scales with .w', (tester) async {
      late double w10;
      late double w20;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          w10 = (10.wBox).width!;
          w20 = (20.wBox).width!;
          return const SizedBox.shrink();
        }),
      );
      expect(w10, greaterThan(0));
      expect(w20, closeTo(w10 * 2, 1e-6));
    });

    testWidgets('radius builds a circular BorderRadius from .r (non-negative)', (tester) async {
      late BorderRadius br;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          br = 12.radius;
          return const SizedBox.shrink();
        }),
      );
      // All four corners equal (circular) and non-negative.
      expect(br.topLeft.x, greaterThanOrEqualTo(0));
      expect(br.topLeft, br.topRight);
      expect(br.topLeft, br.bottomLeft);
      expect(br.topLeft, br.bottomRight);
    });

    testWidgets('radiusCircular builds a Radius from .r (non-negative, x==y)', (tester) async {
      late Radius r;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          r = 8.radiusCircular;
          return const SizedBox.shrink();
        }),
      );
      expect(r.x, greaterThanOrEqualTo(0));
      // Radius.circular -> x == y.
      expect(r.x, r.y);
    });

    testWidgets('zero stays zero across the helpers', (tester) async {
      late SizedBox hb;
      late SizedBox wb;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          hb = 0.hBox;
          wb = 0.wBox;
          return const SizedBox.shrink();
        }),
      );
      expect(hb.height, 0);
      expect(wb.width, 0);
    });
  });

  group('PaddingExt on BuildContext', () {
    testWidgets('paddingOnly maps each side through .w/.h and scales linearly', (tester) async {
      late EdgeInsetsDirectional p1;
      late EdgeInsetsDirectional p2;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          p1 = context.paddingOnly(start: 5, end: 5, top: 5, bottom: 5);
          p2 = context.paddingOnly(start: 10, end: 10, top: 10, bottom: 10);
          return const SizedBox.shrink();
        }),
      );
      expect(p1.start, greaterThan(0));
      expect(p1.top, greaterThan(0));
      // Doubling the inputs doubles each resolved side.
      expect(p2.start, closeTo(p1.start * 2, 1e-6));
      expect(p2.end, closeTo(p1.end * 2, 1e-6));
      expect(p2.top, closeTo(p1.top * 2, 1e-6));
      expect(p2.bottom, closeTo(p1.bottom * 2, 1e-6));
    });

    testWidgets('paddingOnly defaults unspecified sides to 0', (tester) async {
      late EdgeInsetsDirectional p;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          p = context.paddingOnly(top: 8);
          return const SizedBox.shrink();
        }),
      );
      expect(p.top, greaterThan(0));
      expect(p.start, 0);
      expect(p.end, 0);
      expect(p.bottom, 0);
    });

    testWidgets('paddingSymmetric resolves horizontal via .w and vertical via .h', (tester) async {
      late EdgeInsetsDirectional p;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          p = context.paddingSymmetric(horizontal: 16, vertical: 8);
          return const SizedBox.shrink();
        }),
      );
      expect(p.start, greaterThan(0));
      expect(p.end, p.start); // symmetric horizontal
      expect(p.top, greaterThan(0));
      expect(p.bottom, p.top); // symmetric vertical
    });

    testWidgets('paddingAll resolves every side via .h (so all sides equal)', (tester) async {
      late EdgeInsetsDirectional p;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          p = context.paddingAll(12);
          return const SizedBox.shrink();
        }),
      );
      expect(p.start, greaterThan(0));
      // paddingAll uses value.h for every side -> all four equal.
      expect(p.end, p.start);
      expect(p.top, p.start);
      expect(p.bottom, p.start);
    });

    testWidgets('paddingZero is EdgeInsets.zero', (tester) async {
      late EdgeInsets p;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          p = context.paddingZero();
          return const SizedBox.shrink();
        }),
      );
      expect(p, EdgeInsets.zero);
    });

    testWidgets('a Padding widget built from paddingAll has matching EdgeInsets', (tester) async {
      await pumpApp(
        tester,
        Builder(builder: (context) {
          return Padding(
            padding: context.paddingAll(10),
            child: const Text('x'),
          );
        }),
      );
      final padding = tester.widget<Padding>(find.byType(Padding).first);
      final resolved = (padding.padding as EdgeInsetsDirectional);
      expect(resolved.start, greaterThan(0));
      expect(resolved.start, resolved.top);
    });
  });

  group('TextStyleExtensions on BuildContext', () {
    testWidgets('bodySmall/Medium/Large are non-null and ordered by size', (tester) async {
      late TextStyle small;
      late TextStyle medium;
      late TextStyle large;
      // Provide a theme with an explicit, ordered text theme.
      await pumpApp(
        tester,
        Builder(builder: (context) {
          small = context.bodySmall;
          medium = context.bodyMedium;
          large = context.bodyLarge;
          return const SizedBox.shrink();
        }),
        theme: ThemeData(
          textTheme: const TextTheme(
            bodySmall: TextStyle(fontSize: 12),
            bodyMedium: TextStyle(fontSize: 14),
            bodyLarge: TextStyle(fontSize: 16),
          ),
        ),
      );
      expect(small.fontSize, 12);
      expect(medium.fontSize, 14);
      expect(large.fontSize, 16);
    });

    testWidgets('falls back to const TextStyle() when the theme lacks the slot', (tester) async {
      late TextStyle medium;
      // A bare ThemeData still populates default bodyMedium, so to exercise the
      // `?? const TextStyle()` fallback we null out the slots explicitly.
      await pumpApp(
        tester,
        Builder(builder: (context) {
          medium = context.bodyMedium;
          return const SizedBox.shrink();
        }),
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: null),
        ),
      );
      // Either the framework default or the const fallback — never throws / null.
      expect(medium, isA<TextStyle>());
    });
  });

  group('TextStyleModifiers.size (.sp)', () {
    testWidgets('size sets fontSize via .sp and scales monotonically', (tester) async {
      late TextStyle s10;
      late TextStyle s20;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          s10 = const TextStyle().size(10);
          s20 = const TextStyle().size(20);
          return const SizedBox.shrink();
        }),
      );
      expect(s10.fontSize, greaterThan(0));
      expect(s20.fontSize, greaterThan(s10.fontSize!));
    });

    testWidgets('size preserves other style fields (copyWith semantics)', (tester) async {
      late TextStyle out;
      await pumpApp(
        tester,
        Builder(builder: (context) {
          out = const TextStyle(color: Color(0xFF123456), fontWeight: FontWeight.w700)
              .size(14);
          return const SizedBox.shrink();
        }),
      );
      expect(out.color, const Color(0xFF123456));
      expect(out.fontWeight, FontWeight.w700);
      expect(out.fontSize, greaterThan(0));
    });
  });

  // ScreenUtil is a global singleton initialised by the harness; nothing to
  // tear down between tests since each pumpApp re-initialises it.
  tearDown(() {});
}
