import 'package:utd_app/config/theme_notifier.dart';
import 'package:utd_app/localization/locale_notifier.dart';
import 'package:utd_studio_sdk/utd_studio_sdk.dart';

import 'actions/app_actions.dart';
import 'adapters/dio_stac_transport.dart';
import 'adapters/go_router_navigator.dart';
import 'adapters/hive_key_value_cache.dart';
import 'adapters/locale_source_adapter.dart';
import 'adapters/theme_source_adapter.dart';
import 'sources/core_stac_sources.dart';

/// Boots UTD Studio for the Base app: opens the screen cache, wires the glue
/// adapters + app-specific actions, runs the one-shot `UtdStudio.init` (which
/// performs `Stac.initialize` → screen store init → background sync in order),
/// then registers the base's own data sources.
///
/// Call once from `main()` AFTER `ApiClient.initialize` (the transport needs the
/// Dio client ready) and after the theme/locale notifiers are created.
Future<void> bootstrapStudio({
  required ThemeNotifier themeNotifier,
  required LocaleNotifier localeNotifier,
  required List<StacParser> featureParsers,
  required List<StacActionParser> featureActionParsers,
}) async {
  final cache = await HiveKeyValueCache.open();

  await UtdStudio.init(StudioConfig(
    transport: const DioStacTransport(),
    cache: cache,
    navigator: const GoRouterNavigator(),
    theme: ThemeSourceAdapter(themeNotifier),
    locale: LocaleSourceAdapter(localeNotifier),
    extraParsers: featureParsers,
    extraActions: [...appCoreActionParsers, ...featureActionParsers],
  ));

  // Base app's own core data sources (core.currentUser + core.app branding).
  registerCoreStacSources();
  registerCoreAppSource();
}
