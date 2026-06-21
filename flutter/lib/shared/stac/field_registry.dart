/// Re-export shim — `FieldRegistry` now lives in `utd_studio_sdk` (the vendored
/// SDUI SDK). The moment package imports this stable
/// `package:utd_app/shared/stac/field_registry.dart` path; this is a pure
/// re-export so there is exactly ONE `FieldRegistry` (the SDK's), shared by the
/// utdTextField parser and any package that references a field by id.
library;

export 'package:utd_studio_sdk/utd_studio_sdk.dart' show FieldRegistry;
