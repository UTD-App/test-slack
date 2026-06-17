# Audio Room Package - Integration Guide

Complete setup guide for integrating the `audio_room` package into a host app built on the UTD base-project.

---

## Prerequisites

- UTD base-project (https://github.com/UTD-App/base-project)
- `utd_audio_room_kit` package (provides `UTDMiniOverlayMachine`, `UTDRoomController`, etc.)

---

## Step 1: Add dependency

In your app's `pubspec.yaml`:

```yaml
dependencies:
  audio_room:
    path: packages/audio-room/flutter

  # If using plugins (e.g. charisma):
  audio_room_charisma:
    path: packages/audio-room/plugins/charisma/flutter
```

Run `flutter pub get`.

---

## Step 2: Android — one line

In `android/app/src/main/AndroidManifest.xml`, add `supportsPictureInPicture` to your Activity:

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    ...>
```

That's it. The plugin handles everything else automatically:
- **PiP lifecycle** (`onUserLeaveHint`, state detection) is handled by the plugin via `ActivityPluginBinding`.

Your `MainActivity.kt` stays as the default:

```kotlin
class MainActivity : FlutterActivity()
```

---

## Step 3: Register the feature

In `main.dart`, create the `AudioRoomFeature` and register any plugins:

```dart
import 'package:audio_room/audio_room.dart';

List<AppFeature> buildFeatures() {
  final audioRoom = AudioRoomFeature();

  // Register plugins (optional)
  // audioRoom.registerPlugin(CharismaPlugin());

  return [
    // ...other features
    audioRoom,
  ];
}
```

The feature auto-registers its routes (`/rooms`, `/rooms/:id`, `/rooms/create`, `/rooms/:id/settings`) via the base-project's `FeatureRegistry`.

---

## Step 4: Add the overlay to `app.dart`

The `AudioRoomAppOverlay` manages the full room lifecycle: room page, mini overlay (minimized), and PiP view (background).

In `MaterialApp.router`'s `builder`:

```dart
import 'package:audio_room/audio_room.dart';

MaterialApp.router(
  routerConfig: router,
  builder: (context, child) {
    return AudioRoomAppOverlay(
      router: router,
      child: child!,
    );
  },
);
```

> Pass the `GoRouter` instance because the builder's context is above GoRouter in the widget tree.

---

## Done

That's the complete setup. Full rebuild required after adding the dependency (not hot reload).

---

## What the package handles

| Feature | How |
|---------|-----|
| **Room page** | Rendered in an overlay above the router — stays alive across minimize/restore |
| **Minimize** | Back button minimizes the room, showing a draggable mini overlay |
| **Restore** | Tap the mini overlay to restore the room (same instance, no rebuild) |
| **PiP** | Auto-enters PiP when the user leaves the app while in a room |
| **Background audio** | Audio stays connected while minimized or in PiP |
| **Back button** | Intercepted by the overlay — minimizes room instead of exiting the app |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────┐
│  Host App (base-project)                         │
│                                                  │
│  main.dart         Register AudioRoomFeature     │
│  app.dart          AudioRoomAppOverlay wrapper    │
│  AndroidManifest   supportsPictureInPicture=true  │
│  MainActivity.kt   class MainActivity :          │
│                     FlutterActivity()  (default)  │
├──────────────────────────────────────────────────┤
│  audio_room package (Flutter plugin)             │
│                                                  │
│  Dart:                                           │
│    AudioRoomFeature        Feature registration  │
│    AudioRoomAppOverlay     Room + mini + PiP UI  │
│    AudioRoomPage           Full room view        │
│    AudioRoomRoutes         Route definitions     │
│    PipManager              PiP state (Dart side) │
│                                                  │
│  Android native (plugin):                        │
│    AudioRoomPlugin.kt      PiP bridge            │
├──────────────────────────────────────────────────┤
│  utd_audio_room_kit (external)                   │
│                                                  │
│    UTDMiniOverlayMachine   State machine (idle/  │
│                            inAudioRoom/minimizing)│
│    UTDRoomController       Room connection       │
│    UTDAudioRoom            Room widget           │
└──────────────────────────────────────────────────┘
```

---

## Quick Checklist

- [ ] `pubspec.yaml` — added `audio_room` dependency
- [ ] `AndroidManifest.xml` — added `android:supportsPictureInPicture="true"` on Activity
- [ ] `main.dart` — registered `AudioRoomFeature` in `buildFeatures()`
- [ ] `app.dart` — wrapped router output with `AudioRoomAppOverlay`
- [ ] Full rebuild (not hot reload) after adding the package
