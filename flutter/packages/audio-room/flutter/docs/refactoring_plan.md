# Audio Room Package — Refactoring Plan

خطة تنظيف وتقسيم الكود — مرتبة بالأولوية. كل خطوة مستقلة وتقدر تتنفذ لوحدها.

---

## 1. تقسيم `audio_room_page.dart` (775 سطر → ~4 ملفات)

**المشكلة:** ملف واحد فيه UI + RTM handling + plugin lifecycle + mode sheet + broadcasting.

**الخطوات:**

### 1.1 استخراج Mode Sheet
- انقل `_SeatModeSheet` + `_ModeCard` + `_SeatPreview` + `_buildModes()` لملف جديد:
  `widgets/room/seat_mode_sheet.dart`
- `audio_room_page` يعمل `import` ويستدعي `showSeatModeSheet(context, currentMode)`

### 1.2 استخراج RTM Handling لـ mixin
- أنشئ `presentation/mixins/audio_room_rtm_mixin.dart`
- انقل:
  - `_handleRoleChangeRtm()`
  - `_handleRoomSettingsUpdateRtm()`
  - `_broadcastRoomSettingsUpdate()`
  - `_listenPluginMessages()`
- الـ mixin يكون `mixin AudioRoomRtmMixin on State<AudioRoomPage>`

### 1.3 استخراج Plugin Lifecycle لـ mixin
- أنشئ `presentation/mixins/audio_room_plugin_mixin.dart`
- انقل:
  - `_notifyPluginsEnter()`
  - `_notifyPluginsExit()`
  - plugin-related fields
- الـ mixin يكون `mixin AudioRoomPluginMixin on State<AudioRoomPage>`

### 1.4 تبسيط الـ build method
- استخرج الـ error/loading state لـ widget منفصل أو method قصير
- استخرج الـ `UTDAudioRoom(...)` configuration لـ method `_buildAudioRoom()`
- الـ build method النهائي يكون < 80 سطر

**النتيجة:** `audio_room_page.dart` يقل من 775 → ~300 سطر.

---

## 2. تقسيم `room_settings_page.dart` (770 سطر → ~3 ملفات)

**المشكلة:** build method = 352 سطر، 6 setting rows متكررة، 3 dialogs inline.

**الخطوات:**

### 2.1 استخراج الـ Dialogs
- أنشئ `widgets/room/room_edit_text_sheet.dart` ← الـ `_editText()` method (69 سطر)
- أنشئ `widgets/room/room_password_dialog.dart` ← الـ `_showPasswordDialog()` method (53 سطر)
- الـ `_confirmDelete()` ممكن يفضل inline (29 سطر بس)

### 2.2 عمل Reusable Setting Row
- الـ `_SettingRow` الموجودة كويسة بس الـ trailing content متكرر
- أنشئ `_TextSettingRow` extends `_SettingRow` — بياخد title + value + onTap + canEdit
- ده هيقلل كل setting row من 30-40 سطر لـ 5-8 سطر

### 2.3 تقصير الـ build method
- بعد استخراج الـ dialogs + الـ reusable rows، الـ build هيقل تلقائي من 352 → ~120 سطر

**النتيجة:** `room_settings_page.dart` يقل من 770 → ~350 سطر.

---

## 3. ✅ تقسيم `RoomManagementBloc` (350 سطر، 4 domains → 3 BLoCs)

**المشكلة:** bloc واحد بيدير settings + admins + blacklist + visitors. الـ State فيه 16 field.

**الخطوات:**

### 3.1 استخراج `AdminBloc`
- أنشئ `bloc/admin_bloc.dart` + events + state
- انقل: `_onLoadAdmins()`, `_onAddAdmin()`, `_onRemoveAdmin()`
- State: `admins`, `adminsState`, `message`

### 3.2 استخراج `BlacklistBloc`
- أنشئ `bloc/blacklist_bloc.dart` + events + state
- انقل: `_onLoadBlacklist()`, `_onKickUser()`, `_onBanUser()`, `_onUnbanUser()`
- State: `blacklist`, `blacklistState`, `message`

### 3.3 تنظيف `RoomManagementBloc`
- يفضل فيه بس: `UpdateRoom`, `RemovePassword`, `ChangeMode`, `ToggleComments`, `DeleteRoom`
- الـ State يقل من 16 → 6 fields
- الـ Visitors ممكن يفضل هنا أو يطلع لـ `VisitorBloc` لو حبيت

### 3.4 تحديث الـ Providers
- `audio_room_page.dart` و `room_settings_page.dart` هيحتاجوا `MultiBlocProvider` بدل provider واحد
- الـ sheets (admin, blacklist, visitors) كل واحد يستخدم الـ bloc الخاص بيه

