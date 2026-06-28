# Reels package — تثبيت يدوي (Drop-in)

باكيج مستقل (`utd/reels`, namespace `Utd\Reels`). **مش nwidart module** ومش بيتسطب أوتوماتيك — التثبيت يدوي بالخطوات دي.

## 1. انسخ الفولدر
حُط الباكيج في:
```
backend/packages/utd/reels/
```

## 2. سجّل الـ autoload (root composer.json)
ضيف الـ PSR-4 ده تحت `autoload.psr-4` في `backend/composer.json`:
```json
"Utd\\Reels\\": "packages/utd/reels/src/"
```
ولو هتشغّل اختبارات الباكيج، ضيف تحت `autoload-dev.psr-4`:
```json
"Utd\\Reels\\Tests\\": "packages/utd/reels/tests/"
```

## 3. سجّل الـ Service Provider (يدوي)
ضيف في `config/app.php` تحت `providers`:
```php
Utd\Reels\Providers\ReelsServiceProvider::class,
```

## 4. سجّل شاشة الأدمن (Filament) — يدوي
في `app/Providers/Filament/AdminPanelProvider.php` ضيف للـ panel:
```php
->plugin(\Utd\Reels\Filament\ReelsPlugin::make())
```

## 5. ثبّت FFMpeg (مطلوب للـ poster frames)
الباكيج بيستخدم `pbmedia/laravel-ffmpeg` (مذكورة في `composer.json` بتاع الباكيج، بتتسحب أوتوماتيك مع `composer update`).
- **لازم** بايناريز `ffmpeg` و`ffprobe` متسطبة على السيرفر/الجهاز.
- لازم disk اسمه `gcs` متظبط في `config/filesystems.php` (الـ frames بتتكتب هناك تحت `frames/{id}.jpg`).
- لو الـ ffmpeg مش موجود، إنشاء الريل **مش هيفشل** — بس صورة الـ poster (`sub_frame`) مش هتتولّد (best-effort).

## 6. حدّث الـ autoload + شغّل الـ migrations
```bash
composer update    # يسحب pbmedia/laravel-ffmpeg
composer dump-autoload
php artisan migrate
```

## 7. سجّل الباكيج في النظام (مطلوب)
```bash
php artisan utd:sync-packages
```
الأمر ده بيكتب الباكيج في جدول `packages` عشان تظهر في صفحة `admin/packages` (تشغيل/إطفاء) وفي الـ API `/api/packages/installed` اللي التطبيق بيقرأ منه المزايا المُفعّلة.
> ⚠️ **مش اختيارية**: من غيرها الباكيج هتشتغل لكن **مش هتبان** في لوحة الأدمن ولا التطبيق. شغّلها بعد كل تثبيت أو تحديث.

## 8. (اختياري) seed بيانات تجريبية
```bash
php artisan db:seed --class="Utd\Reels\Database\Seeders\ReelsDatabaseSeeder"   # إعدادات الباكيج
php artisan db:seed --class="Utd\Reels\Database\Seeders\ReelsDemoSeeder"        # ريلز تجريبية
```

## التحقق
```bash
php artisan route:list --path=reals        # API + admin/reels
php artisan tinker --execute="\App\Models\Package::pluck('slug')"  # لازم يطلّع 'reels'
php artisan test packages/utd/reels/tests  # كل اختبارات الباكيج تعدّي
```

## الإلغاء (Uninstall)
اعكس خطوات 2/3/4، امسح الفولدر، `composer dump-autoload`. امسح صف الباكيج من صفحة `admin/packages` (أو من جدول `packages`). (لو عايز تشيل الجداول اعمل rollback للـ migrations الأول).

> الاعتمادات على الـ Base عبر Contracts: `MediaUploader`, `NotificationSender` (جاهزين)، و`GiftSender` (اختياري — الهدايا تتفعّل تلقائي لما باكيج Gifts يباينده). معالجة الفيديو (FFMpeg) **جوه الباكيج**. تفاصيل الفجوات في `NOTES_GAPS.md`.
