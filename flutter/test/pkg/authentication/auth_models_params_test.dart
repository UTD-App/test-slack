import 'dart:io';

import 'package:authentication/src/data/models/login_model.dart';
import 'package:authentication/src/domain/entities/login_entity.dart';
import 'package:authentication/src/domain/params/auth_parameter.dart';
import 'package:authentication/src/domain/params/forget_password_parameter.dart';
import 'package:authentication/src/domain/params/information_parameter.dart';
import 'package:authentication/src/domain/params/recover_otp_parameter.dart';
import 'package:authentication/src/domain/params/register_parameter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginModel.fromJson', () {
    test('parses a payload without a nested user', () {
      final m = LoginModel.fromJson(const {
        'id': 42,
        'is_first': true,
        'auth_token': 'tok-123',
      });

      expect(m.id, 42);
      expect(m.isFirst, true);
      expect(m.authToken, 'tok-123');
      expect(m.user, isNull);
    });

    test('parses a payload with a nested user', () {
      final m = LoginModel.fromJson(const {
        'id': 7,
        'is_first': false,
        'auth_token': 'abc',
        'user': {
          'id': 7,
          'name': 'Ahmed',
          'email': 'a@b.com',
        },
      });

      expect(m.id, 7);
      expect(m.isFirst, false);
      expect(m.user, isNotNull);
      expect(m.user!.id, 7);
      expect(m.user!.name, 'Ahmed');
      expect(m.user!.email, 'a@b.com');
    });

    test('null user key yields a null user (not a crash)', () {
      final m = LoginModel.fromJson(const {
        'id': 1,
        'is_first': true,
        'auth_token': 't',
        'user': null,
      });
      expect(m.user, isNull);
    });

    test('is a LoginEntity (subtype) and uses Equatable identity', () {
      final a = LoginModel.fromJson(const {
        'id': 1,
        'is_first': true,
        'auth_token': 't',
      });
      final b = LoginModel.fromJson(const {
        'id': 1,
        'is_first': true,
        'auth_token': 't',
      });
      expect(a, isA<LoginEntity>());
      // Same scalar fields + null user → equal by Equatable props.
      expect(a, equals(b));
    });

    test('different scalar fields break equality', () {
      final a = LoginModel.fromJson(const {
        'id': 1,
        'is_first': true,
        'auth_token': 't',
      });
      final c = LoginModel.fromJson(const {
        'id': 2,
        'is_first': true,
        'auth_token': 't',
      });
      expect(a, isNot(equals(c)));
    });
  });

  group('LoginEntity equality', () {
    test('equal props compare equal', () {
      const a = LoginEntity(id: 5, isFirst: false, authToken: 'x');
      const b = LoginEntity(id: 5, isFirst: false, authToken: 'x');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('props list exposes all fields', () {
      const a = LoginEntity(id: 5, isFirst: false, authToken: 'x');
      expect(a.props, [5, false, 'x', null]);
    });
  });

  group('AuthParameter / RegisterParameter', () {
    test('AuthParameter is value-equal by email+password', () {
      const a = AuthParameter(email: 'a@b.com', password: 'pw');
      const b = AuthParameter(email: 'a@b.com', password: 'pw');
      const c = AuthParameter(email: 'a@b.com', password: 'other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, ['a@b.com', 'pw']);
    });

    test('RegisterParameter is value-equal by email+password', () {
      const a = RegisterParameter(email: 'a@b.com', password: 'pw');
      const b = RegisterParameter(email: 'a@b.com', password: 'pw');
      expect(a, equals(b));
      expect(a.props, ['a@b.com', 'pw']);
    });

    test('AuthParameter and RegisterParameter are distinct types', () {
      const a = AuthParameter(email: 'a@b.com', password: 'pw');
      const r = RegisterParameter(email: 'a@b.com', password: 'pw');
      // Equatable equality also requires the same runtimeType.
      expect(a, isNot(equals(r)));
    });
  });

  group('ForgetPasswordParameter', () {
    test('value-equal by email+password+token', () {
      const a = ForgetPasswordParameter(
          email: 'a@b.com', password: 'pw', token: 'tk');
      const b = ForgetPasswordParameter(
          email: 'a@b.com', password: 'pw', token: 'tk');
      const c = ForgetPasswordParameter(
          email: 'a@b.com', password: 'pw', token: 'other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, ['a@b.com', 'pw', 'tk']);
    });
  });

  group('Recover OTP params', () {
    test('VerifyOtpParameter value equality by email+code', () {
      const a = VerifyOtpParameter(email: 'a@b.com', code: '1234');
      const b = VerifyOtpParameter(email: 'a@b.com', code: '1234');
      const c = VerifyOtpParameter(email: 'a@b.com', code: '0000');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, ['a@b.com', '1234']);
    });

    test('ResetWithOtpParameter value equality by email+code+password', () {
      const a =
          ResetWithOtpParameter(email: 'a@b.com', code: '1', password: 'pw');
      const b =
          ResetWithOtpParameter(email: 'a@b.com', code: '1', password: 'pw');
      const c =
          ResetWithOtpParameter(email: 'a@b.com', code: '1', password: 'x');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.props, ['a@b.com', '1', 'pw']);
    });
  });

  group('InformationParameter', () {
    test('defaults are all null', () {
      const p = InformationParameter();
      expect(p.name, isNull);
      expect(p.bio, isNull);
      expect(p.date, isNull);
      expect(p.gender, isNull);
      expect(p.image, isNull);
      expect(p.multiImages, isNull);
      expect(p.oldMultiImages, isNull);
      expect(p.uuid, isNull);
      expect(p.isUpdateOnlyUid, isNull);
    });

    test('holds provided values and is value-equal', () {
      final img = File('avatar.png');
      final p1 = InformationParameter(
        name: 'Ahmed',
        bio: 'hi',
        date: '2000-01-01',
        gender: 1,
        image: img,
        oldMultiImages: const ['a.png'],
        uuid: 'u-1',
        isUpdateOnlyUid: false,
      );
      final p2 = InformationParameter(
        name: 'Ahmed',
        bio: 'hi',
        date: '2000-01-01',
        gender: 1,
        image: img,
        oldMultiImages: const ['a.png'],
        uuid: 'u-1',
        isUpdateOnlyUid: false,
      );
      expect(p1, equals(p2));
      expect(p1.gender, 1);
      expect(p1.uuid, 'u-1');
    });

    test('differing gender breaks equality', () {
      const a = InformationParameter(name: 'X', gender: 0);
      const b = InformationParameter(name: 'X', gender: 1);
      expect(a, isNot(equals(b)));
    });

    test('props exposes all nine fields', () {
      const p = InformationParameter(name: 'n');
      expect(p.props.length, 9);
    });
  });
}
