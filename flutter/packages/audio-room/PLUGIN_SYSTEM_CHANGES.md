# Plugin System - التعديلات اللي اتعملت

## الهدف
تحويل الروم من hardcoded features لـ plugin-based architecture.
الروم مبقاش يعرف عن الكاريزما أو أي plugin — بيعمل loop على اللي مسجلين بس.

---

## الملفات اللي اتعدلت

### 1. `audio_room_plugin.dart` — توسيع الـ Contract

**المكان:** `flutter/packages/audio-room/flutter/lib/src/audio_room_plugin.dart`

**اللي كان موجود:**
- `buildControlsWidget()` — زرار في الـ controls bar
- `buildOverlayWidget()` — widget فوق الروم

**اللي اتضاف:**
- `buildSeatBadge(context, userId, roomId)` — badge تحت كل كرسي
- `getSettingRows(context, roomId)` — صفوف في الـ settings
- `rtmMessageTypes` — أنواع رسائل RTM اللي البلاجن عايز يسمعها
- `onRtmMessage(type, data)` — handler لما رسالة RTM توصل
- `conflictsWith` — بلاجنز متشتغلش مع بعض
- `onRoomEnter(roomId, userId)` — لما يوزر يدخل الروم
- `onRoomExit(roomId, userId)` — لما يوزر يخرج

كل الـ hooks ليها default implementation (ترجع null أو list فاضية) — يعني البلاجنز القديمة مش هتتكسر.

---

### 2. `plugin_setting_row.dart` — ملف جديد

**المكان:** `flutter/packages/audio-room/flutter/lib/src/plugin_setting_row.dart`

Model بسيط بيوصف row في الـ settings:
- `PluginSettingType.toggle` — switch بيفتح/يقفل
- `PluginSettingType.action` — زرار بيعمل حاجة
- `title` — اسم الإعداد
- `currentValue` — القيمة الحالية (للـ toggle)
- `onToggle` / `onTap` — callbacks
- `isLoading` — حالة تحميل

---

### 3. `audio_room_feature.dart` — Static Access

**المكان:** `flutter/packages/audio-room/flutter/lib/src/audio_room_feature.dart`

**اللي اتضاف:**
- `static AudioRoomFeature? _instance` — يتحفظ لما الـ feature يتعمل
- `static List<AudioRoomPlugin> get registeredPlugins` — أي حتة في الكود تقدر توصل للبلاجنز المسجلة من غير Provider

---

### 4. `audio_room.dart` — Export

**المكان:** `flutter/packages/audio-room/flutter/lib/audio_room.dart`

اتضاف export لـ `plugin_setting_row.dart` عشان البلاجنز الخارجية تقدر تستخدمه.

---

### 5. `room_settings_page.dart` — Plugin Settings Section

**المكان:** `flutter/packages/audio-room/flutter/lib/src/presentation/view/room_settings_page.dart`

**اللي اتضاف:**
- `_pluginSettingRows` getter — يجمع كل الـ rows من كل البلاجنز المسجلة
- `_buildPluginRow(row)` — يرسم الـ row حسب النوع (toggle أو action)
- Section جديد في الـ body بين القوانين وكلمة المرور — يعمل loop ويعرض plugin rows
- `setState` بيتنادى بعد كل callback عشان الصفحة تتحدث

**الترتيب في الصفحة:**
```
صورة الغرفة
رقم الغرفة
اسم الغرفة
إعلان الغرفة
قوانين الغرفة
─── strip ───
[Plugin Settings]  ← الجزء الجديد
─── strip ───
كلمة المرور
إغلاق التعليقات
مايك حر
─── strip ───
حذف الغرفة
```

---

### 6. `seat_avatar_widget.dart` — Plugin Badges

**المكان:** `flutter/packages/audio-room/flutter/lib/src/presentation/widgets/room/seat_avatar_widget.dart`

**اللي اتضاف:**
- `roomId` parameter جديد
- Loop على `AudioRoomFeature.registeredPlugins` — كل plugin يرجع badge (أو null) — الـ badges بتتعرض بين الـ avatar والاسم

---

### 7. `audio_room_page.dart` — Lifecycle Hooks

**المكان:** `flutter/packages/audio-room/flutter/lib/src/presentation/view/audio_room_page.dart`

**اللي اتضاف:**
- `_notifyPluginsEnter(room)` — بينادي `onRoomEnter` لكل plugin لما اليوزر يدخل الروم
- `_notifyPluginsExit()` — بينادي `onRoomExit` لكل plugin لما اليوزر يخرج
- `roomId: room.id` بيتمرر لـ `SeatAvatarWidget`

---

### 8. `charisma_plugin.dart` — أول Plugin شغال

**المكان:** `flutter/packages/audio-room/plugins/charisma/flutter/lib/src/charisma_plugin.dart`

**كان:**
```dart
class CharismaPlugin extends AudioRoomPlugin {
  Widget? buildControlsWidget(...) => null;
  Widget? buildOverlayWidget(...)  => null;
}
```

**بقى:**
- `buildSeatBadge()` — badge بنفسجي تحت الكرسي فيها أيقونة قلب + النقاط
- `getSettingRows()` — toggle "الكاريزما" + action "ريست الكاريزما"
- `rtmMessageTypes` — بيسمع `updateCharisma`, `startCharisma`, `closeCharisma`
- `onRtmMessage()` — بيحدث الـ bloc حسب نوع الرسالة
- `onRoomEnter()` — بيحمل بيانات الكاريزما للروم
- `onRoomExit()` — بيعمل reset للـ state
- `conflictsWith` — `['pk', 'cinema']`
- الـ CharismaBloc بيتعمل في الـ constructor ومستنيين يسمعوا

---

## اللي مش متضمن (مراحل جاية)

| الحاجة | ليه |
|---|---|
| متجر البلاجنز (شراء/تفعيل) | محتاج API + UI منفصلين |
| RTM forwarding من الـ kit | محتاج سامح يضيف generic message stream في UTD Stream |
| ربط الهدايا بالكاريزما | الـ gifts plugin لسه متبنتش |
| باقي البلاجنز (emoji, pk) | تملا الـ hooks زي الكاريزما — كل واحد لوحده |
| Initial charisma status | محتاج endpoint يرجع الـ status من غير ما يغيره |

---

## ازاي تضيف plugin جديد

1. اعمل folder في `plugins/`
2. اعمل class يعمل `extends AudioRoomPlugin`
3. املا الـ hooks اللي محتاجها (الباقي يفضل default)
4. في `main.dart`: `audioRoom.registerPlugin(YourPlugin())`
5. خلاص — مش محتاج تفتح كود الروم
