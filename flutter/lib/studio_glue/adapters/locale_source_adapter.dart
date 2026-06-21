import 'package:flutter/widgets.dart';
import 'package:utd_app/localization/locale_notifier.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// [LocaleSource] over the app's [LocaleNotifier] (for `core.setLocale`).
/// Swallows unsupported language codes, matching the original action behavior.
class LocaleSourceAdapter implements LocaleSource {
  const LocaleSourceAdapter(this._notifier);

  final LocaleNotifier _notifier;

  @override
  Future<void> setLanguage(String code) async {
    try {
      await _notifier.setLocale(Locale(code));
    } catch (_) {
      // Unsupported locale — ignore.
    }
  }
}
