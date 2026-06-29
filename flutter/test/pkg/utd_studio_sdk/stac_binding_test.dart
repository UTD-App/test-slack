import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

void main() {
  group('StacBinding.resolve — text', () {
    test('binds a plain value into text.data', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'name'},
        {'name': 'Ahmed'},
      );
      expect(out['data'], 'Ahmed');
    });

    test('fully-qualified binding falls back to the last dot segment', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'chat.conversations.name'},
        {'name': 'Sara'},
      );
      expect(out['data'], 'Sara');
    });

    test('exact-key match wins over the last-segment fallback', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'chat.name'},
        {'chat.name': 'Exact', 'name': 'Fallback'},
      );
      expect(out['data'], 'Exact');
    });

    test('missing value keeps the existing literal data', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'name', 'data': 'default'},
        {'other': 'x'},
      );
      expect(out['data'], 'default');
    });

    test('does not mutate the original template', () {
      final template = {'type': 'text', 'binding': 'name'};
      StacBinding.resolve(template, {'name': 'Z'});
      expect(template.containsKey('data'), isFalse);
    });
  });

  group('StacBinding.resolve — datetime display', () {
    test('today ISO timestamp renders as HH:mm', () {
      final now = DateTime.now();
      final iso = DateTime(now.year, now.month, now.day, 14, 7).toIso8601String();
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'time'},
        {'time': iso},
      );
      expect(out['data'], '14:07');
    });

    test('a non-today ISO timestamp renders as yyyy/MM/dd', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'time'},
        {'time': '2020-03-05T11:34:07'},
      );
      expect(out['data'], '2020/03/05');
    });

    test('a plain string with no T is shown as-is', () {
      final out = StacBinding.resolve(
        {'type': 'text', 'binding': 'msg'},
        {'msg': 'hello world'},
      );
      expect(out['data'], 'hello world');
    });
  });

  group('StacBinding.resolve — image', () {
    test('binds a URL and sets imageType network', () {
      final out = StacBinding.resolve(
        {'type': 'image', 'binding': 'image'},
        {'image': 'https://x/y.png'},
      );
      expect(out['src'], 'https://x/y.png');
      expect(out['imageType'], 'network');
    });

    test('empty NON-avatar image binding renders an empty (vanishing) src', () {
      final out = StacBinding.resolve(
        {'type': 'image', 'binding': 'flag'},
        {'flag': ''},
      );
      expect(out['src'], '');
      expect(out['imageType'], 'network');
      // Stays an image, not converted to a placeholder container.
      expect(out['type'], 'image');
    });

    test('empty AVATAR binding becomes a circular person placeholder', () {
      final out = StacBinding.resolve(
        {'type': 'image', 'binding': 'avatar', 'width': 96, 'height': 96},
        {'avatar': ''},
      );
      expect(out['type'], 'container');
      expect(out['alignment'], 'center');
      final child = out['child'] as Map;
      expect(child['type'], 'icon');
      expect(child['icon'], 'person');
      // icon size = dim * 0.6
      expect(child['size'], 96 * 0.6);
      expect(out['width'], 96);
      expect(out['height'], 96);
    });

    test('avatar placeholder defaults icon size from 96 when no dims', () {
      final out = StacBinding.resolve(
        {'type': 'image', 'binding': 'user.avatar'},
        {'avatar': null},
      );
      expect(out['type'], 'container');
      expect((out['child'] as Map)['size'], 96 * 0.6);
    });
  });

  group('StacBinding.resolve — fields and icons', () {
    test('textFormField gets initialValue', () {
      final out = StacBinding.resolve(
        {'type': 'textFormField', 'binding': 'name'},
        {'name': 'Pre'},
      );
      expect(out['initialValue'], 'Pre');
    });

    test('utdTextField gets initialValue', () {
      final out = StacBinding.resolve(
        {'type': 'utdTextField', 'binding': 'name'},
        {'name': 'Pre'},
      );
      expect(out['initialValue'], 'Pre');
    });

    test('icon binding sets the icon name', () {
      final out = StacBinding.resolve(
        {'type': 'icon', 'binding': 'icon'},
        {'icon': 'home'},
      );
      expect(out['icon'], 'home');
    });

    test('unknown type exposes the value under data (generic fallback)', () {
      final out = StacBinding.resolve(
        {'type': 'customWidget', 'binding': 'count'},
        {'count': 9},
      );
      expect(out['data'], 9);
    });
  });

  group('StacBinding.resolve — conditional visibility', () {
    test('drops a child whose visibleBinding is falsy (0)', () {
      final out = StacBinding.resolve(
        {
          'type': 'row',
          'children': [
            {'type': 'badge', 'visibleBinding': 'unread'},
            {'type': 'text', 'data': 'keep'},
          ],
        },
        {'unread': 0},
      );
      final children = out['children'] as List;
      expect(children.length, 1);
      expect((children.single as Map)['type'], 'text');
    });

    test('keeps a child whose visibleBinding is truthy', () {
      final out = StacBinding.resolve(
        {
          'type': 'row',
          'children': [
            {'type': 'dot', 'visibleBinding': 'online'},
          ],
        },
        {'online': true},
      );
      expect((out['children'] as List).length, 1);
    });

    test('"false"/"0"/"null"/empty strings count as falsy', () {
      for (final v in ['false', '0', 'null', '', '  ']) {
        final out = StacBinding.resolve(
          {
            'type': 'row',
            'children': [
              {'type': 'dot', 'visibleBinding': 'flag'},
            ],
          },
          {'flag': v},
        );
        expect((out['children'] as List), isEmpty, reason: 'value "$v"');
      }
    });

    test('a single child slot is removed when its visibleBinding is falsy', () {
      final out = StacBinding.resolve(
        {
          'type': 'container',
          'child': {'type': 'dot', 'visibleBinding': 'online'},
        },
        {'online': false},
      );
      expect(out.containsKey('child'), isFalse);
    });
  });

  group('StacBinding.injectItemContext', () {
    test('stamps item onto every actionType node missing one', () {
      final node = <String, dynamic>{
        'type': 'row',
        'onTap': <String, dynamic>{'actionType': 'like'},
        'children': <Map<String, dynamic>>[
          {
            'type': 'button',
            'onTap': <String, dynamic>{'actionType': 'comment'},
          },
        ],
      };
      StacBinding.injectItemContext(node, {'id': 7});
      expect((node['onTap'] as Map)['item'], {'id': 7});
      final inner = ((node['children'] as List).first as Map)['onTap'] as Map;
      expect(inner['item'], {'id': 7});
    });

    test('does not overwrite an explicit item override', () {
      final node = <String, dynamic>{
        'onTap': <String, dynamic>{
          'actionType': 'like',
          'item': {'id': 99},
        },
      };
      StacBinding.injectItemContext(node, {'id': 7});
      expect(((node['onTap'] as Map)['item'] as Map)['id'], 99);
    });

    test('ignores nodes without an actionType', () {
      final node = <String, dynamic>{'type': 'text', 'data': 'x'};
      StacBinding.injectItemContext(node, {'id': 1});
      expect(node.containsKey('item'), isFalse);
    });
  });
}
