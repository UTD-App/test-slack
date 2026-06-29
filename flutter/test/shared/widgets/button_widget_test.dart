import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/button_widget.dart';
import 'package:utd_app/shared/widgets/loading_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('ButtonWidget', () {
    testWidgets('renders title text', (tester) async {
      await pumpApp(
        tester,
        ButtonWidget(title: 'Submit', onPressed: () {}),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        ButtonWidget(title: 'Submit', onPressed: () => tapped = true),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows LoadingWidget and no title when isLoading is true',
        (tester) async {
      await pumpApp(
        tester,
        ButtonWidget(title: 'Submit', isLoading: true, onPressed: () {}),
      );

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('is disabled (onPressed not fired) when onPressed is null',
        (tester) async {
      await pumpApp(
        tester,
        const ButtonWidget(title: 'Disabled', onPressed: null),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      // Tapping a null-callback button must not throw.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('renders a custom (non-String) title widget directly',
        (tester) async {
      await pumpApp(
        tester,
        ButtonWidget(
          title: const Icon(Icons.star, key: Key('custom-title')),
          onPressed: () {},
        ),
      );

      expect(find.byKey(const Key('custom-title')), findsOneWidget);
    });
  });
}
