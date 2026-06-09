# خطة: State Management والفصل بين UI Stack و Package — UTD Stack

> النسخة: 2026-06-02 · المرجع: `utdStack/docs/integration/index.html` + الكود الحالي في
> `utd-base-project/flutter/lib/shared/stac/**` و `chat package/flutter/lib/**`.

---

## 0) الخلاصة والتوصية (TL;DR)

| السؤال | الإجابة المختصرة |
|---|---|
| هل الـ Package تدعم State Management حاليًا في الـ Stac؟ | **لأ.** المحرّك (BLoC) موجود جوّه الـ chat package، لكن جسر الـ Stac يتجاهله ويستخدم `Future<List>` لمرة واحدة (بدون refresh / pagination / realtime / cache للبيانات). |
| هل فيه Elements متطورة (Template/Component للـ State و Scroll/Refresh)؟ | **لسه لأ.** `utdList` الحالي = `FutureBuilder` ساكن. لازم نرقّيه. |
| مين يعمل الـ State Management — الـ Stack ولا الـ Package؟ | **الاتنين بدور مختلف:** الـ **Package** يملك الـ State + Cache + Realtime + المنطق (Headless Engine). الـ **Stack/JSON** يرسم بس + يفعّل سلوكيات (refresh/paginate). الـ **Base App** يعمل الـ wiring (DI / token / theme / routing). |
| الأفضل؟ | منطق الحالة والكاش والـ scroll/refresh **في الـ Stack engine + الـ Package** — مش في الـ JSON. الـ JSON يفضل declarative بحت. |

**المبدأ الحاكم:** `Headless Package (المخ) + Skin Stack (الجلد)`.
الـ Package بيقدّم **بيانات تفاعلية (stream) + أفعال (actions)**، والـ Stack بيقدّم **شكل** يستهلكها.

---

## 1) الوضع الحالي بدقّة (ما هو موجود فعلاً)

| الطبقة | الحالة | موجود؟ | الناقص |
|---|---|---|---|
| `StacService` | كاش الـ **شاشة (JSON)** في Hive بالنسخة | ✅ | كاش **البيانات** نفسها (مش بس الـ layout) |
| `StacDataRegistry` | `registerList(key, () => Future<List>)` | ✅ one-shot | تفاعلية (stream)، pagination، refresh، actions |
| `utdList` parser | `FutureBuilder` → يرسم `itemTemplate` | ✅ | RefreshIndicator، infinite scroll، state slots (loading/empty/error)، realtime |
| `StacBinding` | يحل `binding` (text/image) | ✅ | كفاية مبدئيًا — يُوسّع لأنواع أكتر |
| chat package | `ChatRoomsBloc` + `MessagesBloc` + repo + models (pagination/reacts/replay) | ✅ **المحرّك موجود!** | مربوط بالـ Stac كـ one-shot بيتجاوز الـ BLoC تمامًا |
| `chat_stac_sources.dart` | يسجّل `chat.conversations` فقط (Future) | ⚠️ | `chat.conversation.messages`، الأفعال (send/react)، الربط التفاعلي بالـ BLoC |
| Realtime | backend فيه `pusher/pusher-php-server` | ✅ backend | لا يوجد عميل realtime في Flutter (محتاج `pusher_channels_flutter` / `laravel_echo`) |

**أهم نقطة:** الـ chat package فيها الـ state engine الجاهز (BLoC + ConversationModel فيه `currentPage/lastPage`)، لكن `chat_stac_sources.dart` بينده الـ repository مباشرة ويرجّع List ثابتة → كل احترافية الـ BLoC ضايعة عند الرسم.

---

## 2) المبدأ المعماري: Headless Package + Skin Stack

ثلاث مسؤوليات منفصلة بالكامل:

