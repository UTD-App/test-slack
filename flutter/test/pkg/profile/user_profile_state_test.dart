import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/presentation/bloc/user_profile_bloc.dart';
import 'package:profile/src/domain/user_profile_model.dart';
import 'package:utd_app/shared/core/enums.dart';

void main() {
  group('UserProfileState defaults', () {
    test('initial state', () {
      const s = UserProfileState();
      expect(s.requestState, RequestState.idle);
      expect(s.profile, isNull);
      expect(s.message, isNull);
    });
  });

  group('UserProfileState.copyWith', () {
    test('overrides provided fields, preserves the rest', () {
      const profile = UserProfileModel(id: 1, name: 'A');
      final next = const UserProfileState()
          .copyWith(requestState: RequestState.loaded, profile: profile);
      expect(next.requestState, RequestState.loaded);
      expect(next.profile, profile);
      expect(next.message, isNull);
    });

    test('omitted fields are preserved', () {
      const profile = UserProfileModel(id: 1, name: 'A');
      final base = const UserProfileState()
          .copyWith(requestState: RequestState.loaded, profile: profile);
      final next = base.copyWith(message: 'hi');
      expect(next.requestState, RequestState.loaded); // preserved
      expect(next.profile, profile); // preserved
      expect(next.message, 'hi');
    });
  });

  group('UserProfileState equality', () {
    test('equal when all props equal', () {
      const a = UserProfileState(requestState: RequestState.loading);
      const b = UserProfileState(requestState: RequestState.loading);
      expect(a, equals(b));
    });
    test('different requestState breaks equality', () {
      const a = UserProfileState(requestState: RequestState.loading);
      const b = UserProfileState(requestState: RequestState.error);
      expect(a, isNot(equals(b)));
    });
  });

  group('UserProfileEvent', () {
    test('LoadUserProfileEvent defaults silent to false', () {
      const e = LoadUserProfileEvent(userId: 5);
      expect(e.userId, 5);
      expect(e.silent, isFalse);
    });

    test('LoadUserProfileEvent equality includes userId & silent', () {
      const a = LoadUserProfileEvent(userId: 5, silent: true);
      const b = LoadUserProfileEvent(userId: 5, silent: true);
      const c = LoadUserProfileEvent(userId: 5, silent: false);
      const d = LoadUserProfileEvent(userId: 6, silent: true);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
