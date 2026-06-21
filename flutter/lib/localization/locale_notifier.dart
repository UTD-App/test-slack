import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/client/api_client.dart';

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
  Set<String> _rtlCodes = const {'ar'};
  Map<String, String> _names = const {};

  /// The currently active locale.
  Locale get locale => _locale;

  /// The list of supported locales.
  List<Locale> get supportedLocales => _supportedLocales;

  /// Whether the current locale uses right-to-left text direction. Driven by the
  /// backend's `is_rtl` flags (so any RTL language added in the admin works), not
  /// a hardcoded 'ar'.
  bool get isRtl => _rtlCodes.contains(_locale.languageCode);

  /// Native display name of a language (e.g. 'العربية', 'Français') from the
  /// backend; falls back to the upper-cased code for an unknown one.
  String nameFor(String languageCode) =>
      _names[languageCode] ?? languageCode.toUpperCase();

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
    Set<String> rtlCodes = const {'ar'},
    Map<String, String> names = const {},
  }) async {
    _supportedLocales = supportedLocales;
    _fallbackLocale = fallbackLocale;
    _rtlCodes = rtlCodes;
    _names = names;

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

  /// Replace the supported-language set at runtime (after a fresh fetch from the
  /// backend), so a language added in the admin shows up without a relaunch.
  /// Keeps the current locale.
  void applySupported(
    List<Locale> supportedLocales, {
    Set<String> rtlCodes = const {'ar'},
    Map<String, String> names = const {},
  }) {
    if (supportedLocales.isEmpty) return;

    _supportedLocales = supportedLocales;
    _rtlCodes = rtlCodes;
    _names = names;
    notifyListeners();
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
    _syncApiLocaleHeader();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Clears the persisted locale preference and reverts to the fallback.
  Future<void> resetLocale() async {
    _locale = _fallbackLocale;
    _syncApiLocaleHeader();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Keep the backend's `X-localization` header in step with the active locale,
  /// so server-rendered text (notifications feed + push) follows the UI language
  /// and device-token registration stores the right locale. Best-effort: a no-op
  /// if the API client isn't initialized yet (main.dart sets the initial header
  /// right after ApiClient.initialize()).
  void _syncApiLocaleHeader() {
    try {
      ApiClient.instance.setHeader('X-localization', _locale.languageCode);
    } catch (_) {
      // ApiClient not ready (early startup / tests).
    }
  }

  bool _isSupported(String languageCode) {
    return _supportedLocales.any((l) => l.languageCode == languageCode);
  }
}
