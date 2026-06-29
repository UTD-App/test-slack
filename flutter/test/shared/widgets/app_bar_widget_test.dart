import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/app_bar_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('AppBarWidget', () {
    testWidgets('renders a String title', (tester) async {
      await pumpApp(tester, const AppBarWidget(title: 'My Title'));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('renders a custom (non-String) title widget', (tester) async {
      await pumpApp(
        tester,
        const AppBarWidget(
          title: Icon(Icons.home, key: Key('custom-app-bar-title')),
        ),
      );

      expect(find.byKey(const Key('custom-app-bar-title')), findsOneWidget);
    });

    testWidgets('shows a back button when isShowBack is true', (tester) async {
      await pumpApp(tester, const AppBarWidget(title: 'X'));

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    testWidgets('hides the leading back button when isShowBack is false',
        (tester) async {
      await pumpApp(
        tester,
        const AppBarWidget(title: 'X', isShowBack: false),
      );

      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    });

    testWidgets('back button invokes custom onLeadingPressed', (tester) async {
      var pressed = false;
      await pumpApp(
        tester,
        AppBarWidget(
          title: 'X',
          onLeadingPressed: () async {
            pressed = true;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('renders provided actions', (tester) async {
      await pumpApp(
        tester,
        const AppBarWidget(
          title: 'X',
          actions: [Icon(Icons.search, key: Key('action-search'))],
        ),
      );

      expect(find.byKey(const Key('action-search')), findsOneWidget);
    });

    testWidgets('preferredSize uses default AppBar height when height is null',
        (tester) async {
      const widget = AppBarWidget(title: 'X');
      expect(widget.preferredSize.height, AppBar().preferredSize.height);
    });

    testWidgets('preferredSize honours an explicit height', (tester) async {
      const widget = AppBarWidget(title: 'X', height: 72);
      expect(widget.preferredSize.height, 72);
    });
  });
}
