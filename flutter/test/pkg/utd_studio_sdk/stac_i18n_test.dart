import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/src/core/stac_i18n.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// A catalog-backed fake translate port: returns the value for a known key,
/// else echoes the key back (the app i18n's "missing" contract).
String Function(BuildContext, String) catalog(Map<String, String> entries) =>
    (ctx, key) => entries[key] ?? key;

void main() {
  // localizeStac reads StudioRuntime.instance.translate — wire/clear per test.
  tearDown(() => StudioRuntime.instance.translate = null);

  /// Runs [localizeStac] with a real BuildContext via a pumped widget.
  Future<Map<String, dynamic>> run(
    WidgetTester tester,
    Map<String, dynamic> json,
  ) async {
    late Map<String, dynamic> result;
    await tester.pumpWidget(
      Builder(builder: (context) {
        result = localizeStac(json, context);
        return const SizedBox();
      }),
    );
    return result;
  }

  testWidgets('no translate port wired → returns input unchanged', (t) async {
    StudioRuntime.instance.translate = null;
    final input = {'type': 'text', 'tKey': 'auth.login', 'data': 'x'};
    final out = await run(t, input);
    expect(identical(out, input), isTrue);
  });

  testWidgets('tKey resolves and strips the binding', (t) async {
    StudioRuntime.instance.translate = catalog({'auth.login': 'Login'});
    final out = await run(
      t,
      {'type': 'text', 'tKey': 'auth.login', 'binding': 't.auth.login'},
    );
    expect(out['data'], 'Login');
    expect(out.containsKey('binding'), isFalse);
  });

  testWidgets('t.* binding is treated as a translation key', (t) async {
    StudioRuntime.instance.translate = catalog({'auth.email': 'Email'});
    final out = await run(t, {'type': 'text', 'binding': 't.auth.email'});
    expect(out['data'], 'Email');
    expect(out.containsKey('binding'), isFalse);
  });

  testWidgets('missing key keeps the literal data fallback (no raw key shown)',
      (t) async {
    StudioRuntime.instance.translate = catalog({}); // every key misses
    final out = await run(
      t,
      {'type': 'text', 'tKey': 'auth.unknown', 'data': 'Fallback'},
    );
    expect(out['data'], 'Fallback');
  });

  testWidgets('data-as-key fallback: a literal that IS a catalog key is swapped',
      (t) async {
    StudioRuntime.instance.translate = catalog({'app.hello': 'Hi!'});
    final out = await run(t, {'type': 'text', 'data': 'app.hello'});
    expect(out['data'], 'Hi!');
  });

  testWidgets('plain literal text is never touched (self-guarding)', (t) async {
    StudioRuntime.instance.translate = catalog({'app.hello': 'Hi!'});
    final out = await run(t, {'type': 'text', 'data': 'Welcome!'});
    expect(out['data'], 'Welcome!');
  });

  testWidgets('tHint translates placeholder and hintText', (t) async {
    StudioRuntime.instance.translate =
        catalog({'auth.email_hint': 'Your email'});
    final out = await run(
      t,
      {'type': 'utdTextField', 'tHint': 'auth.email_hint'},
    );
    expect(out['placeholder'], 'Your email');
    expect(out['hintText'], 'Your email');
  });

  testWidgets('tHint miss leaves placeholder/hintText absent', (t) async {
    StudioRuntime.instance.translate = catalog({});
    final out = await run(
      t,
      {'type': 'utdTextField', 'tHint': 'auth.missing'},
    );
    expect(out.containsKey('placeholder'), isFalse);
    expect(out.containsKey('hintText'), isFalse);
  });

  testWidgets('walks nested children and translates each Text', (t) async {
    StudioRuntime.instance.translate =
        catalog({'a.one': 'One', 'a.two': 'Two'});
    final out = await run(t, {
      'type': 'column',
      'children': [
        {'type': 'text', 'tKey': 'a.one'},
        {
          'type': 'container',
          'child': {'type': 'text', 'tKey': 'a.two'},
        },
      ],
    });
    final children = out['children'] as List;
    expect((children[0] as Map)['data'], 'One');
    expect(((children[1] as Map)['child'] as Map)['data'], 'Two');
  });

  testWidgets('source JSON is not mutated on a touched branch', (t) async {
    StudioRuntime.instance.translate = catalog({'auth.login': 'Login'});
    final input = {'type': 'text', 'tKey': 'auth.login', 'binding': 't.auth.login'};
    await run(t, input);
    // Original still has its binding and no resolved data.
    expect(input['binding'], 't.auth.login');
    expect(input.containsKey('data'), isFalse);
  });
}
