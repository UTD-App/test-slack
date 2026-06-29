import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/text_button_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('TextButtonWidget', () {
    testWidgets('renders its content child', (tester) async {
      await pumpApp(
        tester,
        TextButtonWidget(
          onTap: () {},
          content: const Text('Tap me'),
        ),
      );

      expect(find.text('Tap me'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('fires onTap when pressed', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        TextButtonWidget(
          onTap: () => tapped = true,
          content: const Text('Tap me'),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
