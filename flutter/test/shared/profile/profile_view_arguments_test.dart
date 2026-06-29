import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

/// Pure-Dart unit tests for [ProfileViewArguments] and its `section` accessor.
void main() {
  group('ProfileViewArguments defaults', () {
    test('const default constructor: empty sections, zero user, not me', () {
      const args = ProfileViewArguments();

      expect(args.sections, isEmpty);
      expect(args.userId, 0);
      expect(args.isMe, false);
    });

    test('explicit construction stores fields', () {
      const args = ProfileViewArguments(
        sections: {
          'gifts': {'count': 12}
        },
        userId: 7,
        isMe: true,
      );

      expect(args.userId, 7);
      expect(args.isMe, true);
      expect(args.sections['gifts'], {'count': 12});
    });
  });

  group('section(key)', () {
    test('returns the slice when present as a map', () {
      const args = ProfileViewArguments(sections: {
        'gifts': {'count': 12, 'items': []},
      });

      final gifts = args.section('gifts');
      expect(gifts['count'], 12);
      expect(gifts['items'], isEmpty);
      expect(gifts, isA<Map<String, dynamic>>());
    });

    test('returns empty map for an absent key', () {
      const args = ProfileViewArguments(sections: {});
      expect(args.section('missing'), isEmpty);
    });

    test('returns empty map when value is not a map', () {
      const args = ProfileViewArguments(sections: {
        'broken': 'not-a-map',
        'alsoBroken': 5,
      });
      expect(args.section('broken'), isEmpty);
      expect(args.section('alsoBroken'), isEmpty);
    });

    test('casts a dynamic-keyed nested map to Map<String,dynamic>', () {
      // section() does value.cast<String, dynamic>(); ensure a dynamic map works.
      final dynamicMap = <dynamic, dynamic>{'count': 3};
      final args = ProfileViewArguments(sections: {'gifts': dynamicMap});

      final gifts = args.section('gifts');
      expect(gifts, isA<Map<String, dynamic>>());
      expect(gifts['count'], 3);
    });
  });
}
