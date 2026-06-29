import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

void main() {
  group('StacCoerce.sanitize', () {
    test('coerces a string-expected int field to a String', () {
      final node = {'type': 'text', 'data': 42};
      StacCoerce.sanitize(node);
      expect(node['data'], '42');
    });

    test('coerces bool and double string-keys to String', () {
      final node = {'data': true, 'labelText': 3.5};
      StacCoerce.sanitize(node);
      expect(node['data'], 'true');
      expect(node['labelText'], '3.5');
    });

    test('null string-key becomes empty string (image src crash guard)', () {
      final node = {'type': 'image', 'src': null};
      StacCoerce.sanitize(node);
      expect(node['src'], '');
    });

    test('leaves already-String values untouched', () {
      final node = {'data': 'hello'};
      StacCoerce.sanitize(node);
      expect(node['data'], 'hello');
    });

    test('does not touch non-string keys even when they are numbers', () {
      final node = {'width': 100, 'height': 40};
      StacCoerce.sanitize(node);
      expect(node['width'], 100);
      expect(node['height'], 40);
    });

    test('recurses into nested maps and lists', () {
      final node = {
        'type': 'column',
        'children': [
          {'type': 'text', 'data': 1},
          {
            'type': 'container',
            'child': {'type': 'text', 'data': 2},
          },
        ],
      };
      StacCoerce.sanitize(node);
      final children = node['children'] as List;
      expect((children[0] as Map)['data'], '1');
      expect(((children[1] as Map)['child'] as Map)['data'], '2');
    });

    test('returns the same instance (mutates in place, idempotent)', () {
      final node = <String, dynamic>{'data': 5};
      final out = StacCoerce.sanitize(node);
      expect(identical(out, node), isTrue);
      // Second call is a no-op (already a String).
      StacCoerce.sanitize(out);
      expect(node['data'], '5');
    });

    test('handles a top-level list', () {
      final list = <Map<String, dynamic>>[
        {'data': 7},
        {'src': 9},
      ];
      StacCoerce.sanitize(list);
      expect((list[0])['data'], '7');
      expect((list[1])['src'], '9');
    });

    test('coerces all known string keys', () {
      final node = <String, dynamic>{
        'data': 1,
        'src': 2,
        'hintText': 3,
        'labelText': 4,
        'routeName': 5,
        'route': 6,
        'fontFamily': 7,
        'semanticLabel': 8,
      };
      StacCoerce.sanitize(node);
      for (final v in node.values) {
        expect(v, isA<String>());
      }
    });
  });
}
