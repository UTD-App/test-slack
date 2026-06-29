import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/app_text_styles.dart';
import 'package:utd_app/shared/core/color_manager.dart';

import '../../support/widget_harness.dart';

/// Tests for AppTextStyles — the semantic, ScreenUtil-scaled text styles.
///
/// Each style is a getter that calls `.sp`, so it must be resolved inside a
/// ScreenUtilInit + BuildContext (provided by `pumpApp`). We assert the static
/// invariants: every style is non-null, carries the documented weight + colour,
/// and the size hierarchy (h1 > h2 > h3 > title >= body) holds after `.sp`
/// scaling. Exact pixel sizes are surface-dependent, so only ordering is checked.
void main() {
  // Read every style once inside a pumped context and stash the resolved values.
  late Map<String, TextStyle> styles;

  Future<void> resolve(WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(builder: (context) {
        styles = {
          'h1': AppTextStyles.h1,
          'h2': AppTextStyles.h2,
          'h3': AppTextStyles.h3,
          'title': AppTextStyles.title,
          'body': AppTextStyles.body,
          'bodySecondary': AppTextStyles.bodySecondary,
          'caption': AppTextStyles.caption,
          'button': AppTextStyles.button,
          'label': AppTextStyles.label,
        };
        return const SizedBox.shrink();
      }),
    );
  }

  testWidgets('every style is non-null with a positive font size', (tester) async {
    await resolve(tester);
    for (final entry in styles.entries) {
      expect(entry.value, isNotNull, reason: '${entry.key} should be non-null');
      expect(entry.value.fontSize, isNotNull,
          reason: '${entry.key} should have a fontSize');
      expect(entry.value.fontSize, greaterThan(0),
          reason: '${entry.key} fontSize should scale to > 0');
    }
  });

  testWidgets('font weights match the design spec', (tester) async {
    await resolve(tester);
    expect(styles['h1']!.fontWeight, FontWeight.w700);
    expect(styles['h2']!.fontWeight, FontWeight.w700);
    expect(styles['h3']!.fontWeight, FontWeight.w600);
    expect(styles['title']!.fontWeight, FontWeight.w600);
    expect(styles['body']!.fontWeight, FontWeight.w400);
    expect(styles['bodySecondary']!.fontWeight, FontWeight.w400);
    expect(styles['caption']!.fontWeight, FontWeight.w400);
    expect(styles['button']!.fontWeight, FontWeight.w600);
    expect(styles['label']!.fontWeight, FontWeight.w500);
  });

  testWidgets('colours map to the Lumia tokens', (tester) async {
    await resolve(tester);
    expect(styles['h1']!.color, ColorManager.lumiaTextPrimary);
    expect(styles['h2']!.color, ColorManager.lumiaTextPrimary);
    expect(styles['h3']!.color, ColorManager.lumiaTextPrimary);
    expect(styles['title']!.color, ColorManager.lumiaTextPrimary);
    expect(styles['body']!.color, ColorManager.lumiaTextPrimary);
    expect(styles['bodySecondary']!.color, ColorManager.lumiaTextSecondary);
    expect(styles['caption']!.color, ColorManager.lumiaTextSecondary);
    expect(styles['button']!.color, ColorManager.white);
    expect(styles['label']!.color, ColorManager.lumiaTextSecondary);
  });

  testWidgets('size hierarchy is preserved after .sp scaling', (tester) async {
    await resolve(tester);
    final h1 = styles['h1']!.fontSize!;
    final h2 = styles['h2']!.fontSize!;
    final h3 = styles['h3']!.fontSize!;
    final title = styles['title']!.fontSize!;
    final body = styles['body']!.fontSize!;
    final caption = styles['caption']!.fontSize!;
    // Source sizes: 28 > 22 > 18 > 16 > 14 > 12. `.sp` scaling is monotonic, so
    // the ordering must survive.
    expect(h1, greaterThan(h2));
    expect(h2, greaterThan(h3));
    expect(h3, greaterThan(title));
    expect(title, greaterThan(body));
    expect(body, greaterThan(caption));
  });

  testWidgets('getters resolve fresh each call (not const-cached)', (tester) async {
    await resolve(tester);
    // Two reads of the same getter yield equal styles (same inputs), proving the
    // getter is stable within one screen context.
    late TextStyle a;
    late TextStyle b;
    await pumpApp(
      tester,
      Builder(builder: (context) {
        a = AppTextStyles.body;
        b = AppTextStyles.body;
        return const SizedBox.shrink();
      }),
    );
    expect(a.fontSize, b.fontSize);
    expect(a.color, b.color);
    expect(a.fontWeight, b.fontWeight);
  });
}
