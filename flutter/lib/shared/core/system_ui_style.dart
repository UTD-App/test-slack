import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single source of truth for the app's system-UI (status bar + Android
/// navigation bar) appearance.
///
/// The app is edge-to-edge over a dark purple gradient, so both system bars
/// must be transparent with LIGHT (white) icons everywhere — otherwise Android
/// falls back to opaque black bars, and every Material [AppBar] would recompute
/// its own overlay style (making the status bar dark on some screens but not
/// others). Apply this in `main()` once AND on the global `appBarTheme` so it
/// holds on every page.
const SystemUiOverlayStyle kTransparentLightSystemUi = SystemUiOverlayStyle(
  // Status bar (top)
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android: white icons
  statusBarBrightness: Brightness.dark, // iOS: white icons
  // System navigation bar (bottom, under the in-app menu)
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);
