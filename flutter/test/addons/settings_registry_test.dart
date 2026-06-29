import 'package:flutter_test/flutter_test.dart';
import 'package:utd_app/addons/settings_registry.dart';

/// Pure-Dart tests for [SettingsRegistry] and [UserSettingDefinition]:
/// register/override definitions, get/set values, default-value fallback,
/// set/clear bulk values, and the missing-key behavior.
void main() {
  late SettingsRegistry registry;
  setUp(() => registry = SettingsRegistry());

  group('UserSettingDefinition', () {
    test('holds its fields', () {
      const d = UserSettingDefinition(
        key: 'privacy.country_hidden',
        label: 'Hide Country',
        defaultValue: false,
        package: 'privacy',
      );
      expect(d.key, 'privacy.country_hidden');
      expect(d.label, 'Hide Country');
      expect(d.defaultValue, false);
      expect(d.package, 'privacy');
    });
  });

  group('registerSettings', () {
    test('registers definitions retrievable via allDefinitions', () {
      registry.registerSettings(const [
        UserSettingDefinition(key: 'a', label: 'A', defaultValue: 1),
        UserSettingDefinition(key: 'b', label: 'B', defaultValue: 2),
      ]);
      expect(registry.allDefinitions.length, 2);
      expect(registry.allDefinitions.map((d) => d.key), containsAll(['a', 'b']));
    });

    test('re-registering a key overwrites the previous definition', () {
      registry.registerSettings(
          const [UserSettingDefinition(key: 'k', label: 'Old', defaultValue: 1)]);
      registry.registerSettings(
          const [UserSettingDefinition(key: 'k', label: 'New', defaultValue: 2)]);
      expect(registry.allDefinitions.length, 1);
      expect(registry.allDefinitions.single.label, 'New');
      expect(registry.getValue<int>('k'), 2);
    });
  });

  group('getValue', () {
    test('falls back to the definition default when unset', () {
      registry.registerSettings(const [
        UserSettingDefinition(key: 'privacy.hidden', label: 'H', defaultValue: true),
      ]);
      expect(registry.getValue<bool>('privacy.hidden'), isTrue);
    });

    test('an explicitly set value wins over the default', () {
      registry.registerSettings(const [
        UserSettingDefinition(key: 'privacy.hidden', label: 'H', defaultValue: true),
      ]);
      registry.setValue('privacy.hidden', false);
      expect(registry.getValue<bool>('privacy.hidden'), isFalse);
    });

    test('a nullable type for a fully-unknown key returns null', () {
      // No definition, no value → (def?.defaultValue as T?) ?? (null as T).
      // For a nullable T (bool?), this is null (safe).
      expect(registry.getValue<bool?>('does.not.exist'), isNull);
    });

    test('set then get round-trips an arbitrary value', () {
      registry.setValue('x', 'hello');
      expect(registry.getValue<String>('x'), 'hello');
    });
  });

  group('setValues / clearValues', () {
    test('setValues replaces all values', () {
      registry.setValues({'a': 1, 'b': 2});
      expect(registry.allValues, {'a': 1, 'b': 2});
      registry.setValues({'c': 3});
      expect(registry.allValues, {'c': 3});
    });

    test('clearValues empties values but keeps definitions', () {
      registry.registerSettings(
          const [UserSettingDefinition(key: 'a', label: 'A', defaultValue: 9)]);
      registry.setValues({'a': 1});
      registry.clearValues();
      expect(registry.allValues, isEmpty);
      // definition default is restored as the effective value
      expect(registry.getValue<int>('a'), 9);
      expect(registry.allDefinitions.length, 1);
    });
  });

  test('allValues is an unmodifiable snapshot', () {
    registry.setValue('a', 1);
    final snap = registry.allValues;
    expect(() => snap['b'] = 2, throwsUnsupportedError);
  });

  test('notifyListeners fires on setValue/setValues/clearValues', () {
    var count = 0;
    registry.addListener(() => count++);
    registry.setValue('a', 1);
    registry.setValues({'b': 2});
    registry.clearValues();
    expect(count, 3);
  });
}
