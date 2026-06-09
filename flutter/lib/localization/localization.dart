/// Public API for the localization system.
///
/// Import this single file to access the complete localization API:
/// - [AppTranslations] - Translation lookup object
/// - [AppLocalizationsDelegate] - Custom localizations delegate
/// - [LocaleNotifier] - Locale state management
/// - [LocalizationExtensions] - context.tr() and context.trArgs()
/// - [baseTranslations] - Base app translations
library;

export 'app_translations.dart';
export 'base_translations.dart';
export 'locale_notifier.dart';
export 'localization_delegate.dart';
export 'localization_extensions.dart';
