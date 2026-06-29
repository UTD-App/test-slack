import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/localization/app_translations.dart';

/// Pure-Dart tests for the localization logic.
///
/// SKIPPED: LocalizationExtensions (context.tr / context.trArgs / context.translations)
/// in lib/localization/localization_extensions.dart are thin BuildContext wrappers
/// over AppTranslations.of(context), which calls Localizations.of — that needs a
/// real widget tree, so it is not pure-Dart-testable. Instead we test the
/// underlying pure engine, AppTranslations.translate / translateWithArgs, directly.
void main() {
  AppTranslations build(String locale) => AppTranslations(
        const {
          'en': {
            'hello': 'Hello',
            'welcome': 'Welcome back, {name}!',
            'two': '{a} and {b}',
          },
          'ar': {
            'hello': 'مرحبا',
            // 'welcome' intentionally missing in ar to test fallback
          },
        },
        locale,
      );

  group('AppTranslations.translate — fallback chain', () {
    test('current-locale hit', () {
      expect(build('ar').translate('hello'), 'مرحبا');
      expect(build('en').translate('hello'), 'Hello');
    });

    test('falls back to English when missing in current locale', () {
      expect(build('ar').translate('welcome'), 'Welcome back, {name}!');
    });

    test('falls back to the raw key when missing everywhere', () {
      expect(build('ar').translate('nope.key'), 'nope.key');
      expect(build('en').translate('totally.missing'), 'totally.missing');
    });

    test('unknown locale falls back to English', () {
      expect(build('fr').translate('hello'), 'Hello');
    });
  });

  group('AppTranslations.translateWithArgs', () {
    test('interpolates a single placeholder', () {
      expect(
        build('en').translateWithArgs('welcome', {'name': 'John'}),
        'Welcome back, John!',
      );
    });

    test('interpolates multiple placeholders', () {
      expect(
        build('en').translateWithArgs('two', {'a': 'X', 'b': 'Y'}),
        'X and Y',
      );
    });

    test('no args leaves placeholders intact', () {
      expect(
        build('en').translateWithArgs('welcome', const {}),
        'Welcome back, {name}!',
      );
    });

    test('extra/unused args are ignored', () {
      expect(
        build('en').translateWithArgs('hello', {'unused': 'z'}),
        'Hello',
      );
    });

    test('missing key returns the raw key (no interpolation target)', () {
      expect(
        build('en').translateWithArgs('missing', {'name': 'John'}),
        'missing',
      );
    });

    test('replaces all occurrences of a repeated placeholder', () {
      final t = AppTranslations(
        const {
          'en': {'echo': '{x}-{x}'},
        },
        'en',
      );
      expect(t.translateWithArgs('echo', {'x': 'A'}), 'A-A');
    });
  });

  group('AppTranslations — empty map', () {
    test('empty translations return raw key', () {
      const t = AppTranslations({}, 'en');
      expect(t.translate('any'), 'any');
    });
  });
}
