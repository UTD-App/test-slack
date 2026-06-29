import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/widgets/text_input_widget.dart';

import '../../support/widget_harness.dart';

void main() {
  group('TextInputWidget', () {
    testWidgets('renders a TextFormField with the hint text', (tester) async {
      await pumpApp(tester, const TextInputWidget('Enter name'));

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('shows initialValue', (tester) async {
      await pumpApp(
        tester,
        const TextInputWidget('hint', initialValue: 'preset'),
      );

      expect(find.text('preset'), findsOneWidget);
    });

    testWidgets('onChanged fires with typed value', (tester) async {
      String? changed;
      await pumpApp(
        tester,
        TextInputWidget('hint', onChanged: (v) => changed = v),
      );

      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();

      expect(changed, 'abc');
    });

    testWidgets('obscures text when isPassword is true', (tester) async {
      await pumpApp(
        tester,
        const TextInputWidget('password', isPassword: true),
      );

      // EditableText is the inner field; obscureText must propagate to it.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
    });

    testWidgets('does not obscure text by default', (tester) async {
      await pumpApp(tester, const TextInputWidget('plain'));

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isFalse);
    });

    testWidgets('validator wiring surfaces error text on validate()',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpApp(
        tester,
        Form(
          key: formKey,
          child: TextInputWidget(
            'email',
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required field' : null,
          ),
        ),
      );

      // No error before validation runs.
      expect(find.text('Required field'), findsNothing);

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('passes a valid value (no error shown)', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpApp(
        tester,
        Form(
          key: formKey,
          child: TextInputWidget(
            'email',
            initialValue: 'filled',
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Required field' : null,
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
      expect(find.text('Required field'), findsNothing);
    });

    testWidgets('renders a prefix IconData icon', (tester) async {
      await pumpApp(
        tester,
        const TextInputWidget('search', prefixIcon: Icons.search),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('suffix IconButton fires onPressed', (tester) async {
      var pressed = false;
      await pumpApp(
        tester,
        TextInputWidget(
          'pwd',
          suffixIcon: Icons.visibility,
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('respects readOnly + onTap', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        TextInputWidget(
          'readonly',
          readOnly: true,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
