/// Re-export shim — `StacDataRegistry` now lives in `utd_studio_sdk` (the
/// vendored SDUI SDK). Feature PACKAGES (profile/moment/…) depend on `utd_app`
/// but not on `utd_studio_sdk` directly, so they keep importing this stable
/// `package:utd_app/shared/stac/stac_data_registry.dart` path. This is a pure
/// re-export — there is exactly ONE `StacDataRegistry` singleton (the SDK's),
/// so sources registered here and screens rendered by the SDK share it.
library;

export 'package:utd_studio_sdk/utd_studio_sdk.dart' show StacDataRegistry;
