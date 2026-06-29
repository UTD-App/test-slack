import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/utils/formatters.dart';

/// Pure-Dart unit tests for the shared formatters. `relativeTime` takes an
/// injectable `now`, so every branch is deterministic without touching the clock.
void main() {
  group('Formatters.relativeTime', () {
    final now = DateTime(2026, 6, 29, 12, 0, 0);

    test('under a minute -> just now', () {
      expect(Formatters.relativeTime(now.subtract(const Duration(seconds: 10)), now: now), 'just now');
    });

    test('minutes', () {
      expect(Formatters.relativeTime(now.subtract(const Duration(minutes: 5)), now: now), '5m');
    });

    test('hours', () {
      expect(Formatters.relativeTime(now.subtract(const Duration(hours: 3)), now: now), '3h');
    });

    test('days (under a week)', () {
      expect(Formatters.relativeTime(now.subtract(const Duration(days: 2)), now: now), '2d');
    });

    test('a week or more falls back to absolute date', () {
      final old = now.subtract(const Duration(days: 10));
      expect(Formatters.relativeTime(old, now: now), Formatters.date(old));
    });
  });

  group('Formatters dates', () {
    test('date / time / dateTime use the default patterns', () {
      final d = DateTime(2026, 6, 29, 14, 5);
      expect(Formatters.date(d), '2026-06-29');
      expect(Formatters.time(d), '14:05');
      expect(Formatters.dateTime(d), '2026-06-29 14:05');
    });
  });

  group('Formatters numbers', () {
    test('thousands separator', () {
      expect(Formatters.number(1234567, locale: 'en_US'), '1,234,567');
    });

    test('compact magnitude', () {
      expect(Formatters.compactNumber(1200, locale: 'en_US'), '1.2K');
      expect(Formatters.compactNumber(3400000, locale: 'en_US'), '3.4M');
    });

    test('currency', () {
      expect(Formatters.currency(9.5, locale: 'en_US'), '\$9.50');
    });
  });
}
