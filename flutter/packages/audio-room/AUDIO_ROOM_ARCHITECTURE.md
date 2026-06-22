# Audio Room — Plugin System Architecture

## Overview

Audio Room is a feature package that wraps `utd_audio_room_kit` (pub package v1.0.1) and extends it with a **plugin system** allowing features like Charisma, PK, Emoji, etc. to be added modularly without modifying the core room code.

---

## Layer Separation

```
┌──────────────────────────────────────────────┐
│  utd_audio_room_kit (pub package)            │
│  - LiveKit connection & data channels        │
│  - UTDRoomController (seats, chat, media)    │
│  - Role management (admin/host via engine)   │
│  - Seat grid, member list, ban management    │
│  - Sends/receives _role_change, _seat_update │
│    _banned, _speaker_invitation, etc.        │
│  - Does NOT show chat messages for events    │
│  - Does NOT show toasts/notifications        │
└──────────────┬───────────────────────────────┘
               │ depends on
┌──────────────▼───────────────────────────────┐
│  audio_room (feature package)                │
│  - AudioRoomPage (main room UI)              │
│  - Custom widgets (header, avatar, controls) │
│  - Room settings page                        │
│  - Plugin system (registration + lifecycle)  │
│  - RTM message routing to plugins            │
│  - Role change handling (chat + toast + UI)  │
└──────────────┬───────────────────────────────┘
               │ registers
┌──────────────▼───────────────────────────────┐
│  Plugins (charisma, emoji, pk, etc.)         │
│  - Each plugin extends AudioRoomPlugin       │
│  - Independent BLoC / state management       │
│  - Own API service & repository              │
│  - Builds UI widgets (controls, badges, etc.)│
└──────────────────────────────────────────────┘
```

---

## Plugin Base Class

**File:** `audio_room/flutter/lib/src/audio_room_plugin.dart`

```dart
abstract class AudioRoomPlugin {
  // ── Identity ──
  String get id;                          // unique: 'charisma', 'pk', etc.
  String get displayName;                 // user-facing name
  List<String> get conflictsWith;         // plugin IDs that can't run together

  // ── UI Hooks ──
  Widget? buildControlsWidget(context, roomId);   // icon in controls bar
  Widget? buildOverlayWidget(context, roomId);     // overlay on room
  Widget? buildSeatBadge(context, userId, roomId); // badge below avatar
  List<PluginSettingRow> getSettingRows(context, roomId); // settings page rows

  // ── Lifecycle ──
  void onControllerReady(UTDRoomController controller);  // controller available
  void onRoomEnter(int roomId, String userId);            // user entered room
  void onRoomExit(int roomId, String userId);             // user left room

  // ── RTM (Real-Time Messaging) ──
  List<String> get rtmMessageTypes;                            // message types to listen for
  void onRtmMessage(String type, Map<String, dynamic> data);  // handle incoming RTM
}
```

All hooks have default no-op implementations — plugins only override what they need.

---

## Plugin Registration

**File:** `audio_room/flutter/lib/src/audio_room_feature.dart`

```dart
class AudioRoomFeature extends AppFeature {
  static List<AudioRoomPlugin> get registeredPlugins => _instance?._plugins ?? [];

  void registerPlugin(AudioRoomPlugin plugin) {
    _plugins.add(plugin);
  }
}
```

**Registration in main.dart:**
```dart
final audioRoom = AudioRoomFeature();
audioRoom.registerPlugin(CharismaPlugin());
// audioRoom.registerPlugin(PkPlugin());
// audioRoom.registerPlugin(EmojiPlugin());
```

Plugins are registered at app startup before the widget tree builds.

---

## How audio_room_page.dart Wires Everything

### 1. Room Enter → notify plugins

```dart
void _notifyPluginsEnter(RoomModel room) {
  final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
  for (final plugin in AudioRoomFeature.registeredPlugins) {
    plugin.onRoomEnter(room.id, userId);
  }
}
```

### 2. Controller Ready → give plugins the controller + start RTM routing

```dart
onControllerReady: (controller) {
  _listenPluginMessages(controller);        // RTM routing
  for (final plugin in AudioRoomFeature.registeredPlugins) {
    plugin.onControllerReady(controller);   // each plugin gets the controller
  }
  setState(() => _controller = controller);
}
```

### 3. RTM Message Routing → filter by type, forward to matching plugins