```
┌──────────────────────────────────────────────────────────────┐
│ UTD Studio  →  Stac JSON (الشكل + تفعيل سلوكيات + bindings)   │  ← العميل يتحكم
├──────────────────────────────────────────────────────────────┤
│ Base App (Host): DI · token · theme · routing · register pkgs │  ← wiring
├──────────────────────────────────────────────────────────────┤
│ Stac Engine (generic): utdList/utdAction · state slots ·       │  ← الـ stack (مرّة واحدة لكل الـ packages)
│ refresh · pagination · binding · StreamBuilder                 │
├──────────────────────────────────────────────────────────────┤
│ Package (Headless Engine): BLoC/Controller · cache · realtime ·│  ← "الاحترافية" تيجي من هنا
│ pagination · optimistic · data schema · actions               │
└──────────────────────────────────────────────────────────────┘
```

- **الـ JSON لا يحتوي منطق.** هو سيّئ في التعبير عن state machine / websocket lifecycle / retry / optimistic.
- **الـ Package لا يفرض شكلًا.** يقدّم بيانات وأفعال فقط؛ الشكل من الـ JSON.
- **الـ Stack Engine هو الوسيط** اللي بيترجم سلوكيات الـ JSON (refresh/paginate) إلى نداءات على الـ Controller بتاع الـ Package.

---

## 3) القرار: مين يعمل كل حاجة؟ (decision table)

| المسؤولية | المكان الصحيح | ليه |
|---|---|---|
| رسم الـ UI / الترتيب / الألوان | **Stack (JSON)** | ده غرضه الوحيد، وقابل للتعديل من العميل بدون نشر |
| تفعيل/تعطيل سلوك (refresh, paginate, realtime on) | **Stack (JSON)** كـ flags | declarative، العميل يقرر |
| منطق الـ State (loading/loaded/error) | **Package (Controller/BLoC)** | معقّد، يتكرّر، لازم reusable + testable |
| Caching للبيانات (offline / فتح فوري) | **Package** (عبر طبقة cache موحّدة) | domain-specific، عشان كل client ياخده مجانًا |
| Pagination (cursor/page) | **Package** | المنطق عند صاحب الـ API |
| تنفيذ الـ Scroll/Refresh/InfiniteScroll | **Stack Engine** (generic widget) مدفوع بأوامر من الـ Package | السلوك واحد لكل القوائم؛ نكتبه مرة |
| Realtime (websocket lifecycle, typing, receipts) | **Package** | يغذّي الـ Controller stream |
| Optimistic send / retry | **Package** | جزء من منطق الدومين |
| الـ wiring (token, DI, تسجيل الـ packages) | **Base App (Host)** | هو اللي يعرف كل الـ packages |

> **القاعدة:** أي حاجة فيها "ذكاء" → Package. أي حاجة فيها "شكل" → Stack. أي حاجة فيها "ربط/تشغيل" → Host.

---

## 4) الترقية التقنية على الـ Stack (generic — تخدم كل الـ packages)

### 4.1 من `Future<List>` إلى Controller تفاعلي

```dart
/// الحالة التفاعلية لأي قائمة مربوطة
class StacListState {
  final List<Map<String, dynamic>> items;
  final bool loading;      // أول تحميل
  final bool refreshing;   // pull-to-refresh
  final bool loadingMore;  // pagination
  final bool hasMore;      // فيه صفحات تانية؟
  final Object? error;
  const StacListState({
    this.items = const [], this.loading = false, this.refreshing = false,
    this.loadingMore = false, this.hasMore = false, this.error,
  });
}

/// "المخ" اللي يملكه الـ package: state + cache + realtime + pagination
abstract class StacListController {
  Stream<StacListState> get stream;
  StacListState get state;
  Future<void> load();      // كاش أولًا ثم شبكة
  Future<void> refresh();   // pull-to-refresh
  Future<void> loadMore();  // الصفحة التالية
  void dispose();
}
```

```dart
// StacDataRegistry — إضافة (مع الإبقاء على registerList القديم للتوافق)
void registerController(String key, StacListController Function() factory);
StacListController controller(String key); // ينشئ/يعيد instance حسب الشاشة
```

> الـ chat package تلفّ الـ `ChatRoomsBloc` / `MessagesBloc` الموجودين داخل `StacListController` — من غير ما نعيد كتابة منطق الحالة.

### 4.2 ترقية `utdList`: refresh + pagination + state slots

