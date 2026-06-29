import 'package:authentication/src/data/models/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the hardened LoginModel.fromJson — an edge/malformed
/// login response must coerce to safe defaults instead of throwing.
void main() {
  group('LoginModel.fromJson hardening', () {
    test('happy path', () {
      final m = LoginModel.fromJson({'id': 7, 'is_first': true, 'auth_token': 'tok'});
      expect(m.id, 7);
      expect(m.isFirst, isTrue);
      expect(m.authToken, 'tok');
      expect(m.user, isNull);
    });

    test('missing id/is_first/auth_token default safely (no crash)', () {
      final m = LoginModel.fromJson(<String, dynamic>{});
      expect(m.id, 0);
      expect(m.isFirst, isFalse);
      expect(m.authToken, '');
    });

    test('is_first accepts 0/1 ints and string variants', () {
      expect(LoginModel.fromJson({'is_first': 1}).isFirst, isTrue);
      expect(LoginModel.fromJson({'is_first': 0}).isFirst, isFalse);
      expect(LoginModel.fromJson({'is_first': '1'}).isFirst, isTrue);
      expect(LoginModel.fromJson({'is_first': 'true'}).isFirst, isTrue);
    });

    test('id accepts numeric string/double via num coercion', () {
      expect(LoginModel.fromJson({'id': 12.0}).id, 12);
    });

    test('auth_token stringifies a non-string value', () {
      expect(LoginModel.fromJson({'auth_token': 999}).authToken, '999');
    });

    test('non-map user falls back to null instead of throwing', () {
      expect(LoginModel.fromJson({'id': 1, 'user': 'oops'}).user, isNull);
    });
  });
}
