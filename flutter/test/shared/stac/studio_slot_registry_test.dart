import 'package:flutter_test/flutter_test.dart';
// Through the stable re-export shim under utd_app.
import 'package:utd_app/shared/stac/studio_slot_registry.dart';

/// Pure-Dart tests for the [StudioSlotRegistry] singleton: slot/screen-card
/// contribution, keyed overwrite (no duplicates), registration-order rendering,
/// deep-copied fragments, and screen-slot injection into a body's main column.
///
/// The registry is a singleton with a @visibleForTesting clear(); we reset it
/// before each test so order never matters.
void main() {
  final reg = StudioSlotRegistry.instance;
  setUp(reg.clear);
  tearDown(reg.clear);

  group('contributeToSlot / fragmentsFor', () {
    test('empty for an unknown slot', () {
      expect(reg.fragmentsFor('nope'), isEmpty);
    });

    test('registers and returns a node for a slot', () {
      reg.contributeToSlot('s', 'k1', {'type': 'text', 'data': 'hi'});
      final frags = reg.fragmentsFor('s');
      expect(frags.length, 1);
      expect(frags.single['data'], 'hi');
    });

    test('renders contributions in registration order', () {
      reg.contributeToSlot('s', 'a', {'type': 'text', 'data': 'A'});
      reg.contributeToSlot('s', 'b', {'type': 'text', 'data': 'B'});
      expect(reg.fragmentsFor('s').map((n) => n['data']), ['A', 'B']);
    });

    test('the same key overwrites instead of duplicating', () {
      reg.contributeToSlot('s', 'k', {'type': 'text', 'data': 'old'});
      reg.contributeToSlot('s', 'k', {'type': 'text', 'data': 'new'});
      final frags = reg.fragmentsFor('s');
      expect(frags.length, 1);
      expect(frags.single['data'], 'new');
    });

    test('fragmentsFor returns deep copies (mutating them is safe)', () {
      reg.contributeToSlot('s', 'k', {'type': 'text', 'data': 'hi'});
      final first = reg.fragmentsFor('s');
      first.single['data'] = 'mutated';
      // a fresh fetch is unaffected
      expect(reg.fragmentsFor('s').single['data'], 'hi');
    });
  });

  group('contributeScreenCard / screenCards', () {
    test('cards land under the screen-scoped slot', () {
      reg.contributeScreenCard('profile', 'wallet.coins', {'type': 'card'});
      expect(reg.screenCards('profile').length, 1);
      expect(reg.screenCards('other'), isEmpty);
    });

    test('repeated screen card key overwrites', () {
      reg.contributeScreenCard('profile', 'k', {'type': 'card', 'v': 1});
      reg.contributeScreenCard('profile', 'k', {'type': 'card', 'v': 2});
      expect(reg.screenCards('profile').single['v'], 2);
    });
  });

  group('injectScreenSlots', () {
    Map<String, dynamic> screen() => {
          'body': {
            'type': 'column',
            'children': [
              {'type': 'text', 'data': 'header'},
            ],
          },
        };

    test('returns input unchanged when no cards for the screen', () {
      final content = screen();
      final out = reg.injectScreenSlots('profile', content);
      expect(identical(out, content), isTrue);
    });

    test('appends cards to the main column without mutating the original', () {
      reg.contributeScreenCard('profile', 'c1', {'type': 'card', 'id': 'c1'});
      final content = screen();
      final out = reg.injectScreenSlots('profile', content);

      final outChildren = (out['body'] as Map)['children'] as List;
      expect(outChildren.length, 2);
      expect((outChildren.last as Map)['id'], 'c1');

      // original untouched
      final origChildren =
          (content['body'] as Map)['children'] as List;
      expect(origChildren.length, 1);
    });

    test('finds a nested column when there is no top-level one', () {
      reg.contributeScreenCard('profile', 'c1', {'type': 'card'});
      final content = {
        'body': {
          'type': 'scaffold',
          'child': {
            'type': 'column',
            'children': [
              {'type': 'text'}
            ],
          },
        },
      };
      final out = reg.injectScreenSlots('profile', content);
      final col = ((out['body'] as Map)['child'] as Map)['children'] as List;
      expect(col.length, 2);
    });

    test('returns input unchanged when no column exists to host the cards', () {
      reg.contributeScreenCard('profile', 'c1', {'type': 'card'});
      final content = {
        'body': {'type': 'text', 'data': 'no column here'},
      };
      final out = reg.injectScreenSlots('profile', content);
      expect(identical(out, content), isTrue);
    });
  });
}
