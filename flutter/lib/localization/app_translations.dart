import 'package:flutter/widgets.dart';

/// Holds the aggregated translation map and provides lookup methods.
///
/// This is the `Localizations` object resolved through Flutter's localization
/// framework via `Localizations.of<AppTranslations>(context)`.
///
/// Lookup chain: current locale → English fallback → raw key.
/// This ensures missing translations are visible during development
/// (the raw key appears in the UI) and never cause crashes.
class AppTranslations {
  final Map<String, Map<String, String>> _translations;
  final String _currentLocale;

  const AppTranslations(this._translations, this._currentLocale);

  /// Translates a key to the current locale's string.
  ///
  /// Fallback chain:
  /// 1. Current locale translation
  /// 2. English ('en') translation
  /// 3. The raw key itself (makes missing translations obvious)
  String translate(String key) {
    return _translations[_currentLocale]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  /// Translates a key with argument interpolation.
  ///
  /// Replaces `{argName}` placeholders in the translated string with values
  /// from the [args] map.
  ///
  /// Example:
  /// ```dart
  /// // Translation: 'auth.welcome': 'Welcome back, {name}!'
  /// translateWithArgs('auth.welcome', {'name': 'John'})
  /// // Returns: 'Welcome back, John!'
  /// ```
  String translateWithArgs(String key, Map<String, String> args) {
    var result = translate(key);
    for (final entry in args.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// Retrieves the [AppTranslations] instance from the widget tree.
  static AppTranslations of(BuildContext context) {
    return Localizations.of<AppTranslations>(context, AppTranslations)!;
  }
}
