import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/config/app_flow.dart';

/// Pure-Dart tests for the data-driven navigation contract: [ScreenRoles]
/// vocabulary, [ScreenContract] defaults, [AppFlow] slot defaulting,
/// [AppFlow.contractFor], the boot decision [AppFlow.resolveStart], and the
/// static [AppFlow.instance]/[override] lifecycle.
void main() {
  group('ScreenRoles', () {
    test('exposes the curated role vocabulary', () {
      expect(ScreenRoles.login, 'auth.login');
      expect(ScreenRoles.register, 'auth.register');
      expect(ScreenRoles.forgot, 'auth.forgot');
      expect(ScreenRoles.profile, 'auth.profile');
      expect(ScreenRoles.intro, 'onboarding.intro');
      expect(ScreenRoles.home, 'app.home');
      expect(ScreenRoles.settings, 'app.settings');
      expect(ScreenRoles.splash, 'app.splash');
    });
  });

  group('ScreenContract', () {
    test('defaults are inert', () {
      const c = ScreenContract();
      expect(c.role, isNull);
      expect(c.requiresAuth, isFalse);
      expect(c.showOnce, isFalse);
    });

    test('retains supplied values', () {
      const c = ScreenContract(
        role: ScreenRoles.home,
        requiresAuth: true,
        showOnce: true,
      );
      expect(c.role, ScreenRoles.home);
      expect(c.requiresAuth, isTrue);
      expect(c.showOnce, isTrue);
    });
  });

  group('AppFlow constructor defaulting', () {
    test('onAuthSuccess defaults to home, onLogout to unauthenticated', () {
      const flow = AppFlow(
        splash: '/s',
        firstRun: '/f',
        unauthenticated: '/u',
        home: '/h',
      );
      expect(flow.onAuthSuccess, '/h');
      expect(flow.onLogout, '/u');
    });

    test('explicit onAuthSuccess/onLogout win over the defaults', () {
      const flow = AppFlow(
        splash: '/s',
        firstRun: '/f',
        unauthenticated: '/u',
        home: '/h',
        onAuthSuccess: '/welcome',
        onLogout: '/bye',
      );
      expect(flow.onAuthSuccess, '/welcome');
      expect(flow.onLogout, '/bye');
    });
  });

  group('contractFor', () {
    const flow = AppFlow(
      splash: '/s',
      firstRun: '/f',
      unauthenticated: '/u',
      home: '/h',
      contracts: {
        '/h': ScreenContract(role: ScreenRoles.home, requiresAuth: true),
      },
    );

    test('returns the declared contract for a known route', () {
      final c = flow.contractFor('/h');
      expect(c.role, ScreenRoles.home);
      expect(c.requiresAuth, isTrue);
    });

    test('returns an inert default contract for an unknown route', () {
      final c = flow.contractFor('/unknown');
      expect(c.role, isNull);
      expect(c.requiresAuth, isFalse);
      expect(c.showOnce, isFalse);
    });
  });

  group('resolveStart', () {
    const flow = AppFlow(
      splash: '/splash',
      firstRun: '/intro',
      unauthenticated: '/login',
      home: '/',
    );

    test('a session goes straight home (even if firstRun unseen)', () {
      final start = flow.resolveStart(
        hasSession: true,
        seen: (_) => false,
      );
      expect(start, '/');
    });

    test('no session + firstRun never seen → firstRun', () {
      final start = flow.resolveStart(
        hasSession: false,
        seen: (route) => false,
      );
      expect(start, '/intro');
    });

    test('no session + firstRun already seen → unauthenticated', () {
      final start = flow.resolveStart(
        hasSession: false,
        seen: (route) => route == '/intro',
      );
      expect(start, '/login');
    });
  });

  group('AppFlow.fallback', () {
    test('mirrors the base core screens', () {
      const fb = AppFlow.fallback;
      expect(fb.splash, '/splash');
      expect(fb.firstRun, '/intro');
      expect(fb.unauthenticated, '/login');
      expect(fb.home, '/');
      // defaulted derived slots
      expect(fb.onAuthSuccess, '/');
      expect(fb.onLogout, '/login');
    });

    test('declares the expected route contracts', () {
      const fb = AppFlow.fallback;
      expect(fb.contractFor('/intro').role, ScreenRoles.intro);
      expect(fb.contractFor('/intro').showOnce, isTrue);
      expect(fb.contractFor('/login').role, ScreenRoles.login);
      expect(fb.contractFor('/register').role, ScreenRoles.register);
      expect(fb.contractFor('/recover-password').role, ScreenRoles.forgot);
      expect(fb.contractFor('/').role, ScreenRoles.home);
      expect(fb.contractFor('/').requiresAuth, isTrue);
      expect(fb.contractFor('/profile').role, ScreenRoles.profile);
      expect(fb.contractFor('/profile').requiresAuth, isTrue);
    });
  });

  group('AppFlow.instance / override', () {
    // The active flow is static global state. Restore the fallback after each
    // test so order never matters.
    tearDown(() => AppFlow.override(AppFlow.fallback));

    test('defaults to the fallback flow', () {
      // Establish a known baseline first (in case a prior test overrode it).
      AppFlow.override(AppFlow.fallback);
      expect(AppFlow.instance.home, AppFlow.fallback.home);
      expect(AppFlow.instance.unauthenticated, '/login');
    });

    test('override swaps the active flow', () {
      const custom = AppFlow(
        splash: '/x-splash',
        firstRun: '/x-intro',
        unauthenticated: '/s/core_login',
        home: '/s/core_home',
      );
      AppFlow.override(custom);
      expect(AppFlow.instance.home, '/s/core_home');
      expect(AppFlow.instance.unauthenticated, '/s/core_login');
      expect(AppFlow.instance.onAuthSuccess, '/s/core_home');
    });
  });
}
