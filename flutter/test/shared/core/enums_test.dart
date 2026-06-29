import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';

/// Pure-Dart tests for the app's enums. Enums have no logic of their own, so we
/// pin their member set, ordering (index) and name strings — these are relied on
/// by serialization, switch-exhaustiveness and `.values` iteration elsewhere.
void main() {
  group('RequestState', () {
    test('has the expected members in order', () {
      expect(RequestState.values, <RequestState>[
        RequestState.idle,
        RequestState.loading,
        RequestState.loaded,
        RequestState.error,
        RequestState.offline,
        RequestState.empty,
        RequestState.banUser,
      ]);
    });

    test('has exactly 7 members', () {
      expect(RequestState.values.length, 7);
    });

    test('indices are stable', () {
      expect(RequestState.idle.index, 0);
      expect(RequestState.loading.index, 1);
      expect(RequestState.loaded.index, 2);
      expect(RequestState.error.index, 3);
      expect(RequestState.offline.index, 4);
      expect(RequestState.empty.index, 5);
      expect(RequestState.banUser.index, 6);
    });

    test('member names', () {
      expect(RequestState.idle.name, 'idle');
      expect(RequestState.banUser.name, 'banUser');
    });
  });

  group('LanguageType', () {
    test('has the expected members in order', () {
      expect(LanguageType.values, <LanguageType>[
        LanguageType.ar,
        LanguageType.en,
        LanguageType.tr,
        LanguageType.ur,
        LanguageType.hi,
        LanguageType.id,
      ]);
    });

    test('has exactly 6 members', () {
      expect(LanguageType.values.length, 6);
    });

    test('names match ISO-ish codes', () {
      expect(LanguageType.values.map((e) => e.name).toList(),
          <String>['ar', 'en', 'tr', 'ur', 'hi', 'id']);
    });

    test('lookup by name via .byName', () {
      expect(LanguageType.values.byName('en'), LanguageType.en);
      expect(LanguageType.values.byName('ar'), LanguageType.ar);
    });
  });

  group('OtpType', () {
    test('has the expected members in order', () {
      expect(OtpType.values, <OtpType>[
        OtpType.register,
        OtpType.resetPassword,
        OtpType.passwordChange,
        OtpType.verifyOldPhone,
        OtpType.verifyNewPhone,
        OtpType.bindAccount,
      ]);
    });

    test('has exactly 6 members', () {
      expect(OtpType.values.length, 6);
    });

    test('member names', () {
      expect(OtpType.register.name, 'register');
      expect(OtpType.resetPassword.name, 'resetPassword');
      expect(OtpType.bindAccount.name, 'bindAccount');
    });
  });
}
