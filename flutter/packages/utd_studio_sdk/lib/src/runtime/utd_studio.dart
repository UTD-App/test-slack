import 'package:stac/stac.dart';

import '../actions/generic_actions.dart';
import '../core/stac_data_registry.dart';
import '../interfaces/interfaces.dart';
import '../parsers/builtin_parsers.dart';
import '../screen/stac_screen_store.dart';
import 'studio_config.dart';
import 'studio_runtime.dart';

/// The single public entry point for UTD Studio's server-driven UI runtime.
///
/// Call [init] once during app bootstrap (before `runApp`). It reproduces the
/// exact boot order the Base used:
///   1) `Stac.initialize(parsers, actionParsers)` (once)
///   2) `screenSource.init()` (open/ready the cache)
///   3) `screenSource.syncAll()` (background, fire-and-forget — never blocks)
/// so the no-spinner-flash startup is preserved.
class UtdStudio {
  UtdStudio._();

  static bool _stacInitialized = false;

  static Future<void> init(StudioConfig config) async {
    final StacScreenSource screenSource = config.screenSource ??
        StacScreenStore(transport: config.transport, cache: config.cache);

    // Publish the resolved ports so generic actions + StacDynamicScreen +
    // core.openDialog read THIS same screen source (never a fresh store).
    // Re-callable on app restart to refresh captured singletons.
    StudioRuntime.instance.configure(
      screenSource: screenSource,
      navigator: config.navigator,
      theme: config.theme,
      locale: config.locale,
      toast: config.toast,
      session: config.session,
      fallbackBuilder: config.fallbackBuilder,
    );

    // Stac.initialize is global/one-shot — register parsers + actions once.
    if (!_stacInitialized) {
      await Stac.initialize(
        parsers: [...builtinStacParsers, ...config.extraParsers],
        actionParsers: [...genericStacActionParsers, ...config.extraActions],
      );
      _stacInitialized = true;
    }

    await screenSource.init();
    screenSource.syncAll(); // background; matches the old StacService.syncAll()
  }

  // ---- Data-source registration pass-throughs (the ONE shared registry) ----

  static void registerList(String key, StacListSource source) =>
      StacDataRegistry.instance.registerList(key, source);

  static void registerObject(String key, StacObjectSource source) =>
      StacDataRegistry.instance.registerObject(key, source);

  static void invalidate() => StacDataRegistry.instance.invalidate();
}
