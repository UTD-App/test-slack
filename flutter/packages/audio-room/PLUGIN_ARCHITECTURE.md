# Audio Room Plugin Architecture

## Overview

The Audio Room and its plugins (e.g. Charisma) are **completely decoupled** — neither knows the other exists. They communicate through an abstract contract (`AudioRoomPlugin`), and a third party (`main.dart`) wires them together at startup.

```
┌─────────────────────────────────────────────┐
│             main.dart (Mediator)             │  ← The only place that knows both
├─────────────────────────────────────────────┤
│                                             │
│   Audio Room             Charisma Plugin    │  ← Can't see each other
│   (Package)              (Plugin)           │
│                                             │
├─────────────────────────────────────────────┤
│        AudioRoomPlugin (The Contract)        │  ← Shared abstract class
└─────────────────────────────────────────────┘
```

---

## Layer 1: The Contract (AudioRoomPlugin)

**File:** `flutter/lib/src/audio_room_plugin.dart`

An abstract class that defines what any plugin must provide:

```dart
abstract class AudioRoomPlugin {
  String get id;                          // Unique identifier (e.g. 'charisma')
  String get displayName;                 // Human-readable name

  // UI Slots — the plugin fills these with its own widgets
  Widget? buildControlsWidget(context, roomId);   // Button in the controls bar
  Widget? buildSeatBadge(context, userId, roomId); // Badge on each seat
  List<PluginSettingRow> getSettingRows(context, roomId); // Rows in room settings

  // Lifecycle — the room notifies the plugin about events
  void onRoomEnter(roomId, userId);
  void onRoomExit(roomId, userId);
  void onControllerReady(controller);

  // RTM — real-time message routing
  List<String> get rtmMessageTypes;       // Message types this plugin cares about
  void onRtmMessage(type, data);          // Called when a matching message arrives

  // Conflict resolution
  List<String> get conflictsWith;         // Plugin IDs that can't run alongside this one
}
```

The Audio Room **only knows this contract**. It never imports or references any concrete plugin.

---

## Layer 2: The Audio Room (Consumer)

**File:** `flutter/lib/src/audio_room_feature.dart`

The Audio Room holds an empty list and a registration method:

```dart
class AudioRoomFeature {
  final List<AudioRoomPlugin> _plugins = [];

  void registerPlugin(AudioRoomPlugin plugin) {
    _plugins.add(plugin);
  }

  static List<AudioRoomPlugin> get registeredPlugins => _instance?._plugins ?? [];
}
```

**File:** `flutter/lib/src/presentation/view/audio_room_page.dart`

The Audio Room loops over `registeredPlugins` at every integration point — without knowing who's inside:

### On Room Enter (line ~101)
```dart
for (final plugin in AudioRoomFeature.registeredPlugins) {
  plugin.onRoomEnter(room.id, userId);
}
```

### On RTM Message (line ~147)
```dart
for (final plugin in AudioRoomFeature.registeredPlugins) {
  if (plugin.rtmMessageTypes.contains(type)) {
    plugin.onRtmMessage(type, data);
  }
}
```

### Controls Bar UI (line ~318)
```dart
...AudioRoomFeature.registeredPlugins
    .map((p) => p.buildControlsWidget(context, room.id))
    .where((w) => w != null)
    .cast<Widget>()
```

### Seat Badges (in `seat_avatar_widget.dart`)
```dart
...AudioRoomFeature.registeredPlugins
    .map((p) => p.buildSeatBadge(context, userId, roomId))
    .where((w) => w != null)
    .cast<Widget>()
```

### Room Settings (in `room_settings_page.dart`)
```dart
for (final plugin in plugins) {
  rows.addAll(plugin.getSettingRows(context, widget.room.id));
}
```

The Audio Room never calls `CharismaPlugin.something()` — it always calls `plugin.something()` on whatever is in the list.

---

## Layer 3: The Charisma Plugin (Provider)

**File:** `plugins/charisma/flutter/lib/src/charisma_plugin.dart`

Charisma implements the contract and fills the slots:

```dart
class CharismaPlugin extends AudioRoomPlugin {
  @override
  String get id => 'charisma';

  @override
  String get displayName => 'Charisma';

  @override
  List<String> get conflictsWith => ['pk', 'cinema'];

  @override
  List<String> get rtmMessageTypes => ['updateCharisma', 'startCharisma', 'closeCharisma'];

  @override
  void onRoomEnter(int roomId, String userId) {
    _bloc.add(LoadRoomCharismaEvent(roomId: roomId));
  }

  @override
  void onRtmMessage(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'startCharisma':  // activate charisma
      case 'closeCharisma':  // deactivate charisma
      case 'updateCharisma': // update points
    }
  }

  @override
  Widget? buildControlsWidget(context, roomId) {
    // Returns a pink heart button that opens the leaderboard
  }

  @override
  Widget? buildSeatBadge(context, userId, roomId) {
    // Returns a purple badge showing the user's charisma points
  }

  @override
  List<PluginSettingRow> getSettingRows(context, roomId) {
    // Returns a toggle to enable/disable + a reset button
  }
}
```

Charisma manages its own state internally using a `CharismaBloc` — the Audio Room never touches it.

---

## Layer 4: The Mediator (main.dart)

**File:** `flutter/lib/main.dart` (line 49-50)

The **only place** that knows both sides:

```dart
final audioRoom = AudioRoomFeature();
audioRoom.registerPlugin(CharismaPlugin());
```

Remove this line → Charisma disappears. Audio Room keeps working with zero changes.

---

## Data Flow

```
User enters room
      │
      ▼
AudioRoomPage._enterRoom()
      │
      ▼
_notifyPluginsEnter() ──► plugin.onRoomEnter()
                                │
                                ▼
                          CharismaBloc fetches data from API
                                │
                                ▼
                          State updates → UI rebuilds via BlocBuilder
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                  ▼
        Controls Bar       Seat Badges        Room Settings
      (heart button)    (purple + points)   (toggle + reset)
```

```
RTM Message arrives (e.g. "updateCharisma")
      │
      ▼
AudioRoomPage._listenPluginMessages()
      │
      ▼
Check: plugin.rtmMessageTypes.contains(type)?
      │ Yes
      ▼
plugin.onRtmMessage(type, data)
      │
      ▼
CharismaPlugin handles it internally
      │
      ▼
BlocBuilder widgets rebuild automatically
```

---

## Adding a New Plugin

To add a new plugin (e.g. PK, Cinema), you only need to:

1. **Create a class** that `extends AudioRoomPlugin`
2. **Implement the methods** (fill the UI slots, handle RTM messages, etc.)
3. **Register it** in `main.dart`:
   ```dart
   audioRoom.registerPlugin(NewPlugin());
   ```

**Zero changes needed in the Audio Room package itself.**

---

## Key Design Principle

> The Audio Room is a **stage** with empty slots and says "any actor can perform here."
>
> The Charisma Plugin is an **actor** that knows how to perform but doesn't know the stage's internals.
>
> `main.dart` is the **organizer** that brings the actor to the stage.
>
> **The stage doesn't know who the actor is. The actor doesn't know the stage details. The organizer connects them.**
