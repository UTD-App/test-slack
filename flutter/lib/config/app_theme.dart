import 'dart:ui';

import 'package:utd_app/shared/core/color_manager.dart';

/// Runtime, admin-controllable color palette. Every field defaults to this
/// build's built-in [ColorManager] "lumia" token, so an empty/absent backend
/// config leaves the app looking exactly as it does now (whatever palette the
/// current build ships). Populated once at launch from the `/app-version`
/// `theme` block (see LaunchGateService), read by the ThemeData builder and the
/// gradient widgets.
class AppPalette {
  final Color primary; // brand accent (buttons, highlights)
  final Color accent; // secondary accent
  final Color bgDark; // scaffold / surface / app bar
  final List<Color> bgGradient; // full-screen background gradient
  final Color cardBg; // card fill
  final Color cardBorder; // card border / gradient end
  final Color textPrimary;
  final Color textSecondary;

  const AppPalette({
    this.primary = ColorManager.lumiaAccent,
    this.accent = ColorManager.lumiaAccentLight,
    this.bgDark = ColorManager.lumiaBgDark,
    this.bgGradient = ColorManager.lumiaBgGradient,
    this.cardBg = ColorManager.lumiaCardBg,
    this.cardBorder = ColorManager.lumiaCardBorder,
    this.textPrimary = ColorManager.lumiaTextPrimary,
    this.textSecondary = ColorManager.lumiaTextSecondary,
  });

  /// Built-in defaults — used until the backend palette resolves (or if it
  /// fails / a field is blank). Equal to this build's [ColorManager] tokens.
  static const fallback = AppPalette();

  factory AppPalette.fromJson(Map<String, dynamic> t) {
    Color c(Object? hex, Color d) => parseHexColor(hex as String?) ?? d;
    return AppPalette(
      primary: c(t['primary'], fallback.primary),
      accent: c(t['accent'], fallback.accent),
      bgDark: c(t['bg_dark'], fallback.bgDark),
      bgGradient: [
        c(t['bg_gradient_1'], fallback.bgGradient[0]),
        c(t['bg_gradient_2'], fallback.bgGradient[1]),
        c(t['bg_gradient_3'], fallback.bgGradient[2]),
      ],
      cardBg: c(t['card_bg'], fallback.cardBg),
      cardBorder: c(t['card_border'], fallback.cardBorder),
      textPrimary: c(t['text_primary'], fallback.textPrimary),
      textSecondary: c(t['text_secondary'], fallback.textSecondary),
    );
  }
}

/// App-wide access to the active palette (set once the launch gate resolves).
/// Reads [AppPalette.fallback] until then, so the app always has valid colors.
class AppThemeProvider {
  static AppPalette current = AppPalette.fallback;
}

/// Parse `#RRGGBB` / `#AARRGGBB` (or without `#`) into a [Color]; null on bad input.
Color? parseHexColor(String? input) {
  if (input == null) return null;
  var hex = input.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}
