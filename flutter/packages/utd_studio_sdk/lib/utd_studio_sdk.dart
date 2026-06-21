/// UTD Studio — the Flutter Server-Driven UI runtime.
///
/// A vendored fork of `stac` (bundled under `vendor/`) plus the UTD layer:
/// the data-binding registry, the `utd*` widget parsers, the generic `core.*`
/// actions, the screen store, and a single [UtdStudio.init] facade.
///
/// Consumers import ONLY this barrel — never `package:stac/...`.
library;

// Curated re-export of the vendored Stac extension API (NOT a blanket export;
// deliberately does NOT expose the upstream `StacService`, which we replaced
// with `StacScreenStore`). Grep consumers for any other `package:stac` symbol
// before adding it here.
export 'package:stac/stac.dart' show Stac, StacParser, StacActionParser, StacFormScope;

// Public runtime / facade.
export 'src/runtime/utd_studio.dart';
export 'src/runtime/studio_config.dart';
export 'src/runtime/studio_runtime.dart' show StudioRuntime;

// Injectable ports the host app implements.
export 'src/interfaces/interfaces.dart';

// Stac contribution SPI (AppFeature mixes this; feature packages reach it here).
export 'src/spi/stac_contributor.dart';

// Data binding + registries (shared by Base core.* and chat chat.* — ONE singleton).
export 'src/core/stac_data_registry.dart';
export 'src/core/stac_binding.dart'; // StacBinding.injectItemContext is public
export 'src/core/field_registry.dart';
export 'src/core/stac_coerce.dart';

// Render API + screen source.
export 'src/screen/stac_dynamic_screen.dart';
export 'src/screen/stac_screen_store.dart' show StacScreenStore;

// Action base + form helper (so the app can author custom actions).
export 'src/actions/stac_map_action.dart';

// Built-in parsers / generic actions (exposed so an app can inspect/extend the set).
export 'src/parsers/builtin_parsers.dart';
export 'src/actions/generic_actions.dart' show genericStacActionParsers;