```dart
void _listenPluginMessages(UTDRoomController controller) {
  _dataSub = controller.dataStream.listen((data) {
    final type = data['type'] as String?;
    if (type == null) return;

    // Handle system messages (roleChange, etc.) first
    if (type == 'roleChange') {
      _handleRoleChangeRtm(data['data'] ?? data);
      return;
    }

    // Forward to plugins
    for (final plugin in AudioRoomFeature.registeredPlugins) {
      if (plugin.rtmMessageTypes.contains(type)) {
        plugin.onRtmMessage(type, data['data'] ?? data);
      }
    }
  });
}
```

### 4. Controls Bar → collect widgets from plugins

```dart
controlsBarWidget: Row(
  children: [
    ...AudioRoomFeature.registeredPlugins
        .map((p) => p.buildControlsWidget(context, room.id))
        .where((w) => w != null)
        .cast<Widget>(),
    Expanded(child: RoomControlsBar(controller: _controller!)),
  ],
)
```

### 5. Room Exit → cleanup plugins

```dart
void _notifyPluginsExit() {
  final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
  for (final plugin in AudioRoomFeature.registeredPlugins) {
    plugin.onRoomExit(_room!.id, userId);
  }
}
```

---

## How seat_avatar_widget.dart Shows Plugin Badges

```dart
Stack(
  children: [
    _SpeakingWave(...),
    _Avatar(...),

    // Plugin badges (e.g. charisma points)
    ...AudioRoomFeature.registeredPlugins
        .map((p) => p.buildSeatBadge(context, userId, roomId))
        .where((w) => w != null)
        .cast<Widget>(),

    if (effectivelyMuted)
      Positioned(bottom: 0, right: 0, child: _MicMutedIcon(...)),
  ],
)
```

---

## How room_settings_page.dart Shows Plugin Settings

```dart
// Collect all plugin setting rows
List<PluginSettingRow> get _pluginSettingRows {
  final rows = <PluginSettingRow>[];
  for (final plugin in AudioRoomFeature.registeredPlugins) {
    rows.addAll(plugin.getSettingRows(context, widget.room.id));
  }
  return rows;
}

// Render in the settings page (only for admins/owner)
if (_canEdit && _pluginSettingRows.isNotEmpty) ...[
  for (final row in _pluginSettingRows)
    _buildPluginRow(row),  // renders Toggle or Action based on row.type
]
```

**PluginSettingRow model:**
```dart
enum PluginSettingType { toggle, action }

class PluginSettingRow {
  final String title;
  final PluginSettingType type;
  final bool? currentValue;           // for toggle
  final ValueChanged<bool>? onToggle; // for toggle
  final VoidCallback? onTap;          // for action
  final bool isLoading;
}
```

---

## RTM (Real-Time Messaging) Flow

RTM uses LiveKit data channels through `utd_audio_room_kit`:

```
Sender                              Receiver
──────                              ────────
controller.sendRoomMessage({        controller.dataStream
  'type': 'startCharisma',    →       .listen((data) {
  'data': {'room_id': 5}               type = data['type']
})                                      plugin.onRtmMessage(type, data['data'])
                                      })
```

**Important:** `sendRoomMessage` sends to ALL OTHER participants (not back to sender).
The message is JSON-encoded, sent via LiveKit `publishData`, received via `DataReceivedEvent`.

### Kit-sent vs App-sent messages

| Source     | Message Type        | Sent By              | Arrives On           |
|------------|--------------------|-----------------------|----------------------|
| **Kit**    | `_role_change`     | UTD Stream server     | `roleChangeStream`   |
| **Kit**    | `_seat_update`     | UTD Stream server     | handled internally   |
| **Kit**    | `_banned`          | UTD Stream server     | `onBanned` callback  |
| **Kit**    | `_speaker_invitation` | UTD Stream server  | `onInvitationUI`     |
| **App**    | `startCharisma`    | `sendRoomMessage`     | `dataStream` → plugin |
| **App**    | `closeCharisma`    | `sendRoomMessage`     | `dataStream` → plugin |
| **App**    | `updateCharisma`   | `sendRoomMessage`     | `dataStream` → plugin |

Kit messages (prefixed with `_`) are handled internally by the kit.
App messages go through `dataStream` and are routed to plugins.

---

## Charisma Plugin — Full Example

**Files:**
```
plugins/charisma/
├── flutter/lib/src/
│   ├── charisma_plugin.dart          ← main plugin class
│   ├── domain/
│   │   ├── charisma_model.dart
│   │   └── charisma_repository.dart
│   ├── data/
│   │   ├── charisma_api_service.dart
│   │   └── charisma_remote_datasource.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── charisma_bloc.dart
│       │   └── charisma_event.dart
│       └── view/
│           └── charisma_leaderboard_sheet.dart
└── backend/                          ← Laravel API
```

### Plugin Lifecycle