```json
{
  "type": "utdList",
  "source": "chat.conversation.messages",
  "reverse": true,
  "refresh": true,
  "paginate": true,
  "itemTemplate":    { "...": "قالب الرسالة بـ binding" },
  "loadingTemplate": { "...": "skeleton أثناء أول تحميل" },
  "emptyTemplate":   { "...": "لا توجد رسائل" },
  "errorTemplate":   { "...": "خطأ + زر إعادة (utdAction: source.refresh)" }
}
```

الـ parser الجديد يستخدم `StreamBuilder` + `RefreshIndicator` + `ScrollController` (للـ loadMore عند الوصول للنهاية) → **ده هو الـ Scroll Handling والـ Refresh اللي بتسأل عليه، وبيعيش في الـ Stack Engine (generic)، مدفوع بأوامر الـ Package**.

### 4.3 سجل الأفعال (Actions)

```dart
typedef StacAction = Future<void> Function(BuildContext ctx, Map<String, dynamic> args);
void registerAction(String key, StacAction handler); // مثال: chat.sendMessage
```

```json
{ "type": "iconButton", "icon": "send",
  "onPressed": { "type": "utdAction", "action": "chat.sendMessage",
                 "args": { "from": "composerInput" } } }
```

### 4.4 طبقة Cache للبيانات (مش بس للـ JSON)

حاليًا Hive يكاش الـ **layout** بس. نضيف cache للـ **data** داخل الـ Package (Hive موجود، أو Drift/Isar لو عايزين message history قابل للاستعلام) → فتح فوري + offline، والشبكة تحدّث في الخلفية (stale-while-revalidate).

---

## 5) مثال Chat Package — العقد الكامل

### A) ما توفّره الـ Package للعميل (عشان يستغلها في UTD Stack)

1. **Manifest (وقت التصميم):** الشاشات (`conversations`, `conversation`) + عناصر البيانات + الأفعال (موجود جزئيًا).
2. **مصادر بيانات تفاعلية (Controllers):**
   - `chat.conversations` — قائمة المحادثات (paginated + realtime + cached).
   - `chat.conversation.messages` — رسائل محادثة (reverse + pagination + realtime). **(ناقص حاليًا)**
   - `chat.conversation.header` — كائن واحد: اسم/صورة الطرف + online + typing.
3. **أفعال (Actions) قابلة للنداء من الـ JSON:**
   - `chat.sendMessage` (مع optimistic insert) · `chat.refresh` · `chat.loadMore`
   - `chat.markRead` · `chat.deleteMessage` · `chat.react` · `chat.typing` · `chat.openConversation`
4. **عناصر جاهزة (Composite widgets) اختيارية:** `chatComposer` (إدخال + إرسال + مرفقات + صوت)، `chatBubble`، `chatList` (refresh + pagination + typing + scroll-to-bottom) — تغلّف الـ scroll/state الصعب وتفضل تسيب خصائص تنسيق مكشوفة.
5. **State + Cache + Realtime** كلها جوّه الـ package (Pusher/Echo → يحدّث الـ Controller stream → الـ UI يعيد الرسم).

### B) ما يقدر العميل يغيّره في الـ Design (من الـ Studio/JSON)

- الترتيب والتخطيط (row/card، أي حقول تظهر، صف مقابل بطاقة).
- التنسيق: ألوان، خطوط، radius، spacing، حجم/شكل الأفاتار، **لون فقاعة رسالتي مقابل الطرف الآخر**، خلفية/wallpaper المحادثة.
- إظهار/إخفاء عناصر: شارة unread، نقطة online، الوقت، معاينة آخر رسالة، أيقونات الحالة.
- قوالب الحالات: empty / loading (skeleton) / error.
- تفعيل سلوكيات: pull-to-refresh، pagination، مؤشّر الكتابة.
- الـ AppBar / FAB / BottomNav + قالب العنصر (item template).

**مقفول داخل الـ Package (مايقدرش يغيّره):** منطق الإرسال/المزامنة/الكاش/الـ pagination/websocket/optimistic/dedup/الترتيب الزمني + **مفاتيح الـ schema**.

### C) الـ Data التي تُخرجها الـ Package للـ Stack (schemas + sample)

