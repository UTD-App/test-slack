import 'package:flutter_test/flutter_test.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

void main() {
  group('genericStacActionParsers', () {
    test('registers the six core.* actions with unique types', () {
      final types = genericStacActionParsers.map((p) => p.actionType).toList();
      expect(
        types,
        containsAll(<String>[
          'core.navigate',
          'core.back',
          'core.openDialog',
          'core.closeDialog',
          'core.toggleTheme',
          'core.setLocale',
        ]),
      );
      // No duplicate action types.
      expect(types.toSet().length, types.length);
      expect(types, hasLength(6));
    });

    test('every action type is namespaced under "core."', () {
      for (final p in genericStacActionParsers) {
        expect(p.actionType, startsWith('core.'));
      }
    });
  });

  group('StacMapActionParser.getModel (the map IS the model)', () {
    test('returns the raw json map unchanged', () {
      // The navigate parser is a StacMapActionParser; getModel echoes its input.
      final navigate = genericStacActionParsers
          .firstWhere((p) => p.actionType == 'core.navigate');
      final json = {'actionType': 'core.navigate', 'route': '/x', 'mode': 'push'};
      final model = navigate.getModel(json);
      expect(identical(model, json), isTrue);
    });
  });

  group('builtinStacParsers', () {
    test('registers all nine utd* widget parsers with unique types', () {
      final types = builtinStacParsers.map((p) => p.type).toList();
      expect(
        types,
        containsAll(<String>[
          'utdList',
          'utdObject',
          'utdScroll',
          'utdSized',
          'utdSlot',
          'utdLoading',
          'utdTabs',
          'utdTextField',
          'utdPositionedDirectional',
        ]),
      );
      expect(types.toSet().length, types.length);
      expect(types, hasLength(9));
    });
  });
}
