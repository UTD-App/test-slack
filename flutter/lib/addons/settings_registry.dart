import 'package:flutter/foundation.dart';

/// Definition of a user-level setting contributed by a package.
///
/// Keys use dot-namespacing to avoid collisions:
/// ```dart
/// UserSettingDefinition(
///   key: 'privacy.country_hidden',
///   label: 'Hide Country',
///   defaultValue: false,
/// )
/// ```
class UserSettingDefinition {
  final String key;
  final String label;
  final dynamic defaultValue;
  final String? package;

  const UserSettingDefinition({
    required this.key,
    required this.label,
    this.defaultValue,
    this.package,
  });
}

/// Central registry for user-level settings across all packages.
///
/// Packages register their [UserSettingDefinition]s during feature
/// initialization. Values are loaded from the API and cached locally.
///
/// Usage:
/// ```dart
/// final settings = context.read<FeatureRegistry>().settingsRegistry;
/// final hidden = settings.getValue<bool>('privacy.country_hidden');
/// settings.setValue('privacy.country_hidden', true);
/// ```
class SettingsRegistry extends ChangeNotifier {
  final Map<String, UserSettingDefinition> _definitions = {};
  final Map<String, dynamic> _values = {};

  void registerSettings(List<UserSettingDefinition> settings) {
    for (final setting in settings) {
      _definitions[setting.key] = setting;
    }
  }

  void setValues(Map<String, dynamic> values) {
    _values
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void clearValues() {
    _values.clear();
    notifyListeners();
  }

  T getValue<T>(String key) {
    if (_values.containsKey(key)) {
      return _values[key] as T;
    }
    final def = _definitions[key];
    return (def?.defaultValue as T?) ?? (null as T);
  }

  void setValue(String key, dynamic value) {
    _values[key] = value;
    notifyListeners();
  }

  Map<String, dynamic> get allValues => Map.unmodifiable(_values);

  List<UserSettingDefinition> get allDefinitions =>
      List.unmodifiable(_definitions.values);
}
