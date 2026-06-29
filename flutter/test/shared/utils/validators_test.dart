import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/utils/validators.dart';

/// Pure-Dart unit tests for the shared input validators (no widgets, no I/O).
void main() {
  group('Validators predicates', () {
    test('isNotEmpty', () {
      expect(Validators.isNotEmpty(null), isFalse);
      expect(Validators.isNotEmpty(''), isFalse);
      expect(Validators.isNotEmpty('   '), isFalse);
      expect(Validators.isNotEmpty('x'), isTrue);
    });

    test('isEmail', () {
      expect(Validators.isEmail('user@example.com'), isTrue);
      expect(Validators.isEmail('  user@example.com  '), isTrue); // trimmed
      expect(Validators.isEmail('a.b+c@sub.domain.co'), isTrue);
      expect(Validators.isEmail('bad'), isFalse);
      expect(Validators.isEmail('a@b'), isFalse); // no TLD dot
      expect(Validators.isEmail('@b.com'), isFalse);
    });

    test('isPhone tolerates spaces, dashes and parentheses', () {
      expect(Validators.isPhone('+201001234567'), isTrue);
      expect(Validators.isPhone('(010) 123-4567'), isTrue);
      expect(Validators.isPhone('0100'), isFalse); // < 7 digits
      expect(Validators.isPhone('12345678901234567'), isFalse); // > 15 digits
      expect(Validators.isPhone('abc'), isFalse);
    });

    test('isUrl only accepts http/https with a host', () {
      expect(Validators.isUrl('https://example.com'), isTrue);
      expect(Validators.isUrl('http://example.com/path?q=1'), isTrue);
      expect(Validators.isUrl('ftp://example.com'), isFalse);
      expect(Validators.isUrl('http://'), isFalse); // empty host
      expect(Validators.isUrl('not a url'), isFalse);
    });

    test('isStrongPassword needs length + letter + digit', () {
      expect(Validators.isStrongPassword('abc12345'), isTrue);
      expect(Validators.isStrongPassword('abcdefgh'), isFalse); // no digit
      expect(Validators.isStrongPassword('12345678'), isFalse); // no letter
      expect(Validators.isStrongPassword('a1b2'), isFalse); // too short
      expect(Validators.isStrongPassword('a1b2', minLength: 4), isTrue);
    });
  });

  group('Validators field validators', () {
    test('requiredField', () {
      final v = Validators.requiredField('required');
      expect(v(''), 'required');
      expect(v('  '), 'required');
      expect(v('value'), isNull);
    });

    test('emailField', () {
      final v = Validators.emailField('bad email');
      expect(v(''), 'bad email');
      expect(v('nope'), 'bad email');
      expect(v('user@example.com'), isNull);
    });

    test('phoneField', () {
      final v = Validators.phoneField('bad phone');
      expect(v('123'), 'bad phone');
      expect(v('+201001234567'), isNull);
    });

    test('passwordField', () {
      final v = Validators.passwordField(message: 'weak');
      expect(v('abc'), 'weak');
      expect(v('abc12345'), isNull);
    });

    test('minLengthField uses default message when none given', () {
      final v = Validators.minLengthField(3);
      expect(v('ab'), 'Must be at least 3 characters');
      expect(v('abc'), isNull);
    });
  });
}
