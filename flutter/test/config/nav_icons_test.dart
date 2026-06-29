import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/config/nav_icons.dart';

/// Pure-Dart tests for the closed name→IconData map used by the server-driven
/// bottom nav. We pin a few known mappings and the missing-key fallback.
void main() {
  group('navIconFor', () {
    test('resolves known names to the expected rounded icons', () {
      expect(navIconFor('home'), Icons.home_rounded);
      expect(navIconFor('chat'), Icons.chat_bubble_rounded);
      expect(navIconFor('settings'), Icons.settings_rounded);
      expect(navIconFor('profile'), Icons.account_circle_rounded);
      expect(navIconFor('wallet'), Icons.account_balance_wallet_rounded);
      expect(navIconFor('mic'), Icons.mic_rounded);
    });

    test('falls back to a neutral icon for unknown names', () {
      expect(navIconFor('definitely-not-an-icon'), Icons.circle_outlined);
    });

    test('falls back for null', () {
      expect(navIconFor(null), Icons.circle_outlined);
    });

    test('falls back for empty string', () {
      expect(navIconFor(''), Icons.circle_outlined);
    });

    test('is case-sensitive (only exact lower-case keys match)', () {
      expect(navIconFor('Home'), Icons.circle_outlined);
      expect(navIconFor('HOME'), Icons.circle_outlined);
    });
  });
}
