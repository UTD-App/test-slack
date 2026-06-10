# Audio Room - Room UI Implementation Plan

## Context

نحن بنحول تطبيق Eagle من تطبيق monolithic لمنتج modular قابل للبيع بالقطعة.
المسؤولية الحالية: بناء الـ Room UI (design layer) فوق `utd_audio_room_kit`.

### القيود
- **لا نلمس** `utd_audio_room_kit` (SDK - ملك زميل)
- **لا نلمس** الـ base project (الشيل الأساسي)
- **نشتغل فقط** جوه `audio-room` package في `audio-room/flutter/`
- **لا plugins** حالياً (charisma, super bomb, PK, couples, etc.)
- **لا هدايا/محفظة** (زميل تاني مسؤول عنهم)
- **الديفولت** = 7 كراسي (1 + 3 + 3)
- **التصميم** لازم يكون مفصول وقابل للتحكم من الداشبورد مستقبلاً

---

## الموجود أصلاً في الـ audio-room package

### BLoCs
- `RoomListBloc` — عرض وبحث وفلترة الغرف
- `CreateRoomBloc` — إنشاء غرفة جديدة
- `RoomManagementBloc` — إدارة الأدمنز، الزوار، البلاك لست، الإعدادات

### صفحات (Views)
- `AudioRoomPage` — صفحة الروم الرئيسية (تستخدم `UTDAudioRoom` بدون custom builders)
- `RoomListPage` — قائمة الغرف
- `CreateRoomPage` — إنشاء غرفة
- `RoomSettingsPage` — إعدادات الغرفة

### Widgets
- `RoomCard` — كارت الغرفة في القائمة
- `RoomVisitorsSheet` — شيت الزوار
- `RoomAdminSheet` — شيت الأدمنز
- `RoomBlacklistSheet` — شيت البلاك لست
- `RoomPasswordDialog` — ديالوج كلمة السر
- `RoomBackgroundPicker` — اختيار خلفية (غير مستخدم حالياً)

### Data Layer
- `AudioRoomApiService` — مسارات الـ API
- `AudioRoomRemoteDatasource` — تنفيذ الـ repository مع Dio
- `RoomEntity` / `RoomModel` — موديلات البيانات (27 خاصية)

---

## المطلوب بناؤه

### 7 ملفات جديدة + تعديل ملف واحد

كل الملفات الجديدة في:
`presentation/widgets/room/`

---

### 1. `seat_avatar_widget.dart` — شكل الكرسي المشغول

**الوصف:** يعرض أفاتار المستخدم مع تأثير التوهج عند الكلام وأيقونة الميوت

**المكونات:**
- صورة الأفاتار من `attributes['avatar']`
- اسم المستخدم من `attributes['name']` أو `userName`
- تأثير توهج أخضر (Speaking Glow) — يستخدم `controller.activeSpeakers`
- أيقونة ميوت حمراء (bottom-right) — يستخدم `isMuted` parameter

**Builder Signature:**
```dart
Widget Function(
  String userId,
  double size,
  Map<String, String> attributes,
  bool isMuted,
  int seatIndex,
  String userName,
)
```

**يعتمد على:** `UTDRoomController.activeSpeakers` (ValueNotifier)

---

### 2. `empty_seat_widget.dart` — شكل الكرسي الفاضي

**الوصف:** دائرة شفافة مع أيقونة مايك + رقم الكرسي

**المكونات:**
- دائرة بـ `Colors.white.withOpacity(0.12)`
- أيقونة `Icons.mic_none_rounded`
- نص رقم الكرسي `(index + 1)`

**Builder Signature:**
```dart
Widget Function(int index, double size)
```

**Stateless** — لا يعتمد على أي state

---

### 3. `locked_seat_widget.dart` — شكل الكرسي المقفول

**الوصف:** دائرة شفافة مع أيقونة قفل + رقم الكرسي

**المكونات:**
- دائرة بـ `Colors.white.withOpacity(0.1)`
- أيقونة `Icons.lock_rounded`
- نص رقم الكرسي `(index + 1)`

**Builder Signature:**
```dart
Widget Function(int index, double size)
```

**Stateless** — لا يعتمد على أي state

---

### 4. `room_header_widget.dart` — هيدر الروم

**الوصف:** شريط علوي يعرض معلومات الروم والتحكم

**المكونات:**
- صورة صاحب الروم + اسم الروم + ID
- عدد الزوار (live من `controller.participantsStream`)
- قائمة أدمن (Admins / Blacklist / Settings) — للأونر والأدمن فقط
- زر خروج مع confirmation dialog

**يعتمد على:**
- `RoomModel` — بيانات الروم
- `UTDRoomController.participantsStream` — عدد الزوار المباشر
- Callbacks: `onExit`, `onVisitorsTap`, `onAdminsTap`, `onBlacklistTap`, `onSettingsTap`

---

### 5. `room_controls_bar.dart` — بار التحكم السفلي

**الوصف:** أزرار التحكم الأساسية (مايك + سبيكر + رسالة)

**المكونات:**
- زر رسالة (chat icon) — دائماً ظاهر
- زر مايك (toggle) — يظهر فقط لما المستخدم قاعد على كرسي
- زر سبيكر (toggle) — دائماً ظاهر

**يعتمد على:**
- `UTDRoomController.mediaController.isMicEnabled` (ValueNotifier)
- `UTDRoomController.mediaController.isSpeakerOn` (ValueNotifier)
- `UTDRoomController.seatController.seats` (ValueNotifier) — لمعرفة هل المستخدم قاعد ولا لا

---

### 6. `room_messages_widget.dart` — الشات

**الوصف:** قائمة رسائل + حقل إدخال

