import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_translations.dart';

/// Custom [LocalizationsDelegate] that provides [AppTranslations]
/// to the widget tree.
///
/// Holds the aggregated translation map (all locales, all features merged).
/// Creates [AppTranslations] instances synchronously since translations
/// are already in memory as Dart const maps.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppTranslations> {
  final Map<String, Map<String, String>> translations;

  const AppLocalizationsDelegate(this.translations);

  @override
  bool isSupported(Locale locale) {
    return translations.containsKey(locale.languageCode);
  }

  @override
  Future<AppTranslations> load(Locale locale) {
    return SynchronousFuture(
      AppTranslations(translations, locale.languageCode),
    );
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) {
    return !identical(translations, old.translations);
  }
}
