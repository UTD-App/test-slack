# Reels (Flutter) — known gaps

Mirrors the backend `utd/reels` package. Built on the same clean-architecture
pattern as `flutter/packages/moment`. The one UI difference: a full-screen
vertical `PageView` of video players (TikTok-style) instead of an image feed.

| # | الفجوة | اللي اتعمل دلوقتي | يتقفل بـ |
|---|--------|-------------------|----------|
| 1 | **بيانات اليوزر الغنية** (vip/levels/frames/special-id/room) | الكارت بيعرض الأساسي بس (اسم + صورة) من الـ backend المبسّط. | باكيجات Levels/VIP/Rooms |
| 2 | ~~**Gifting على الريل**~~ ✅ اتقفل | زرار هدية في الـ action rail بيظهر بس لما `GiftBridge.instance.isAvailable` (يعني باكيج gifts متسطّب). بيفتح gift picker بتاع gifts بـ `contextType: 'reel'` → `POST /reals/{id}/gift`. | — (تم) |
| 3 | **فلتر "following"** | الـ `ReelsFeedBloc` بيدعم `filter`، بس الافتراضي الفيد الكامل (الـ backend بيرجّع الكامل لحد ما Follow يتبني). الـ tabs (Following/For You) في الـ TopBar visual بس دلوقتي. | Follow graph في الـ Base |
| 4 | **Categories عند الرفع** | `ReelCreated` بياخد `categories` (List<int>) بس شاشة الرفع مش بتعرض اختيار كاتيجوري (مفيش catalog interests في الـ Base). | إضافة Interests |
| 5 | **`sub_video` (GIF preview)** | غالبًا فاضي من الـ backend. الكارت بيستخدم `sub_frame` كـ poster + الفيديو نفسه. | لو رجع الـ GIF preview |
| 6 | **التشغيل** | `video_player` بيشغّل/يوقف حسب الصفحة النشطة في الـ PageView (واحد بس بيشتغل) + `ReelPrefetch` بيسخّن الـ 3 ريلز الجايين. مفيش controller-pool disposal متقدّم (زي تطبيق Tempo الأصلي). | لو محتاجين caching/pool أقوى |

## الإضافات في برانش `test` (مراجعة مقابل تطبيق Tempo-Live الأصلي)

اتراجع الباكيج مقابل تطبيق الفلاتر الإنتاجي (Tempo-Live) واتنقلت الإضافات **غير المعتمدة على باكيجات تانية**:

- **زرار الهدية** (فوق) — متوصّل بباكيج gifts عبر `GiftBridge`.
- **شاشة "ريلز اليوزر" (My-Reels grid)**: `reels_my_reels_page.dart` — grid بوسترات (`sub_frame`) + أيقونة play؛ الضغط بيفتح pager full-screen عند نفس الفهرس. route جديد `/reels/user/:id` (`ReelsRoutes.userReels`)، و`ReelsProfileSection` بقت قابلة للضغط بتفتحه. الـ cubit: `reels_profile/reels_profile_cubit.dart` (بيستخدم endpoints موجودة: `my-reals`/`user/{id}`/delete/update/like).
- **تعديل وصف الريل (edit caption)**: `edit_caption_dialog.dart` + `updateReel` في الـ api/repository → `POST /reals-update/{id}`؛ متاح للمالك من قائمة "more" في الـ player (داخل My-Reels).

### مؤجّل من Tempo-Live (معتمد على باكيجات/أنظمة لسه ماتبنوش)
- **following feed الحقيقي + زرار follow** → Follow graph.
- **internal share-to-friends** (بحث + مشاركة لمستخدمين) → باكيجات Search/Messaging. (المتاح: مشاركة OS عبر `share_plus`.)
- **dynamic links** (مشاركة برابط Firebase) → Firebase Dynamic Links.
- **رفع بـ S3 pre-signed + قص/ضغط الفيديو** (`video_trimmer`/`video_compress`) → الحالي رفع multipart مباشر، أبسط وكافٍ.
- **اسم/غلاف الموسيقى** → مفيش field في الـ backend.
