# Audio Room Package - Integration Guide

Complete setup guide for integrating the `audio_room` package into a host app built on the UTD base-project.

---

## Prerequisites

- UTD base-project (`https://github.com/UTD-App/base-project`)
- UTD Stream credentials (app ID + server secret)

---

## Step 1: Add the package as a git submodule

```bash
cd flutter/packages
git submodule add -b test https://github.com/UTD-App/audio-room.git audio-room
```

This places the package at `flutter/packages/audio-room/` — the exact path the package expects.

---

## Step 2: Add dependencies in `flutter/pubspec.yaml`

```yaml
dependencies:
  utd_audio_room_kit: ^1.0.1
  audio_room:
    path: packages/audio-room/flutter

  # Optional plugins:
  audio_room_charisma:
    path: packages/audio-room/plugins/charisma/flutter
```

```bash
cd flutter
flutter pub get
```

---

## Step 3: Add UTD Stream credentials in `flutter/lib/config/app_config.dart`

Add these fields to the `AppConfig` class:

```dart
final String utdStreamAppId;
final String utdStreamServerSecret;
```

In the constructor:

```dart
this.utdStreamAppId = '',
this.utdStreamServerSecret = '',
```

In `factory AppConfig.production()`:

```dart
utdStreamAppId: 'YOUR_APP_ID',
utdStreamServerSecret: 'YOUR_SERVER_SECRET',
```

In `copyWith()`:

```dart
String? utdStreamAppId,
String? utdStreamServerSecret,
// ...
utdStreamAppId: utdStreamAppId ?? this.utdStreamAppId,
utdStreamServerSecret: utdStreamServerSecret ?? this.utdStreamServerSecret,
```

---

## Step 4: Register the feature in `flutter/lib/main.dart`

```dart
import 'package:audio_room/audio_room.dart';

List<AppFeature> buildFeatures() {
  final audioRoom = AudioRoomFeature();

  // Optional plugins:
  // audioRoom.registerPlugin(CharismaPlugin());

  return [
    AuthFeature(),
    audioRoom,
  ];
}
```

Routes (`/rooms`, `/rooms/create`, `/rooms/:id`, `/rooms/:id/settings`) are auto-registered via `FeatureRegistry`.

---

## Step 5: Add the overlay in `flutter/lib/app.dart`

```dart
import 'package:audio_room/audio_room.dart';

// Inside MaterialApp.router:
builder: (context, child) {
  return AudioRoomAppOverlay(
    router: router,
    child: child!,
  );
},
```

---

## Step 6: Android permissions in `flutter/android/app/src/main/AndroidManifest.xml`

Add before `<application>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

Add to `<activity>`:

```xml
android:supportsPictureInPicture="true"
```

`MainActivity.kt` stays as the default — the plugin handles PiP automatically:

```kotlin
class MainActivity : FlutterActivity()
```

---

## Step 7: Backend setup (Laravel)

Register the service provider in `backend/config/app.php`:

```php
'providers' => [
    // ...
    \AudioRoom\Providers\AudioRoomServiceProvider::class,
],
```

Add to `backend/.env`:

```
UTD_STREAM_APP_ID=your_app_id
UTD_STREAM_SERVER_SECRET=your_secret
```

Run:

```bash
cd backend
composer dump-autoload
php artisan migrate
```

---

## Quick Checklist

- [ ] `git submodule add` — added `audio-room` in `flutter/packages/`
- [ ] `pubspec.yaml` — added `utd_audio_room_kit` + `audio_room` path dependency
- [ ] `app_config.dart` — added `utdStreamAppId` + `utdStreamServerSecret`
- [ ] `main.dart` — registered `AudioRoomFeature` in `buildFeatures()`
- [ ] `app.dart` — wrapped with `AudioRoomAppOverlay`
- [ ] `AndroidManifest.xml` — added `RECORD_AUDIO`, `BLUETOOTH_CONNECT`, PiP
- [ ] Backend — registered `AudioRoomServiceProvider`, `.env` credentials, `migrate`
- [ ] Full rebuild (`flutter run`, not hot reload)

---

## What the package handles automatically

| Feature | How |
|---------|-----|
| Room page | Rendered in an overlay above the router |
| Minimize | Back button shows exit/minimize dialog |
| Mini overlay | Draggable floating widget when minimized |
| PiP | Auto-enters PiP when user leaves the app |
| Background audio | Audio stays connected while minimized or in PiP |
| Bottom nav tab | "Rooms" tab auto-registered via `UiContribution` |
| Routes | Auto-aggregated via `FeatureRegistry` |
