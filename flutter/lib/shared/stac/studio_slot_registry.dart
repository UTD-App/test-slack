/// Re-export shim — `StudioSlotRegistry` lives in `utd_studio_sdk` (the vendored
/// SDUI SDK). Feature PACKAGES (wallet/profile/…) depend on `utd_app` but not on
/// `utd_studio_sdk` directly, so they keep importing this stable
/// `package:utd_app/shared/stac/studio_slot_registry.dart` path. Pure re-export:
/// there is exactly ONE `StudioSlotRegistry` singleton (the SDK's), so cards a
/// package contributes here and screens the SDK renders share it.
library;

export 'package:utd_studio_sdk/utd_studio_sdk.dart' show StudioSlotRegistry;
