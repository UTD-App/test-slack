import 'package:authentication/core/asset_manager.dart';
import 'package:authentication/core/auth_strings.dart';
import 'package:authentication/src/data/datasources/auth_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthStrings.translations', () {
    test('returns an "en" and an "ar" catalog', () {
      final t = AuthStrings.translations('Tempo');
      expect(t.keys, containsAll(['en', 'ar']));
    });

    test('interpolates the app name into the onboarding titles', () {
      final t = AuthStrings.translations('Tempo');
      expect(t['en']![AuthStrings.onBoarding1Title], 'Welcome to Tempo');
      expect(t['ar']![AuthStrings.onBoarding1Title], contains('Tempo'));
    });

    test('every key has both an en and an ar translation', () {
      final t = AuthStrings.translations('App');
      final en = t['en']!;
      final ar = t['ar']!;
      expect(en.length, ar.length);
      for (final k in en.keys) {
        expect(ar.containsKey(k), isTrue, reason: 'missing ar for "$k"');
        expect(en[k]!.trim(), isNotEmpty, reason: 'empty en for "$k"');
        expect(ar[k]!.trim(), isNotEmpty, reason: 'empty ar for "$k"');
      }
    });

    test('keys are namespaced under "auth."', () {
      expect(AuthStrings.login, 'auth.login');
      expect(AuthStrings.email, 'auth.email');
      expect(AuthStrings.passwordTooShort, 'auth.password_too_short');
    });

    test('a known scalar string resolves to expected English copy', () {
      final t = AuthStrings.translations('X');
      expect(t['en']![AuthStrings.login], 'Login');
      expect(t['en']![AuthStrings.passwordsDoNotMatch], 'Passwords do not match');
    });
  });

  group('AssetManager paths', () {
    test('image paths live under the package images dir', () {
      expect(AssetManager.logo,
          'packages/authentication/assets/images/logo.png');
      expect(AssetManager.onboarding1,
          startsWith('packages/authentication/assets/images/'));
    });

    test('icon paths live under the package icons dir', () {
      expect(AssetManager.phone,
          'packages/authentication/assets/icons/phone.png');
      expect(AssetManager.man,
          startsWith('packages/authentication/assets/icons/'));
    });

    test('every asset path is a non-empty .png under the package', () {
      const paths = [
        AssetManager.logo,
        AssetManager.onboarding1,
        AssetManager.onboarding2,
        AssetManager.onboarding3,
        AssetManager.man,
        AssetManager.manInfo,
        AssetManager.women,
        AssetManager.femaleIconInfo,
        AssetManager.userAddInfo,
        AssetManager.phone,
        AssetManager.google_,
        AssetManager.apple,
        AssetManager.huawei,
        AssetManager.mobileValidate,
      ];
      for (final p in paths) {
        expect(p, startsWith('packages/authentication/assets/'));
        expect(p, endsWith('.png'));
      }
    });
  });

  group('AuthApiService paths', () {
    final api = AuthApiService();

    test('exposes the expected auth endpoints', () {
      expect(api.loginPath, '/auth/login');
      expect(api.checkEmailPath, '/check-email');
      expect(api.registerPath, '/auth/register');
      expect(api.forgotPasswordPath, '/auth/forgot-password');
      expect(api.resetPasswordPath, '/auth/reset-password');
      expect(api.addInfoPath, '/profile/update');
    });

    test('exposes the OTP recovery endpoints', () {
      expect(api.sendOtpPath, '/auth/forgot-password/send-otp');
      expect(api.verifyOtpPath, '/auth/forgot-password/verify-code');
      expect(api.resetWithOtpPath, '/auth/forgot-password/reset-otp');
    });
  });
}