**المكونات:**
- `ListView` للرسائل — كل رسالة: اسم المرسل (أزرق) + النص (أبيض)
- حقل إدخال مع زر إرسال
- Auto-scroll لآخر رسالة

**يعتمد على:**
- `UTDRoomController.chatController.messages` (ValueNotifier<List<UTDChatMessage>>)
- `UTDRoomController.chatController.sendMessage()` — لإرسال رسالة

---

### 7. `room_background_widget.dart` — خلفية الروم

**الوصف:** صورة خلفية full-screen

**المكونات:**
- لو فيه `backgroundUrl` — يعرض الصورة من الشبكة (CachedNetworkImage)
- لو مفيش — يعرض gradient ثابت كديفولت

**يعتمد على:** `RoomModel.roomBackground` (String? URL)

---

### 8. تعديل `audio_room_page.dart` — ربط كل حاجة

**التغييرات:**
- Import الـ 7 widgets الجديدة
- تمرير custom builders في `UTDAudioRoomConfig`:
  - `avatarBuilder` → `SeatAvatarWidget`
  - `emptySeatBuilder` → `EmptySeatWidget`
  - `lockedSeatBuilder` → `LockedSeatWidget`
  - `headerWidget` → `RoomHeaderWidget`
  - `controlsBarWidget` → `RoomControlsBar`
  - `messagesWidget` → `RoomMessagesWidget`
  - `backgroundWidget` → `RoomBackgroundWidget`
- إضافة `userInRoomAttributes` (avatar URL + name من الكاش)
- إضافة mode بـ 7 كراسي كديفولت
- حفظ الـ `UTDRoomController` من `onControllerReady`

---

## هيكل الملفات النهائي

```
audio-room/flutter/lib/src/presentation/
├── bloc/                               (موجود - بدون تعديل)
│   ├── room_list_bloc.dart
│   ├── create_room_bloc.dart
│   └── room_management_bloc.dart
├── view/
│   ├── audio_room_page.dart            ← تعديل (ربط الـ builders)
│   ├── room_list_page.dart             (موجود - بدون تعديل)
│   ├── create_room_page.dart           (موجود - بدون تعديل)
│   └── room_settings_page.dart         (موجود - بدون تعديل)
└── widgets/
    ├── room/                           ← مجلد جديد
    │   ├── seat_avatar_widget.dart     ← جديد
    │   ├── empty_seat_widget.dart      ← جديد
    │   ├── locked_seat_widget.dart     ← جديد
    │   ├── room_header_widget.dart     ← جديد
    │   ├── room_controls_bar.dart      ← جديد
    │   ├── room_messages_widget.dart   ← جديد
    │   └── room_background_widget.dart ← جديد
    ├── room_card.dart                  (موجود - بدون تعديل)
    ├── room_visitors_sheet.dart        (موجود - بدون تعديل)
    ├── room_admin_sheet.dart           (موجود - بدون تعديل)
    ├── room_blacklist_sheet.dart       (موجود - بدون تعديل)
    ├── room_password_dialog.dart       (موجود - بدون تعديل)
    └── room_background_picker.dart     (موجود - بدون تعديل)
```

---

## ترتيب التنفيذ

| الترتيب | الملف | الصعوبة | الوقت المتوقع |
|---------|-------|---------|--------------|
| 1 | `locked_seat_widget.dart` | سهل | 5 دقائق |
| 2 | `empty_seat_widget.dart` | سهل | 5 دقائق |
| 3 | `room_background_widget.dart` | سهل | 10 دقائق |
| 4 | `seat_avatar_widget.dart` | متوسط | 20 دقيقة |
| 5 | `room_controls_bar.dart` | متوسط | 15 دقيقة |
| 6 | `room_messages_widget.dart` | متوسط | 20 دقيقة |
| 7 | `room_header_widget.dart` | متوسط | 20 دقيقة |
| 8 | `audio_room_page.dart` (تعديل) | سهل | 15 دقيقة |

---

## حالة الباك اند

الباك اند **كافي** للسكوب الحالي:
- ✅ Room CRUD, enter/exit, visitors, admins, blacklist — كله شغال
- ⚠️ Stubs: ranking (فاضي), mute/unmute writing, banner — يتكمل لما الـ UI يحتاجه
- ❌ مش في السكوب: gifts, charisma, PK, backgrounds, music

---

## التحقق (Verification)

بعد التنفيذ:
1. تشغيل الأبلكيشن
2. إنشاء غرفة من صفحة القائمة
3. دخول الغرفة — التأكد إن الـ UI المخصص ظاهر (مش الديفولت بتاع الـ kit)
4. التأكد: الخلفية ظاهرة، الهيدر يعرض معلومات الروم، الكراسي شكلها صح
5. التأكد: المايك والسبيكر بيشتغلوا، الرسائل بتتبعت وبتتستقبل
6. التأكد: الكراسي الفاضية والمقفولة شكلهم صح
7. التأكد: التوهج الأخضر بيظهر لما حد بيتكلم
8. التأكد: زر الخروج بيشتغل مع confirmation dialog
9. التأكد: شيتات الإعدادات والأدمنز لسه شغالة من الهيدر

---

## ملاحظات للمستقبل

- **زميل الـ SDK**: لما يخلص الداشبورد، هيضيف config layer فوق الـ widgets دي. كل widget مفصول في ملف لوحده فسهل يستبدل أي واحد
- **الـ Plugins**: كل mode إضافي (seat2, couples, cinema) هيبقى `AudioRoomModePlugin` مستقل
- **الهدايا**: زميل تاني هيبنيها كـ package مستقل ويحقنها في الـ foregroundWidget أو الـ controlsBar
