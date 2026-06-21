import 'package:stac/stac.dart' show StacParser, StacActionParser;

/// The minimal Stac contribution SPI.
///
/// `utd_app`'s `AppFeature` mixes this in (so its existing API is unchanged),
/// and a feature package (e.g. `chatPackageV2`) reaches these two methods via
/// this SDK — WITHOUT depending on the host app's full `AppFeature` / add-on
/// platform. `UtdStudio.init` consumes the aggregated lists through
/// `StudioConfig.extraParsers` / `extraActions`.
mixin StacContributor {
  List<StacParser> getStacParsers() => const [];
  List<StacActionParser> getStacActionParsers() => const [];
}
