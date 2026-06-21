import 'package:flutter/material.dart';
import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

/// [ThemeSource] over the app's [ThemeNotifier] (for `core.toggleTheme`).
class ThemeSourceAdapter implements ThemeSource {
  const ThemeSourceAdapter(this._notifier);

  final ThemeNotifier _notifier;

  @override
  Future<void> setMode(String? modeName) async {
    switch (modeName) {
      case 'light':
        await _notifier.setThemeMode(ThemeMode.light);
      case 'dark':
        await _notifier.setThemeMode(ThemeMode.dark);
      case 'system':
        await _notifier.setThemeMode(ThemeMode.system);
      default:
        await _notifier.toggle();
    }
  }

  @override
  Future<void> toggle() => _notifier.toggle();
}
