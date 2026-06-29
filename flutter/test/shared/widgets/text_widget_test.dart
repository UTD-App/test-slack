import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/text_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('TextWidget', () {
    testWidgets('renders the provided text', (tester) async {
      await pumpApp(tester, const TextWidget('Hello World'));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('applies the provided style, align, maxLines and overflow',
        (tester) async {
      const style = TextStyle(fontSize: 22, color: Colors.red);
      await pumpApp(
        tester,
        const TextWidget(
          'Styled',
          style: style,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );

      final text = tester.widget<Text>(find.text('Styled'));
      expect(text.style, style);
      expect(text.textAlign, TextAlign.center);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('does not wrap in Padding when padding is null',
        (tester) async {
      await pumpApp(tester, const TextWidget('No padding'));

      // Only the harness should contribute Padding widgets; the widget itself
      // returns a bare Text. The Text must not be a direct child of a Padding
      // created by TextWidget. Easiest robust check: no Padding directly wraps
      // our text inside the TextWidget subtree.
      expect(
        find.descendant(
          of: find.byType(TextWidget),
          matching: find.byType(Padding),
        ),
        findsNothing,
      );
    });

    testWidgets('wraps in Padding when padding is provided', (tester) async {
      const padding = EdgeInsets.all(12);
      await pumpApp(
        tester,
        const TextWidget('Padded', padding: padding),
      );

      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(TextWidget),
          matching: find.byType(Padding),
        ),
      );
      expect(paddingWidget.padding, padding);
      expect(find.text('Padded'), findsOneWidget);
    });
  });
}
