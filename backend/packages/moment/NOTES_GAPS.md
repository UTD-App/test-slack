# Moment package — known gaps (to revisit)

نُقل من Eagle (`Modules/Moment`) كـ **package مستقل** (`Utd\Moment`) يتسطب يدوياً في base-project. كل اللي تحت اتأجّل **عن قصد** لأنه يعتمد على باكيجات/أنظمة لسه ماتبنوش في الـ Base.

| # | الفجوة | السبب | اللي اتعمل دلوقتي | يتقفل بـ |
|---|--------|-------|-------------------|----------|
| 1 | **Gifting على الـ moment** | محتاج باكيج **Gifts** + العملات | `MomentUserGiftsController` محروس بـ `App\Contracts\GiftSender`. مش مبايند → `503`. لما Gifts يتسطب ويباينده → يشتغل تلقائي. جدول `moment_user_gifts` + علاقة `gifts()` متشالين. `gifts_count`=0 ثابت. | باكيج Gifts |
| 2 | **فلترة الـ Feed بالمتابعة (Follow)** | الـ follow graph في باكيج **social** | اتعمل seam `App\Contracts\FollowProvider`: `getFollowedMoments`/`momentUserFollow` يفلتروا بالـ following ids لو الـ provider مبايند، وإلا fallback للـ feed الكامل (زي Eagle قبل أي متابعات). **ترتيب الـ feed بقى مطابق لـ Eagle** (الـ moments اللي المستخدم ماعملهاش like بتطفو فوق ثم الأحدث — `Moment::scopeFeedOrder`). | باكيج social يباينده `FollowProvider` |
| 3 | **بيانات اليوزر الغنية** | levels/vip/frames/special-id/room/chat من باكيجات تانية | `UserResource` + `scopeWithUser` مبسّطين (id, uuid, name, avatar, gender, age). | Levels/VIP/Store/Rooms/Chat |
| 4 | **عدّاد الرسائل غير المقروءة** | `user.chatRoomsAsUser/2` من باكيج Chat | اتشال من الـ repository. | باكيج Chat |
| 5 | **Middleware الحماية** | مش في الـ Base | `appFeatureEnable`→`package.enabled:moment` و **`generalBan`** اتوصّلوا (المحظور ياخد 403 بكود `account_suspended`). الباقي لسه متشال: `checkLatestToken, ban.user.actions:moment, moment.allowed, update.last.seen`. | باكيج Ban + feature flags |
| 6 | **رفع الصور async + WebP** | كان `UploadMomentImageJob` | بقى متزامن عبر `MediaUploader`. | plugin تحسين صور |
| 7 | **`level_center/ovip_center/hasInPack`** | helpers من Levels/VIP | اتشالت. | Levels/VIP |
| 8 | **شاشة الأدمن (Encore)** | Encore web controllers | اتعادت Filament (`MomentResource` + `ReportMomentResource`). | — (تم) |
| 9 | **خطأ `Entities\Real`** + migration متسرّبة (`request_agency_manger_salarey`) | بقايا في Eagle | اتشالوا. | — (تم) |

## أُضيف بعد النقل (تم)
- **Reactions فيسبوك** على البوست والتعليقات (`reaction_type` + جدول `moment_comment_likes`)، حصري.
- **ردود التعليقات** (`parent_id`, مستوى واحد + flatten للرد-على-الرد بـ@mention).
- **حذف التعليق** متحرّس (صاحب التعليق أو صاحب البوست) + بيحذف الردود معاه.
- **التبليغ عن تعليق** (`report_moment_comments` + `ReportMomentComment`) + شاشة أدمن `ReportMomentCommentResource`.
- **مجموع كوينز الهدايا** على البوست (`gifts_coins` عبر `GiftDirectory::coinsFor`).
