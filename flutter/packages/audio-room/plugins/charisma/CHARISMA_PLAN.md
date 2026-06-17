# Plan: تطبيق نمط Eagle للكاريزما

## الحالة الحالية vs Eagle

| الجانب | عندنا حاليًا | Eagle |
|---|---|---|
| **مصدر الحالة** | `_isActive` field + Bloc stream listener | `ValueNotifier<bool>` (`isCharismaVisible`) |
| **تحميل الحالة عند الدخول** | API call منفصل (`getStatus`) | `charisma_status` من enter room response مباشرة |
| **الـ Badge الافتراضي** | `Container` عادي بـ `BoxDecoration` | `CustomPaint` + `ArcContainerPainter` (شكل مقوّس) |
| **الـ Badge المتقدم** | مفيش | Level image badge (صورة من API) |
| **شكل الـ Badge** | مسطح عادي | وضعين: Heart مع Arc / Level Image |
| **الـ Settings toggle** | `_isActive` field (مشكلة stream timing) | `isCharismaVisible.value` مباشرة (ثابت) |
| **RTM handler** | Plugin `onRtmMessage` → Bloc event | يضبط `isCharismaVisible.value` + `RoomOverlayCubit` مباشرة |
| **Seat widget** | `BlocBuilder` فقط | `ValueListenableBuilder<bool>` ← `BlocSelector` (طبقتين) |

---

## التغييرات المطلوبة

### 1. إضافة `charisma_status` لـ enter room response — Backend

**ملف:** `backend/packages/audio-room/src/Http/Controllers/RoomController.php`

- ترجيع `charisma_status` في `formatRoom` تاني — بس المرة دي كـ plugin hook مش hardcoded
- أو: الـ plugin يقرأها من الـ room data اللي بترجع من enter room

**ملف:** `backend/packages/audio-room/src/Http/Controllers/CharismaController.php`
- مفيش تغيير — الـ SET API شغال

> **الفكرة:** بدل ما نرجّع `charisma_status` من `formatRoom` مباشرة (اللي اترفضت)، ممكن نعمل hook في الـ plugin system بحيث كل plugin يقدر يضيف data على enter room response. أو — والأبسط — الـ charisma plugin يفضل يعمل API call منفصل زي ما هو دلوقتي بس نتأكد إنه سريع.

---

### 2. شكل الـ Badge — Flutter/CharismaPlugin

**ملف:** `plugins/charisma/flutter/lib/src/charisma_plugin.dart` → `buildSeatBadge`

التغيير:
- **وضعين للـ badge:**
  - **Level Image Badge** (لو `CharismaBloc.getLevelImage(points)` رجّع صورة):
    - `Positioned(bottom: -imageSize * 0.15, left: 0, right: 0)`
    - صورة الليفل + الرقم فوقيها
    - عرض: `imageSize * 1.1`
  - **Default Heart Badge** (لو مفيش level image):
    - `Positioned(bottom: imageSize * 0.05, left: 0, right: 0)`
    - `CustomPaint` + `ArcContainerPainter` (شكل مقوّس)
    - Heart icon + الرقم
    - عرض: `imageSize * 0.9`

**ملف جديد:** `plugins/charisma/flutter/lib/src/presentation/view/arc_container_painter.dart`

- نسخ `ArcContainerPainter` من Eagle — 37 سطر فقط
- `CustomPainter` بيرسم path مقوّس (arc) من فوق + corners مدوّرين من تحت

**مشكلة:** دالة `buildSeatBadge` حاليًا مبتاخدش `imageSize` — محتاجين نضيفها للـ plugin interface أو نستخدم `LayoutBuilder`.

---

### 3. تحسين `buildSeatBadge` signature — Plugin Interface

**ملف:** `flutter/packages/audio-room/flutter/lib/src/audio_room_plugin.dart`

```dart
// قبل
Widget? buildSeatBadge(BuildContext context, String userId, int roomId);

// بعد
Widget? buildSeatBadge(BuildContext context, String userId, int roomId, {required double avatarSize});
```

**ملف:** `flutter/packages/audio-room/flutter/lib/src/presentation/widgets/room/seat_avatar_widget.dart`
- يمرّر `avatarSize` لـ `buildSeatBadge`

---

### 4. الـ Badge يستخدم `BlocSelector` بدل `BlocBuilder` — أداء أفضل

**ملف:** `plugins/charisma/flutter/lib/src/charisma_plugin.dart`

حاليًا بنعمل `BlocBuilder` بيعمل rebuild على أي تغيير في `data` أو `charismaActive`. Eagle بيستخدم `BlocSelector` بيسحب بس `(total, levelImage)` للـ user المحدد — rebuild أقل.

```dart
BlocSelector<CharismaBloc, CharismaState, ({String total, String? levelImage})>(
  bloc: _bloc,
  selector: (state) {
    final userData = state.data?.firstWhere(...);
    final total = userData?.total ?? "0";
    final levelImage = CharismaBloc.getLevelImage(int.tryParse(total) ?? 0);
    return (total: total, levelImage: levelImage);
  },
  builder: (context, data) { ... },
)
```

---

### 5. إزالة مشكلة الـ stream listener — اختياري

حاليًا بنستخدم `_isActive` + `_bloc.stream.listen` مع فلترة `RequestState.loading`. ده شغّال بس fragile.

**بديل (نمط Eagle):** نخلّي الـ Bloc هو المصدر الوحيد — بدل `_isActive` نقرأ `_bloc.state.charismaActive` في `getSettingRows`. كده مفيش timing issues.

```dart
// بدل
currentValue: _isActive,

// نعمل
currentValue: _bloc.state.charismaActive,
```

وفي `onRtmMessage`:
```dart
case 'startCharisma':
  // بدل _isActive = true
  _bloc.add(LoadRoomCharismaEvent(roomId: roomId));
```

ده أبسط ومفيش حاجة ممكن تتلخبط.

---

## ملخص الملفات

| ملف | التعديل |
|---|---|
| `audio_room_plugin.dart` | إضافة `avatarSize` لـ `buildSeatBadge` |
| `seat_avatar_widget.dart` | تمرير `avatarSize` للـ plugin |
| `charisma_plugin.dart` → `buildSeatBadge` | وضعين (level image / heart+arc)، `BlocSelector` |
| **جديد:** `arc_container_painter.dart` | `CustomPainter` للشكل المقوّس |
| `charisma_plugin.dart` → `getSettingRows` | `_bloc.state.charismaActive` بدل `_isActive` |
| `charisma_bloc.dart` | حذف الـ `print` statements |

---

## اللي مش هنغيّره

- **الـ API call المنفصل لـ getStatus** — يفضل زي ما هو (بدل ما نرجّع `charisma_status` في `formatRoom`). الـ plugin يحمّل حالته بنفسه.
- **SET API** — شغال تمام
- **RTM handling** — الـ pattern الحالي كافي بس نشيل `_isActive` ونعتمد على الـ Bloc
- **Levels API** — موجود وشغال (`FetchCharismaLevelsEvent` + `getLevelImage`)

---

## الترتيب المقترح للتنفيذ

1. إضافة `arc_container_painter.dart` (ملف جديد صغير)
2. تعديل `audio_room_plugin.dart` — إضافة `avatarSize`
3. تعديل `seat_avatar_widget.dart` — تمرير `avatarSize`
4. تعديل `buildSeatBadge` في `charisma_plugin.dart` — الشكل الجديد بالوضعين
5. تعديل `getSettingRows` — شيل `_isActive`، استخدم `_bloc.state.charismaActive`
6. حذف `print` statements من `charisma_bloc.dart`
7. اختبار
