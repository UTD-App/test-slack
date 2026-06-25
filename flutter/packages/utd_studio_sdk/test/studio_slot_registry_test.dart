import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

void main() {
  final registry = StudioSlotRegistry.instance;

  setUp(registry.clear);
  tearDown(registry.clear);

  // A screen body shaped like the published Studio screens:
  // singleChildScrollView → utdSized → container → column(children).
  Map<String, dynamic> screen() => {
        'body': {
          'type': 'singleChildScrollView',
          'child': {
            'type': 'utdSized',
            'child': {
              'type': 'container',
              'child': {
                'type': 'column',
                'spacing': 14,
                'children': [
                  {'type': 'text', 'data': 'header'},
                  {
                    'type': 'utdObject',
                    'source': 'profile.user',
                    'child': {'type': 'text', 'binding': 'profile.user.name'},
                  },
                ],
              },
            },
          },
        },
      };

  Map<String, dynamic> card() => {
        'type': 'utdObject',
        'source': 'wallet.balance',
        'child': {'type': 'text', 'binding': 'wallet.balance.coins'},
      };

  List mainColumnChildren(Map<String, dynamic> content) =>
      (((content['body'] as Map)['child'] as Map)['child']
          as Map)['child']['children'] as List;

  test('no contribution → content returned unchanged (same instance)', () {
    final input = screen();
    final out = registry.injectScreenSlots('profile', input);
    expect(identical(out, input), isTrue);
  });

  test('contributed card is appended to the screen main column', () {
    registry.contributeScreenCard('profile', 'wallet.coins', card());

    final out = registry.injectScreenSlots('profile', screen());
    final children = mainColumnChildren(out);

    expect(children.length, 3); // header + profile + appended card
    expect((children.last as Map)['source'], 'wallet.balance');
  });

  test('only injects on the matching screen name', () {
    registry.contributeScreenCard('profile', 'wallet.coins', card());

    final out = registry.injectScreenSlots('home', screen());
    expect(mainColumnChildren(out).length, 2); // untouched
  });

  test('input is never mutated; output is a deep copy', () {
    registry.contributeScreenCard('profile', 'wallet.coins', card());

    final input = screen();
    registry.injectScreenSlots('profile', input);
    expect(mainColumnChildren(input).length, 2); // original intact
  });

  test('re-registering the same key does not duplicate', () {
    registry.contributeScreenCard('profile', 'wallet.coins', card());
    registry.contributeScreenCard('profile', 'wallet.coins', card());

    final out = registry.injectScreenSlots('profile', screen());
    expect(mainColumnChildren(out).length, 3); // still one card
  });

  test('fragmentsFor exposes named-slot contributions', () {
    registry.contributeToSlot('profile.cards', 'wallet.coins', card());
    expect(registry.fragmentsFor('profile.cards').length, 1);
    expect(registry.fragmentsFor('missing'), isEmpty);
  });
}
