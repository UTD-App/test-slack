# UTD App — Base Project

> **العربية** | [English](#english)

---

## العربية

### ما هو هذا المشروع؟

UTD App هو منصة تطبيقات بث مباشر جاهزة للتشغيل، مبنية على نظام إضافات (Addon System) يتيح لك تركيب أي ميزة أو إزالتها بسطور قليلة من الكود.

هذا المشروع هو **القاعدة (Base Project)** — يشتمل على:
- **تسجيل الدخول** (إيميل + باسورد)
- **لوحة تحكم** كاملة (Filament v3) مع Roles & Permissions
- **نظام الـ Addon** الذي تُبنى عليه كل الإضافات
- **نظام ترجمة** متكامل (Admin Panel + Flutter App)
- **Stac** — تعديل UI التطبيق بدون نشر App Store update
- **Backend Laravel** جاهز للتوسع

كل ميزة إضافية (غرفة صوت، ألعاب، هدايا...) تُضاف كـ **Package** أو **Plugin** مستقل تشتريه من UTD Store وتضيفه بنفسك.

---

### المتطلبات

#### Flutter
- Flutter SDK: **3.29+** | Dart SDK: **3.9+**
- Android Studio أو VS Code

#### Backend
- PHP **8.2+** | Composer | MySQL **8.0+** | Redis | Nginx مع SSL

---

### هيكل المشروع

```
base-project/
├── flutter/
│   ├── lib/
│   │   ├── main.dart                         ← نقطة البداية — أضف packages هنا
│   │   ├── addons/                           ← نظام الـ Addon (لا تعدل هنا)
│   │   ├── config/app_config.dart            ← URL، اسم التطبيق
│   │   └── shared/
│   │       ├── media/
│   │       │   ├── media_cache_service.dart  ← cache دائم للـ SVGA/MP4/WebP
│   │       │   └── api_cache_service.dart    ← cache مؤقت للـ API data
│   │       └── services/
│   │           ├── translation_service.dart  ← ترجمة دائمة في Hive
│   │           └── stac_service.dart         ← Stac screens cache
│   └── pubspec.yaml
└── backend/
    ├── app/
    │   ├── Filament/                 ← Admin Panel
    │   └── Services/
    │       ├── TranslationLoader.php ← قراءة lang files أوتوماتيك
    │       ├── StorageConfigService.php ← Storage من DB
    │       └── FirebaseConfigService.php ← Firebase من DB
    ├── deploy.sh                     ← سكريبت النشر
    └── .env.example
```

---

### إعداد Flutter

```bash
git clone https://github.com/UTD-App/base-project.git
cd base-project/flutter
```

عدّل `flutter/lib/config/app_config.dart`:
```dart
factory AppConfig.production() {
  return AppConfig(
    appName: 'اسم تطبيقك',
    baseUrl: 'https://your-domain.com/api',
    storageBucketUrl: 'https://your-storage',
    domainUrl: 'https://your-domain.com',
    privacyPolicyUrl: 'https://your-domain.com/privacy',
    environment: Environment.production,
  );
}
```

```bash
flutter pub get
flutter run
```

---

### إعداد Backend

```bash
cd base-project/backend
composer install
cp .env.example .env
php artisan key:generate
```

عدّل `.env`:
```env
APP_NAME="اسم تطبيقك"
APP_URL=https://your-domain.com
DB_DATABASE=your_database
DB_USERNAME=your_user
DB_PASSWORD=your_password
SESSION_SECURE_COOKIE=true
ASSET_URL=https://your-domain.com
```

```bash
php artisan migrate
php artisan db:seed          # يضيف اللغتين EN + AR مع كل الترجمات
php artisan storage:link
```

أنشئ أول Admin:
```bash
php artisan tinker
>>> App\Models\AdminUser::create([
...   'name' => 'Admin',
...   'email' => 'admin@domain.com',
...   'password' => bcrypt('password'),
...   'is_active' => true,
... ]);
```

افتح لوحة التحكم: `https://your-domain.com/admin`

---

### النشر (Deployment)

```bash
# على السيرفر
bash deploy.sh          # نشر عادي
bash deploy.sh --seed   # نشر مع إعادة seed الترجمات
```

---

### لوحة التحكم

| الصفحة | الوظيفة | الصلاحيات |
|---|---|---|
| Dashboard | إحصائيات المستخدمين | الكل |
| Users | عرض، حظر، رفع حظر | user_manager |
| Admin Users | إنشاء وإدارة admins | super_admin |
| App Settings | إعدادات التطبيق، Firebase، Storage | settings_manager |
| Languages | إضافة لغات وترجمة المفاتيح | settings_manager |
| Stac Screens | شاشات UI المُنشرة من UTD Studio | settings_manager |

#### الأدوار (Roles)
| الدور | الصلاحيات |
|---|---|
| `super_admin` | كل شيء |
| `user_manager` | إدارة المستخدمين |
| `content_manager` | المحتوى |
| `settings_manager` | الإعدادات، اللغات، Stac |

---

### نظام الترجمة

**القاعدة:** كل translation تيجي من lang files، مش hardcoded.

**Admin Panel:** مفاتيح `lang/en/admin.php` و`lang/ar/admin.php` → seeder → DB.

**Flutter App:**
- التطبيق بيحمّل الترجمات مرة واحدة في Hive
- عند تغيير ترجمة → version تتغير → التطبيق يحدّث فقط ما تغيّر

**APIs:**
```
GET /api/translations/supported           ← اللغات المتاحة
GET /api/translations/{locale}/version    ← version check (صغير)
GET /api/translations/{locale}            ← كل الترجمات
```

**لإضافة مفاتيح package:**
```bash
POST /api/packages/register
{
  "package": "audio-room",
  "version": "1.0.0",
  "keys": [
    {"key": "audio_room.room_title", "group": "audio-room"}
  ]
}
```

---

### Storage — التخزين الديناميكي

من Admin Panel → إعدادات التطبيق → التخزين:

| المزوّد | Driver |
|---|---|
| نفس السيرفر | `local` |
| AWS S3 | `s3` |
| Cloudflare R2 | `s3` + custom endpoint |
| DigitalOcean Spaces | `s3` + custom endpoint |
| Google Cloud Storage | `gcs` |
| FTP | `ftp` |
| SFTP | `sftp` |

---

### Stac — تعديل UI بدون App Store

```
1. Designer يصمم الشاشة في UTD Studio
2. UTD Studio يدفع JSON: POST /api/stac/push  (X-Stac-Key)
3. التطبيق يحمّل الشاشة من سيرفره فوراً
```

الـ Stac Key تُولَّد من UTD Studio وتُحطّ في App Settings.

**APIs:**
```
GET  /api/stac                     ← كل الشاشات
GET  /api/stac/{name}/version      ← version check
GET  /api/stac/{name}              ← JSON الشاشة
POST /api/stac/push                ← نشر من UTD Studio (X-Stac-Key)
GET  /api/stac/screens             ← للـ UTD Studio (X-Stac-Key)
```

---

### كيف تضيف Package؟

```bash
# بجانب base-project/
git clone https://github.com/UTD-App/audio-room.git
```

**`pubspec.yaml`:**
```yaml
dependencies:
  audio_room:
    path: ../../audio-room/flutter
```

**`main.dart`:**
```dart
import 'package:audio_room/audio_room.dart';

List<AppFeature> buildFeatures() {
  return [
    AuthFeature(),
    AudioRoomFeature(), // ← أضف هنا
  ];
}
```

```bash
flutter pub get
# Backend:
cp -r audio-room/backend/Modules/AudioRoom base-project/backend/Modules/
php artisan migrate
```

---

### كيف تضيف Plugin؟

```bash
git clone https://github.com/UTD-App/charisma.git audio-room/plugins/charisma
```

**`pubspec.yaml`:**
```yaml
  audio_room_charisma:
    path: ../../audio-room/plugins/charisma/flutter
```

**`main.dart`:**
```dart
final audioRoom = AudioRoomFeature();
audioRoom.registerPlugin(CharismaPlugin());
```

---

### كيف تبني Package وتبيعه على UTD Store؟

```dart
class MyFeature extends AppFeature {
  @override
  String get id => 'com.company.myfeature';

  @override
  String get displayName => 'My Feature';

  @override
  bool get isCore => false; // قابل للتفعيل/التعطيل

  @override
  List<GoRoute> getRoutes() => [
    GoRoute(path: '/my-feature', builder: (ctx, _) => MyScreen()),
  ];

  @override
  List<UiContribution> getUiContributions() => [
    UiContribution(slot: UiSlot.home, builder: (ctx) => MyWidget()),
  ];

  @override
  Map<String, Map<String, String>> getTranslations() => {
    'en': {'my_feature.title': 'My Feature'},
    'ar': {'my_feature.title': 'ميزتي'},
  };
}
```

**Backend (Laravel Module):**
```
backend/Modules/MyPackage/
  ├── Http/Controllers/
  ├── Models/
  ├── database/migrations/
  └── routes/api.php
```

**سجّل مفاتيح الترجمة عند التثبيت:**
```bash
POST /api/packages/register
{ "package": "my-package", "keys": [...] }
```

**للنشر على UTD Store:**
1. ادفع الكود على GitHub (private)
2. افتح utdsoftware.com → Store
3. ارفع الـ Package وحدد السعر
4. UTD يراجع (3-15 يوم) ثم ينشر

---

### أماكن الـ UI (UiSlot)

| Slot | الموضع |
|---|---|
| `UiSlot.appBar` | شريط العنوان |
| `UiSlot.home` | الشاشة الرئيسية |
| `UiSlot.drawer` | القائمة الجانبية |
| `UiSlot.bottomNav` | شريط التنقل السفلي |
| `UiSlot.dashboard` | لوحة المعلومات |
| `UiSlot.settings` | الإعدادات |
| `UiSlot.loginMethods` | طرق تسجيل الدخول |
| `UiSlot.userProfile` | صفحة الملف الشخصي |
| `UiSlot.userProfileActions` | أزرار الملف الشخصي |

---

### Flutter Cache System

```dart
// Media (دائم — لا ينتهي)
final file = await MediaCacheService.instance.getSvga(url);
final file = await MediaCacheService.instance.getVideo(url);
final file = await MediaCacheService.instance.getImage(url);

// API data (مؤقت — TTL)
final data = await ApiCacheService.instance.get('key', ttl: Duration(minutes: 10));
await ApiCacheService.instance.set('key', data);
```

---

### قواعد المطورين (Developer Contract)

1. **لا hardcoded strings** — كل نص يستخدم `__('admin.xxx')` أو translation key
2. **الترجمات من lang files** — مش يدوي في DB
3. **كل package مستقل** — Flutter + Laravel + translations
4. **لا تعديل في base-project** — الكود يروح في الـ package
5. **الـ Stac key من UTD Studio** — مش العميل يختاره

---

---

## English

### What is this project?

UTD App is a ready-to-run live streaming app platform built on a modular Addon System.

**Base Project includes:**
- Authentication (email + password)
- Full Admin Panel (Filament v3) with Roles & Permissions
- Addon System for all features
- Complete Translation System (Admin + Flutter)
- Stac — update app UI without App Store review
- Laravel Backend ready for scaling

---

### Prerequisites

- Flutter SDK **3.29+** | PHP **8.2+** | MySQL **8.0+** | Redis | Nginx with SSL

---

### Flutter Setup

```bash
git clone https://github.com/UTD-App/base-project.git
cd base-project/flutter
# Edit lib/config/app_config.dart with your URLs
flutter pub get
flutter run
```

---

### Backend Setup

```bash
cd base-project/backend
composer install && cp .env.example .env && php artisan key:generate
# Edit .env (DB, URL, SESSION_SECURE_COOKIE=true, ASSET_URL)
php artisan migrate && php artisan db:seed && php artisan storage:link

# Create first admin
php artisan tinker
>>> App\Models\AdminUser::create(['name'=>'Admin','email'=>'admin@domain.com','password'=>bcrypt('pass'),'is_active'=>true]);
```

---

### Deployment

```bash
bash deploy.sh          # pull + migrate + optimize
bash deploy.sh --seed   # + re-seed translations
```

---

### Admin Panel Roles

| Role | Access |
|---|---|
| `super_admin` | Everything |
| `user_manager` | Manage users |
| `content_manager` | Content |
| `settings_manager` | Settings, Languages, Stac |

---

### Translation System

- **Pattern:** `lang/en/*.php` → seeder → DB → Admin can edit
- **Package keys:** via `getTranslations()` in AppFeature + `POST /api/packages/register`
- **Never hardcode strings** — always use `__('admin.xxx')`

---

### Adding a Package

```bash
git clone https://github.com/UTD-App/audio-room.git  # next to base-project/
# Add to pubspec.yaml, register in main.dart, copy backend module, migrate
```

---

### Building Your Own Package

```dart
class MyFeature extends AppFeature {
  @override String get id => 'com.company.myfeature';
  @override String get displayName => 'My Feature';
  @override List<GoRoute> getRoutes() => [...];
  @override List<UiContribution> getUiContributions() => [...];
  @override Map<String, Map<String, String>> getTranslations() => {
    'en': {'key': 'value'},
    'ar': {'key': 'قيمة'},
  };
}
```

**To publish on UTD Store:**
1. Push to GitHub (private repo)
2. Go to utdsoftware.com → Store → Upload package
3. UTD reviews (3-15 days) then publishes

---

### Flutter Cache

```dart
// Permanent (SVGA, MP4, WebP, Images)
MediaCacheService.instance.getSvga(url);
MediaCacheService.instance.getVideo(url);

// TTL-based (API responses)
ApiCacheService.instance.get('key', ttl: Duration(minutes: 10));
```

---

### Stac — Dynamic UI

UTD Studio generates a Stac Key → Client puts in App Settings → UTD Studio pushes screens → App updates instantly.

```
GET  /api/stac/{name}   ← Flutter fetches screen
POST /api/stac/push     ← UTD Studio pushes (X-Stac-Key)
```

---

### Developer Contract

1. No hardcoded strings — use `__('admin.xxx')`
2. Translations come from lang files or packages
3. Each package is independent (Flutter + Laravel)
4. Never modify base-project — put code in the package
5. Stac key is generated by UTD Studio — not chosen by client
