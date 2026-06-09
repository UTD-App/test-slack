import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the current locale, persists user preference, and supports
/// runtime locale switching.
///
/// Provided to the widget tree via [ChangeNotifierProvider]. When the locale
/// changes, [notifyListeners] triggers a rebuild of [MaterialApp.router],
/// which re-resolves all translations through the [AppLocalizationsDelegate].
///
/// Usage:
/// ```dart
/// // In main.dart
/// final localeNotifier = LocaleNotifier();
/// await localeNotifier.initialize(
///   supportedLocales: [Locale('en'), Locale('ar')],
///   fallbackLocale: Locale('en'),
/// );
///
/// // Switching locale from a widget
/// context.read<LocaleNotifier>().setLocale(Locale('ar'));
/// ```
class LocaleNotifier extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  late Locale _locale;
  late List<Locale> _supportedLocales;
  late Locale _fallbackLocale;

  /// The currently active locale.
  Locale get locale => _locale;

  /// The list of supported locales.
  List<Locale> get supportedLocales => _supportedLocales;

  /// Whether the current locale uses right-to-left text direction.
  bool get isRtl => _locale.languageCode == 'ar';

  /// Initializes the locale notifier.
  ///
  /// Reads the persisted locale preference from [SharedPreferences].
  /// If no preference exists and [useDeviceLocale] is true, uses the
  /// device's locale (clamped to [supportedLocales]).
  /// Otherwise falls back to [fallbackLocale].
  ///
  /// Must be called before [runApp].
  Future<void> initialize({
    required List<Locale> supportedLocales,
    required Locale fallbackLocale,
    bool useDeviceLocale = true,
  }) async {
    _supportedLocales = supportedLocales;
    _fallbackLocale = fallbackLocale;

    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);

    if (savedCode != null && _isSupported(savedCode)) {
      _locale = Locale(savedCode);
    } else if (useDeviceLocale) {
      final deviceLocale = PlatformDispatcher.instance.locale;
      _locale = _isSupported(deviceLocale.languageCode)
          ? Locale(deviceLocale.languageCode)
          : fallbackLocale;
    } else {
      _locale = fallbackLocale;
    }
  }

  /// Changes the active locale and persists the choice.
  ///
  /// Throws [ArgumentError] if the locale is not in [supportedLocales].
  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) {
      throw ArgumentError(
        'Locale "${locale.languageCode}" is not supported. '
        'Supported: ${_supportedLocales.map((l) => l.languageCode).join(", ")}',
      );
    }

    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Clears the persisted locale preference and reverts to the fallback.
  Future<void> resetLocale() async {
    _locale = _fallbackLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  bool _isSupported(String languageCode) {
    return _supportedLocales.any((l) => l.languageCode == languageCode);
  }
}
