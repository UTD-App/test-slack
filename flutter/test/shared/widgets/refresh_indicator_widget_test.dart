import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/refresh_indicator_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('RefreshIndicatorWidget', () {
    testWidgets('renders its child and a RefreshIndicator', (tester) async {
      await pumpApp(
        tester,
        RefreshIndicatorWidget(
          onRefresh: () async {},
          child: ListView(
            children: const [
              SizedBox(height: 200, child: Text('item-1')),
            ],
          ),
        ),
      );

      expect(find.text('item-1'), findsOneWidget);
      // RefreshIndicator.adaptive resolves to a RefreshIndicator on the
      // default (non-iOS) test platform.
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('invokes onRefresh on a pull-to-refresh gesture',
        (tester) async {
      var refreshed = false;
      await pumpApp(
        tester,
        RefreshIndicatorWidget(
          onRefresh: () async {
            refreshed = true;
          },
          child: ListView(
            children: const [
              SizedBox(height: 600, child: Text('pullable')),
            ],
          ),
        ),
      );

      await tester.fling(find.text('pullable'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, isTrue);

      // Let the refresh animation settle to avoid pending-timer failures.
      await tester.pumpAndSettle();
    });
  });
}
