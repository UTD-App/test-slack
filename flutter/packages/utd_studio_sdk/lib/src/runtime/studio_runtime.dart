import 'package:flutter/widgets.dart';

import '../interfaces/interfaces.dart';

/// Process-wide holder for the ports resolved at [UtdStudio.init].
///
/// The generic actions (`core.navigate`/`back`/`openDialog`/`closeDialog`/
/// `toggleTheme`/`setLocale`) and `StacDynamicScreen` read their dependencies
/// from here, so the package never imports app code. `configure` is idempotent
/// and may be re-called on app restart to refresh captured singletons.
class StudioRuntime {
  StudioRuntime._();
  static final StudioRuntime instance = StudioRuntime._();

  AppNavigator? navigator;
  ThemeSource? theme;
  LocaleSource? locale;
  ToastSink? toast;
  UserSession? session;
  WidgetBuilder? fallbackBuilder;

  /// Resolves a translation key → current-locale string (set from the app).
  StacTranslate? translate;

  StacScreenSource? _screenSource;

  /// The single resolved screen source. Both `StacDynamicScreen` and
  /// `core.openDialog` MUST read THIS instance (never construct a fresh store),
  /// otherwise dialogs/screens miss the cache synced at init.
  StacScreenSource get screenSource {
    final source = _screenSource;
    if (source == null) {
      throw StateError(
        'UTD Studio is not initialized. Call UtdStudio.init(StudioConfig(...)) '
        'before rendering server-driven screens.',
      );
    }
    return source;
  }

  bool get isConfigured => _screenSource != null;

  void configure({
    required StacScreenSource screenSource,
    AppNavigator? navigator,
    ThemeSource? theme,
    LocaleSource? locale,
    ToastSink? toast,
    UserSession? session,
    WidgetBuilder? fallbackBuilder,
    StacTranslate? translate,
  }) {
    _screenSource = screenSource;
    this.navigator = navigator;
    this.theme = theme;
    this.locale = locale;
    this.toast = toast;
    this.session = session;
    this.fallbackBuilder = fallbackBuilder;
    this.translate = translate;
  }
}
