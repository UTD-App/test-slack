import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/core/enums.dart';
import 'package:utd_app/shared/core/extensions.dart';

/// Pure-Dart tests for extensions.dart.
///
/// SCOPE: Only the framework-free parts are exercised here —
///   - `parseValue<T>(...)` generic coercion helper (all branches)
///   - RequestStateExt boolean getters
///   - TextStyleModifiers weight getters + colorExt (copyWith-only, no ScreenUtil)
///
/// SKIPPED (need ScreenUtil init and/or a real BuildContext, not pure-Dart):
///   DimensionsExt (.h/.w/.r), PaddingExt, TextStyleExtensions, TextStyleModifiers.size,
///   TextEditingControllerCopyWith is pure but trivial — included below.
void main() {
  group('RequestStateExt', () {
    test('each getter is true only for its matching state', () {
      expect(RequestState.idle.isIdle, isTrue);
      expect(RequestState.loading.isLoading, isTrue);
      expect(RequestState.loaded.isLoaded, isTrue);
      expect(RequestState.error.isError, isTrue);
      expect(RequestState.empty.isEmpty, isTrue);
      expect(RequestState.offline.isOffline, isTrue);
      expect(RequestState.banUser.userBan, isTrue);
    });

    test('getters are false for a non-matching state', () {
      expect(RequestState.idle.isLoading, isFalse);
      expect(RequestState.idle.isError, isFalse);
      expect(RequestState.loaded.isEmpty, isFalse);
      expect(RequestState.error.userBan, isFalse);
      expect(RequestState.loading.isOffline, isFalse);
    });

    test('exactly one getter true per state', () {
      for (final s in RequestState.values) {
        final flags = <bool>[
          s.isIdle,
          s.isLoading,
          s.isLoaded,
          s.isError,
          s.isEmpty,
          s.isOffline,
          s.userBan,
        ];
        expect(flags.where((f) => f).length, 1,
            reason: 'state $s should match exactly one getter');
      }
    });
  });

  group('parseValue — null & fallback', () {
    test('null value returns fallback', () {
      expect(parseValue<int>(null, 7), 7);
      expect(parseValue<String>(null, 'fb'), 'fb');
    });

    test('value already of type T is returned as-is', () {
      expect(parseValue<int>(42, 0), 42);
      expect(parseValue<String>('hi', 'fb'), 'hi');
      expect(parseValue<bool>(true, false), true);
    });
  });

  group('parseValue — int', () {
    test('numeric string parses', () {
      expect(parseValue<int>('123', 0), 123);
    });
    test('non-numeric string -> fallback', () {
      expect(parseValue<int>('abc', -1), -1);
    });
    test('double value coerces via toString().tryParse -> fallback (no decimals)', () {
      // 3.5.toString() == '3.5', int.tryParse('3.5') == null -> fallback
      expect(parseValue<int>(3.5, 99), 99);
    });
    test('double whole number string-parses to fallback (int.tryParse("3.0")==null)', () {
      expect(parseValue<int>(3.0, 99), 99);
    });
  });

  group('parseValue — double', () {
    test('numeric string parses', () {
      expect(parseValue<double>('1.5', 0.0), 1.5);
    });
    test('integer-ish string parses to double', () {
      expect(parseValue<double>('4', 0.0), 4.0);
    });
    test('non-numeric -> fallback', () {
      expect(parseValue<double>('x', -2.0), -2.0);
    });
  });

  group('parseValue — bool', () {
    test('"true"/"false" strings', () {
      expect(parseValue<bool>('true', false), true);
      expect(parseValue<bool>('false', true), false);
    });
    test('case-insensitive', () {
      expect(parseValue<bool>('TRUE', false), true);
      expect(parseValue<bool>('False', true), false);
    });
    test('numeric/other strings -> fallback', () {
      expect(parseValue<bool>('1', false), false);
      expect(parseValue<bool>('yes', true), true);
    });
    test('int 1 is not bool -> coerces via toString -> fallback', () {
      // value is int (not T==bool); '1'.toLowerCase() != 'true'/'false'
      expect(parseValue<bool>(1, false), false);
    });
  });

  group('parseValue — String', () {
    test('int -> its string', () {
      expect(parseValue<String>(5, 'fb'), '5');
    });
    test('double -> its string', () {
      expect(parseValue<String>(2.5, 'fb'), '2.5');
    });
    test('empty list -> fallback', () {
      expect(parseValue<String>(<dynamic>[], 'fb'), 'fb');
    });
    test('empty map -> fallback', () {
      expect(parseValue<String>(<String, dynamic>{}, 'fb'), 'fb');
    });
    test('non-empty list -> toString', () {
      expect(parseValue<String>([1, 2], 'fb'), '[1, 2]');
    });
  });

  group('parseValue — List<String>', () {
    test('from a real List value passes through type check first', () {
      // value is List<String> -> matches `value is T`? List<String> is List<String>
      expect(parseValue<List<String>>(<String>['a', 'b'], const []),
          <String>['a', 'b']);
    });
    test('from a JSON string', () {
      expect(parseValue<List<String>>('["a","b","c"]', const []),
          <String>['a', 'b', 'c']);
    });
    test('JSON of numbers stringified', () {
      expect(parseValue<List<String>>('[1,2,3]', const []),
          <String>['1', '2', '3']);
    });
    test('invalid JSON -> fallback', () {
      expect(parseValue<List<String>>('not json', const ['fb']),
          <String>['fb']);
    });
  });

  group('parseValue — List<int>', () {
    test('from JSON string of ints', () {
      expect(parseValue<List<int>>('[1,2,3]', const []), <int>[1, 2, 3]);
    });
    test('non-numeric elements default to 0', () {
      expect(parseValue<List<int>>('["x",2]', const []), <int>[0, 2]);
    });
  });

  group('parseValue — List<double>', () {
    test('from JSON string', () {
      expect(parseValue<List<double>>('[1.5, 2]', const []),
          <double>[1.5, 2.0]);
    });
    test('bad elements default to 0.0', () {
      expect(parseValue<List<double>>('["q", 3.0]', const []),
          <double>[0.0, 3.0]);
    });
  });

  group('parseValue — List<bool>', () {
    test('from JSON string', () {
      expect(parseValue<List<bool>>('[true, false, true]', const []),
          <bool>[true, false, true]);
    });
    test('non-"true" elements become false', () {
      expect(parseValue<List<bool>>('["yes", "true"]', const []),
          <bool>[false, true]);
    });
  });

  group('parseValue — Map<String, dynamic>', () {
    test('from a JSON string', () {
      expect(parseValue<Map<String, dynamic>>('{"a":1,"b":"x"}', const {}),
          {'a': 1, 'b': 'x'});
    });
    test('already a Map<String,dynamic> passes type check', () {
      final m = <String, dynamic>{'k': 1};
      expect(parseValue<Map<String, dynamic>>(m, const {}), m);
    });
  });

  group('parseValue — List<Map<String, dynamic>>', () {
    test('JSON array of objects', () {
      final out = parseValue<List<Map<String, dynamic>>>(
        '[{"a":1},{"b":2}]',
        const [],
      );
      expect(out, [
        {'a': 1},
        {'b': 2},
      ]);
    });
    test('JSON single object wrapped into a single-element list', () {
      final out = parseValue<List<Map<String, dynamic>>>(
        '{"a":1}',
        const [],
      );
      expect(out, [
        {'a': 1},
      ]);
    });
  });

  group('parseValue — customParser', () {
    test('customParser is applied to a single value', () {
      final out = parseValue<int>('10', 0, customParser: (v) => int.parse(v) * 2);
      expect(out, 20);
    });
    test('customParser is consulted before the primitive branches', () {
      // When a customParser is supplied and the value is not already T, the
      // resolver runs the parser first and returns its result directly.
      final out = parseValue<List<int>>(
        '[1,2,3]',
        const [],
        customParser: (v) => <int>[9, 9],
      );
      expect(out, <int>[9, 9]);
    });
  });

  group('TextStyleModifiers (copyWith-only, no ScreenUtil)', () {
    test('colorExt sets the color', () {
      const base = TextStyle();
      expect(base.colorExt(const Color(0xFF112233)).color,
          const Color(0xFF112233));
    });
    test('weight getters set font weight', () {
      const base = TextStyle();
      expect(base.w400.fontWeight, FontWeight.w400);
      expect(base.w500.fontWeight, FontWeight.w500);
      expect(base.w600.fontWeight, FontWeight.w600);
      expect(base.w700.fontWeight, FontWeight.w700);
      expect(base.bold.fontWeight, FontWeight.bold);
    });
    test('modifiers preserve other fields', () {
      const base = TextStyle(fontSize: 14, color: Color(0xFFAABBCC));
      final out = base.w600;
      expect(out.fontSize, 14);
      expect(out.color, const Color(0xFFAABBCC));
      expect(out.fontWeight, FontWeight.w600);
    });
  });

  group('TextEditingControllerCopyWith', () {
    test('copyWith(text:) creates a controller with given text', () {
      final c = TextEditingController(text: 'old');
      final copy = c.copyWith(text: 'new');
      expect(copy.text, 'new');
      c.dispose();
      copy.dispose();
    });
    test('copyWith() with no arg keeps existing text', () {
      final c = TextEditingController(text: 'keep');
      final copy = c.copyWith();
      expect(copy.text, 'keep');
      c.dispose();
      copy.dispose();
    });
  });
}
