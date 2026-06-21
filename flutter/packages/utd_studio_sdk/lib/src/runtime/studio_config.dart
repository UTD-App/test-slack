import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart' show StacParser, StacActionParser;

import '../interfaces/interfaces.dart';

/// Everything the host app wires into UTD Studio once, at boot, via
/// [UtdStudio.init]. Required ports: [transport] + [cache]. The rest are
/// optional and only needed if you use the corresponding actions.
class StudioConfig {
  const StudioConfig({
    required this.transport,
    required this.cache,
    this.navigator,
    this.theme,
    this.locale,
    this.toast,
    this.session,
    this.screenSource,
    this.fallbackBuilder,
    this.extraParsers = const [],
    this.extraActions = const [],
  });

  /// HTTP transport for `/stac`, `/stac/{name}`, `/stac/{name}/version`, etc.
  final StacTransport transport;

  /// Namespaced key/value store (screen JSON under `'stac_screens'`).
  final KeyValueCache cache;

  /// For `core.navigate` / `core.back` / `core.openDialog`.
  final AppNavigator? navigator;

  /// For `core.toggleTheme`.
  final ThemeSource? theme;

  /// For `core.setLocale`.
  final LocaleSource? locale;

  /// Toast sink used by the package and app-glue actions.
  final ToastSink? toast;

  /// The signed-in user as JSON (optional).
  final UserSession? session;

  /// Override the default [StacScreenStore] (e.g. for tests).
  final StacScreenSource? screenSource;

  /// Default fallback for `StacDynamicScreen` when a screen isn't published yet.
  final WidgetBuilder? fallbackBuilder;

  /// Custom widget parsers (e.g. aggregated from feature packages).
  final List<StacParser> extraParsers;

  /// App-specific actions (e.g. `core.login` / `core.logout` glue).
  final List<StacActionParser> extraActions;
}
