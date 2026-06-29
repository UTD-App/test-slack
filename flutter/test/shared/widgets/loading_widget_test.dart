import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/loading_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('renders a CircularProgressIndicator', (tester) async {
      await pumpApp(tester, const LoadingWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses the provided size for its SizedBox', (tester) async {
      await pumpApp(tester, const LoadingWidget(size: 40));

      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(LoadingWidget),
          matching: find.byType(SizedBox),
        ),
      );
      expect(box.width, 40);
      expect(box.height, 40);
    });

    testWidgets('defaults to white color when none provided', (tester) async {
      await pumpApp(tester, const LoadingWidget());

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, ColorManager.white);
      expect(indicator.strokeWidth, 2.5);
    });

    testWidgets('honours a custom color', (tester) async {
      await pumpApp(tester, const LoadingWidget(color: Colors.green));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, Colors.green);
    });
  });
}