**النتيجة:** كل bloc مسؤولياته واضحة، الـ State صغير ومفهوم.

---

## 4. تقسيم `audio_room_app_overlay.dart` (817 سطر → 3 ملفات)

**المشكلة:** 5 widgets + static state + PiP dialog (124 سطر) + mini overlay (202 سطر).

**الخطوات:**

### 4.1 استخراج Mini Overlay
- انقل `_AudioRoomMiniOverlay` + `_SoundWaveBorder` + `_MicToggleButton` لـ:
  `widgets/audio_room_mini_overlay.dart`

### 4.2 استخراج PiP View
- انقل `_AudioRoomPipView` + `_ExitDialogOption` لـ:
  `widgets/audio_room_pip_view.dart`

### 4.3 تنظيف الملف الرئيسي
- `audio_room_app_overlay.dart` يفضل فيه بس الـ `AudioRoomAppOverlay` + static methods
- الـ `_openRoom()` يفضل هنا بس يستخدم DI بدل ما ينشئ Repository مباشرة

**النتيجة:** `audio_room_app_overlay.dart` يقل من 817 → ~300 سطر.

---

## 5. ✅ تنظيف `user_profile_sheet.dart` (343 سطر)

**المشكلة:** `_UserProfileBody` = 280 سطر + business logic (ban + role change) في الـ widget.

**الخطوات:**

### 5.1 استخراج Actions
- الـ `_handleBan()` (32 سطر) و `_handleRoleChange()` (44 سطر) ينتقلوا لـ callbacks يتبعتوا من بره
- أو يستخدموا الـ `AdminBloc`/`BlacklistBloc` الجديدين (بعد الخطوة 3)

### 5.2 تقسيم الـ Widget
- استخرج الـ profile header (avatar + name + role badge) لـ widget منفصل
- استخرج الـ action buttons row لـ widget منفصل
- الـ `_UserProfileBody` يقل من 280 → ~100 سطر

**النتيجة:** الـ business logic يطلع من الـ widget، كل جزء مسؤوليته واضحة.

---

## 6. ✅ عمل `BlacklistEntryModel`

**المشكلة:** الـ blacklist بتتعامل كـ `List<Map<String, dynamic>>` — مفيش type safety.

**الخطوات:**
- أنشئ `domain/blacklist_entry_model.dart`
- Fields: `userId`, `userName`, `userAvatar`, `reason`, `expiresAt`, `bannedAt`
- أضف `fromJson()` + `Equatable`
- حدّث `AudioRoomRemoteDataSource` يرجع `List<BlacklistEntryModel>`
- حدّث الـ `BlacklistBloc` و `room_blacklist_sheet.dart`

---

## 7. ✅ توحيد Pagination Logic في `RoomListBloc`

**المشكلة:** نفس الكود متكرر 4 مرات.

**الخطوات:**
- أنشئ method خاص:
```dart
void _emitRoomsResult(
  Emitter<RoomListState> emit,
  Result<BaseResponse<List<RoomModel>>> result, {
  List<RoomModel> existingRooms = const [],
  int page = 1,
}) {
  switch (result) {
    case Success(data: final data):
      final rooms = [...existingRooms, ...(data.data ?? [])];
      final paginates = data.paginates;
      emit(state.copyWith(
        rooms: rooms,
        roomsState: rooms.isEmpty ? RequestState.empty : RequestState.loaded,
        currentPage: page,
        hasMore: paginates != null
            ? paginates.currentPage < paginates.lastPage
            : false,
      ));
    case Failure(message: final message):
      if (existingRooms.isEmpty) {
        emit(state.copyWith(roomsState: RequestState.error, message: message));
      }
  }
}
```
- استخدمه في الـ 4 handlers بدل التكرار

---

## ترتيب التنفيذ المقترح

| الخطوة | الملف | التأثير | الصعوبة |
|--------|-------|---------|---------|
| **1** | `audio_room_page.dart` | عالي — أكبر ملف في الباكدج | متوسط |
| **2** | `room_settings_page.dart` | عالي — تاني أكبر ملف | سهل |
| **3** | `RoomManagementBloc` | عالي — يأثر على providers | متوسط |
| **4** | `audio_room_app_overlay.dart` | متوسط | سهل |
| **5** | `user_profile_sheet.dart` | متوسط | سهل |
| **6** | `BlacklistEntryModel` | منخفض — type safety | سهل |
| **7** | Pagination duplication | منخفض — code quality | سهل |

> كل خطوة مستقلة. ابدأ من 1 ولا من أي خطوة تحبها.
