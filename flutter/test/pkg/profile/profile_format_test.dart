import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/domain/profile_format.dart';

void main() {
  group('formatCount', () {
    test('values under 1000 are shown as-is', () {
      expect(formatCount(0), '0');
      expect(formatCount(1), '1');
      expect(formatCount(999), '999');
    });

    test('drops trailing decimal on round thousands', () {
      expect(formatCount(1000), '1K');
      expect(formatCount(2000), '2K');
      expect(formatCount(10000), '10K');
    });

    test('keeps one decimal for non-round thousands', () {
      expect(formatCount(1500), '1.5K');
      expect(formatCount(10500), '10.5K');
    });

    test('millions', () {
      expect(formatCount(1000000), '1M');
      expect(formatCount(2000000), '2M');
      expect(formatCount(2500000), '2.5M');
    });

    test('boundary at 1000 and 1000000', () {
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1K');
      expect(formatCount(999999), endsWith('K'));
      expect(formatCount(1000000), '1M');
    });

    test('truncates the fractional part of the value via toInt under 1000', () {
      // 999.9 < 1000 -> toInt().toString() == '999'
      expect(formatCount(999.9), '999');
    });
  });
}
