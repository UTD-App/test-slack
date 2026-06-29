import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/features/search/search_user_model.dart';

/// Pure-Dart unit tests for [SearchUser.fromJson].
void main() {
  group('SearchUser.fromJson', () {
    test('happy path: all fields populated', () {
      final json = <String, dynamic>{
        'id': 33,
        'name': 'Omar',
        'uuid': 7788,
        'image': 'https://cdn/omar.png',
        'is_online': true,
      };

      final u = SearchUser.fromJson(json);

      expect(u.id, 33);
      expect(u.name, 'Omar');
      expect(u.uuid, '7788'); // interpolated to string
      expect(u.image, 'https://cdn/omar.png');
      expect(u.isOnline, true);
    });

    test('empty json: safe defaults', () {
      final u = SearchUser.fromJson(<String, dynamic>{});

      expect(u.id, 0);
      expect(u.name, '—'); // blank name fallback
      expect(u.uuid, ''); // '${null ?? ''}'
      expect(u.image, isNull);
      expect(u.isOnline, false);
    });

    test('blank / whitespace name falls back to em-dash', () {
      expect(SearchUser.fromJson({'name': ''}).name, '—');
      expect(SearchUser.fromJson({'name': '   '}).name, '—');
      // non-blank name is kept verbatim (not trimmed).
      expect(SearchUser.fromJson({'name': ' Ali '}).name, ' Ali ');
    });

    test('empty image string -> null (only non-empty kept)', () {
      expect(SearchUser.fromJson({'image': ''}).image, isNull);
      expect(SearchUser.fromJson({'image': 'a.png'}).image, 'a.png');
    });

    test('id accepts num (double) and coerces to int', () {
      expect(SearchUser.fromJson({'id': 5.0}).id, 5);
    });

    test('is_online only true for literal boolean true', () {
      expect(SearchUser.fromJson({'is_online': true}).isOnline, true);
      expect(SearchUser.fromJson({'is_online': 1}).isOnline, false);
      expect(SearchUser.fromJson({'is_online': 'true'}).isOnline, false);
    });

    test('string uuid passes through unchanged', () {
      expect(SearchUser.fromJson({'uuid': 'abc-1'}).uuid, 'abc-1');
    });
  });
}
