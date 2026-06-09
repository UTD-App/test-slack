import 'package:flutter/widgets.dart';

import 'app_translations.dart';

/// Ergonomic [BuildContext] extensions for accessing translations.
///
/// Usage:
/// ```dart
/// // Simple translation
/// Text(context.tr('auth.login_title'))
///
/// // Translation with arguments
/// Text(context.trArgs('auth.welcome', {'name': 'John'}))
/// ```
extension LocalizationExtensions on BuildContext {
  /// Translates a key to the current locale's string.
  ///
  /// Fallback: current locale → English → raw key.
  String tr(String key) => AppTranslations.of(this).translate(key);

  /// Translates a key with argument interpolation.
  ///
  /// Replaces `{argName}` placeholders with values from [args].
  String trArgs(String key, Map<String, String> args) =>
      AppTranslations.of(this).translateWithArgs(key, args);

  /// Access the full [AppTranslations] object directly.
  AppTranslations get translations => AppTranslations.of(this);
}
