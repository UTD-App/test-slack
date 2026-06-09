# Moment package — تثبيت يدوي (Drop-in)

باكيج مستقل (`utd/moment`, namespace `Utd\Moment`). **مش nwidart module** ومش بيتسطب أوتوماتيك — التثبيت يدوي بالخطوات دي.

## 1. انسخ الفولدر
حُط الباكيج في:
```
backend/packages/utd/moment/
```

## 2. سجّل الـ autoload (root composer.json)
ضيف الـ PSR-4 ده تحت `autoload.psr-4` في `backend/composer.json`:
```json
"Utd\\Moment\\": "packages/utd/moment/src/"
```
ولو هتشغّل اختبارات الباكيج، ضيف تحت `autoload-dev.psr-4`:
```json
"Utd\\Moment\\Tests\\": "packages/utd/moment/tests/"
```

## 3. سجّل الـ Service Provider (يدوي)
ضيف في `config/app.php` تحت `providers`:
```php
Utd\Moment\Providers\MomentServiceProvider::class,
```

## 4. سجّل شاشة الأدمن (Filament) — يدوي
في `app/Providers/Filament/AdminPanelProvider.php` ضيف للـ panel:
```php
->plugin(\Utd\Moment\Filament\MomentPlugin::make())
```

## 5. حدّث الـ autoload + شغّل الـ migrations
```bash
composer dump-autoload
php artisan migrate
```

## 6. سجّل الباكيج في النظام (مطلوب)
```bash
php artisan utd:sync-packages
```
الأمر ده بيكتب الباكيج في جدول `packages` عشان تظهر في صفحة `admin/packages` (تشغيل/إطفاء) وفي الـ API `/api/packages/installed` اللي التطبيق بيقرأ منه المزايا المُفعّلة.
> ⚠️ **مش اختيارية**: من غيرها الباكيج هتشتغل لكن **مش هتبان** في لوحة الأدمن ولا التطبيق. شغّلها بعد كل تثبيت أو تحديث.

## 7. (اختياري) seed بيانات تجريبية
```bash
php artisan db:seed --class="Utd\Moment\Database\Seeders\MomentDatabaseSeeder"
```

## التحقق
```bash
php artisan route:list --path=moment        # API + admin/moments
php artisan tinker --execute="\App\Models\Package::pluck('slug')"  # لازم يطلّع 'moment'
php artisan test packages/utd/moment/tests  # كل اختبارات الباكيج تعدّي
```

## الإلغاء (Uninstall)
اعكس خطوات 2/3/4، امسح الفولدر، `composer dump-autoload`. امسح صف الباكيج من صفحة `admin/packages` (أو من جدول `packages`). (لو عايز تشيل الجداول اعمل rollback للـ migrations الأول).

> الاعتمادات على الـ Base عبر Contracts: `MediaUploader`, `NotificationSender` (جاهزين)، و`GiftSender` (اختياري — الهدايا تتفعّل تلقائي لما باكيج Gifts يباينده). تفاصيل الفجوات في `NOTES_GAPS.md`.