```
App starts
  → CharismaPlugin() constructor
  → _bloc = CharismaBloc(...)
  → _bloc.add(FetchCharismaLevelsEvent())     // cache levels

User enters room
  → onRoomEnter(roomId, userId)
  → _bloc.add(LoadRoomCharismaEvent(roomId))  // fetch status + data from API

Controller ready
  → onControllerReady(controller)
  → _controller = controller                  // store for RTM sending

RTM received (from another user)
  → onRtmMessage('startCharisma', data)
  → _bloc.add(LoadRoomCharismaEvent(roomId, activeOverride: true))

  → onRtmMessage('updateCharisma', data)
  → _bloc.add(UpdateCharismaEvent(data))      // update scores locally

  → onRtmMessage('closeCharisma', data)
  → _bloc.add(InitCharismaEvent())            // reset state

User exits room
  → onRoomExit(roomId, userId)
  → _controller = null
  → _bloc.add(InitCharismaEvent())
```

### UI Integration Points

**Controls bar** — heart icon (visible only when charisma is active):
```dart
Widget? buildControlsWidget(context, roomId) {
  return BlocBuilder<CharismaBloc, CharismaState>(
    bloc: _bloc,
    buildWhen: (prev, curr) => prev.charismaActive != curr.charismaActive,
    builder: (context, state) {
      if (!state.charismaActive) return SizedBox.shrink();
      return IconButton(
        icon: Icon(Icons.favorite, color: Colors.pinkAccent),
        onPressed: () => CharismaLeaderboardSheet.show(context, _bloc, _controller),
      );
    },
  );
}
```

**Seat badge** — points display under each avatar:
```dart
Widget? buildSeatBadge(context, userId, roomId) {
  return BlocBuilder<CharismaBloc, CharismaState>(
    bloc: _bloc,
    builder: (context, state) {
      if (!state.charismaActive) return SizedBox.shrink();
      final total = state.data?.firstWhere(...)?.total ?? '0';
      return Positioned(bottom: 0, child: /* purple badge with heart + total */);
    },
  );
}
```

**Settings rows** — toggle + reset action:
```dart
List<PluginSettingRow> getSettingRows(context, roomId) {
  return [
    PluginSettingRow(
      title: 'الكاريزما',
      type: PluginSettingType.toggle,
      currentValue: _isActive,
      onToggle: (value) {
        _bloc.add(ChangeCharismaStatusEvent(roomId: roomId, status: value));
        _controller?.sendRoomMessage({
          'type': value ? 'startCharisma' : 'closeCharisma',
          'data': {'room_id': roomId},
        });
      },
    ),
    if (_isActive)
      PluginSettingRow(
        title: 'ريست الكاريزما',
        type: PluginSettingType.action,
        onTap: () {
          _bloc.add(ResetCharismaEvent(roomId: roomId));
          _controller?.sendRoomMessage({
            'type': 'updateCharisma',
            'data': {'charisma': /* zeroed data */},
          });
        },
      ),
  ];
}
```

---

## Role Change (Admin Promotion)

### What the kit does automatically:

1. `controller.changeRole(targetIdentity, role: 'admin')` → API call to UTD Stream
2. UTD Stream server updates LiveKit permissions
3. Server broadcasts `_role_change` to everyone
4. Kit updates `_roleCache` → `isHostOrAdmin` becomes true for the target
5. Kit fires `roleChangeStream` and `onRoleChanged` callback
6. Target user can now mute/kick/lock seats immediately

### What the kit does NOT do:

- Show a chat message ("X became admin")
- Show a toast to the promoted user
- Update `room.isAdmin` (this is our model, not the kit's)

### What we handle in audio_room:

1. **Send backend API call** — `AddAdminEvent` / `RemoveAdminEvent` to sync our database
2. **Listen to `roleChangeStream`** — update `_room.isAdmin` so header menu / settings appear
3. **Show chat message** — `controller.chatController.addDisplayMessage(...)`
4. **Show toast** — `SnackBar` to the promoted/demoted user

---

## Creating a New Plugin

1. Create a class extending `AudioRoomPlugin`
2. Set `id`, `displayName`, and optionally `conflictsWith`
3. Override the hooks you need
4. Register in `main.dart`: `audioRoom.registerPlugin(MyPlugin())`

Minimal plugin:
```dart
class MyPlugin extends AudioRoomPlugin {
  @override
  String get id => 'my_plugin';

  @override
  String get displayName => 'My Plugin';

  @override
  Widget? buildControlsWidget(context, roomId) => null;

  @override
  Widget? buildOverlayWidget(context, roomId) => null;
}
```