> دي بالظبط مفاتيح الـ `binding` اللي العميل بيسحبها في الـ Studio؛ لازم تطابق الـ manifest.

**عنصر محادثة — `chat.conversations`** (مُشتق من `ChatRoomModel` + حقول احترافية جديدة):
```json
{
  "chat_id": 123, "user_id": 55,
  "name": "أحمد علي", "image": "https://.../a.webp",
  "last_message": "تمام، شكرًا", "last_message_type": "text",
  "time": "2026-06-02T14:33:00Z",
  "unread_count": 3, "type": "private",
  "is_online": true, "is_typing": false, "is_muted": false, "is_pinned": false
}
```

**عنصر رسالة — `chat.conversation.messages`** (مُشتق من `ChatMessageModel`):
```json
{
  "id": 998, "message": "إزيك؟",
  "type": "text", "file": null, "duration": null,
  "time": "2026-06-02T14:30:00Z",
  "is_mine": true, "status": "read",
  "sender_name": "أنا", "sender_avatar": "https://...",
  "reply": { "message": "...", "sender_name": "...", "type": "text" },
  "reactions": [ { "emoji": "❤️", "count": 2, "mine": true } ]
}
```

> الحقول **المشتقّة** (`is_mine`, `status`, `is_online`, `is_typing`) = القيمة المضافة للـ Package؛ مش راجعة خام من الـ API، الـ Controller هو اللي يحسبها.

### D) العناصر الجاهزة مقابل الـ primitives (الـ trade-off)

| الأسلوب | حرية التصميم | الاحترافية out-of-box | متى |
|---|---|---|---|
| primitives فقط (row/text/image + utdList) | أعلى | العميل يعيد بناء scroll/refresh بنفسه | شاشات بسيطة |
| composite widgets (chatComposer/chatBubble) | أقل (خصائص محدّدة) | كاملة فورًا | شاشات معقّدة (chat) |
| **Hybrid (موصى)** | عالية | عالية | primitives للتخطيط + widgets سلوكية تغلّف الـ scroll/state |

---

## 6) خطة التنفيذ على مراحل

| Milestone | المحتوى | الأثر |
|---|---|---|
| **M1 — Core (Stack)** | Reactive registry (`StacListController`) + `utdList` بـ `StreamBuilder` + `RefreshIndicator` + infinite scroll + state slots (loading/empty/error) | يخدم **كل** الـ packages |
| **M2 — Actions** | سجل الأفعال + `utdAction` + ربط إدخال الـ composer | تفاعل (إرسال/أزرار) |
| **M3 — Chat reactive bridge** | لفّ `ChatRoomsBloc`/`MessagesBloc` في Controllers بدل الـ one-shot + إضافة `chat.conversation.messages` | استغلال المحرّك الموجود |
| **M4 — Realtime** | `pusher_channels_flutter`/`laravel_echo` → يغذّي الـ Controllers (رسالة جديدة/typing/online/read) + optimistic send | chat حيّ فعلًا |
| **M5 — Data cache** | كاش البيانات نفسها (Hive/Drift) + pagination cursors + offline | فتح فوري + أوفلاين |
| **M6 — Composite + manifest** | `chatComposer`/`chatBubble` + تسجيلها في الـ manifest + design tokens مكشوفة للـ Studio | عناصر احترافية جاهزة |

---

## 7) قرارات مفتوحة محتاجة رأيك (علّق عليها هنا)

1. **نطاق v1:** نرقّي الـ Stac engine بشكل **generic** (registry تفاعلي + state slots) لكل الـ packages — **(موصى)** — ولا نعمل widgets خاصة بالـ chat بس؟
2. **primitives مقابل composite:** نمشي **Hybrid** (موصى) ولا primitives فقط في v1؟
3. **Realtime على Flutter:** `pusher_channels_flutter` (أبسط مع Pusher) ولا `laravel_echo` + pusher driver؟
4. **مخزن الكاش:** Hive (موجود) ولا Drift/Isar (لو عايزين message history قابل للاستعلام/بحث)؟
5. **الحقول الاحترافية (`status`/`online`/`typing`):** ضمن v1 ولا v2؟
