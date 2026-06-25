/// Gifts feature package — public API.
///
/// Add `GiftsFeature()` to `buildFeatures()` in the host app's `main.dart`.
/// Once registered it wires the GiftBridge so any feature (Moment, Reels…) can
/// open the gift picker via `GiftBridge.instance.open(...)`.
library;

export 'core/gifts_feature.dart';
