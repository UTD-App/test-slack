# Reels package — known gaps (to revisit)

نُقل من Eagle (`Modules/Reals`) كـ **package مستقل** (`Utd\Reels`) يتسطب يدوياً في base-project. كل اللي تحت اتأجّل **عن قصد** لأنه يعتمد على باكيجات/أنظمة/جداول لسه ماتبنوش في الـ Base. الباترن نفسه بتاع باكيج `utd/moment`.

| # | الفجوة | السبب | اللي اتعمل دلوقتي | يتقفل بـ |
|---|--------|-------|-------------------|----------|
| 1 | ~~**Gifting على الـ reel**~~ ✅ اتقفل | كان محتاج باكيج **Gifts** + العملات | `ReelGiftsController` محروس بـ `App\Contracts\GiftSender`. باكيج **Gifts اتسطّب** وبيبايند الـ contract → الـ endpoint `POST reals/{id}/gift` شغّال تلقائي. (الفلاتر بيبعت `contextType: 'reel'` عن طريق GiftBridge بتاع باكيج gifts.) | — (تم) |
| 2 | **فلترة الـ Feed بالمتابعة (Follow) + خلط الاهتمامات** | `App\Models\Follow` + سكوبات `isFollow/getFollowers/friendsFollowedId` + جدول/كاتالوج `interests` مش في الـ Base | الفيد اتبسّط لقايمة زمنية مرقّمة (`ReelsRepository`)؛ `getFollowedReels`/فلتر `following` يرجّعوا الفيد الكامل. خلط interest/not-interested/liked اتشال. | إضافة Follow + Interests للـ Base/Profile |
| 3 | **بيانات اليوزر الغنية** | levels/vip/frames/special-id/room/manager-type من باكيجات تانية | `UserResource` + `scopeWithUser` مبسّطين (id, uuid, name, image, gender, age). | Levels/VIP/Store/Rooms |
| 4 | **`sub_video` (GIF preview)** | كان بيتعمل بـ Python script (`script.py`) + `shell_exec` | اتشال. `sub_video = null`. الـ poster (`sub_frame`) بيتولّد من FFMpeg (frame عند ثانية 1). | لو محتاجين GIF preview تاني |
| 5 | **الـ Categories (interests)** | مفيش جدول/موديل `interests` في الـ Base | جدول `reals_categories` موجود لكن `category_id` بدون FK ومن غير كاتالوج. الـ sync بيتعمل يدوي في `RealsService::syncCategories`. `RealStore` بيتأكد إنها أرقام بس (مش `exists:interests`). | إضافة Interests للـ Base |
| 6 | **هوك ترقية الليفل عند رفع ريل** | `Modules\Public\Http\Services\UpgradeLevelServices::uploadReel()` مش في الـ Base | اتشال من `RealsController::store`. | باكيج Levels |
| 7 | **`users.real_type`** | كان عمود في جدول users (بيتدروب في migration الإعدادات) | مش بنلمس جدول `users` خالص — `real_type` فضل attribute مؤقت في الذاكرة (seed للـ random order)، والـ migration بتعمل `reels_user_settings` بس. | — (مقصود) |
| 8 | **Middleware الحماية** | مش في الـ Base | `appFeatureEnable:reel` بقت `package.enabled:reels` (تقفل الـ API لما الباكدج تتقفل من admin/packages). الباقي لسه متشال: `checkLatestToken, generalBan, userBan, ban.user.actions:reals, update.last.seen`. | باكيج Ban + feature flags |
| 9 | **FFMpeg host prereq** | الباكيج بيولّد poster frames | محتاج بايناريز `ffmpeg`/`ffprobe` على السيرفر + disk `gcs`. `FfmpegService::extract` متغلّفة بـ try/catch → غياب الـ binary مبيفشّلش إنشاء الريل (بس من غير صورة). | تثبيت ffmpeg على السيرفر |
| 10 | **شاشة الأدمن (Encore)** | Encore web controllers + blade القديمة | اتعادت Filament (`ReelsFeed` page + `ReelResource` + `ReportReelResource`). | — (تم) |
| 11 | **`RealViewsService` bug** | الكود القديم كان بيشاور على `likes()` في الـ views service (copy-paste) | اتصلّح يشاور على `views()`. | — (تم) |

## التغييرات عند نقل الباكيج لريبو مستقل (`UTD-App/reels` → برانش `test`)

نُقلت النسخة دي من base-project (`oldbranch:backend/packages/utd/reels`) لريبو الباكيج المستقل بنفس layout باكيج `utd/moment` (`backend/` في الجذر). اللي اتعمل:

- **`base-seam/`**: اتشحنت الـ Contracts/Facades/Support اللي الباكيج بيعتمد عليها من الـ Base (MediaUploader, NotificationSender, ProfileContributor + الـ facades والـ support) كـ drop-in reference — **من غير `FollowProvider`** (الريلز ماتستخدمهوش، الفيد مبسّط). تفاصيل في `base-seam/README.md`.
- **مفيش `config/utd_manifest.php`**: الريلز شاشة فيديو native (زي wallet/gifts/profile) مش SDUI — فماشحنّاش manifest ولا بلوك `UtdManifest::registerPackage` (ده خاص بباكيج `moment` اللي هو عرض الـ SDUI). الأدمن عبر Filament.
- **توسيع `reals.description`** لـ `string(500)->nullable()` في migration الإنشاء (نقل migration `2023_10_15` من Eagle بدل ما تفضل منفصلة).
- **تحقّق inline** اتضاف: `description max:500` (store/update)، `comment max:255`، و`categories` لازم تكون array أرقام (من غير `exists:interests` لحد ما الـ Interests يتبني).
- **`composer.json`**: اتضاف `autoload-dev` للـ `Utd\Reels\Tests\`.
